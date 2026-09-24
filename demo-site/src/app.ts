// OnePass demo site: one one-time-code entry screen whose code is emailed to a fixed mailbox.
//   GET  /        the page
//   POST /send    new 6-digit code for this cookie session, emailed to DEMO_TO (max 1 per 30 s)
//   POST /verify  {"code": "123456"} -> {"result": "correct" | "incorrect" | "expired"}
// Bindings come from `c.env` (https://hono.dev/docs/getting-started/cloudflare-workers, "Bindings").
// Signed cookies: hono/cookie `setSignedCookie` / `getSignedCookie`
// (node_modules/hono/dist/types/helper/cookie/index.d.ts, hono 4.13.9).

import { Hono, type Context } from 'hono'
import { getSignedCookie, setSignedCookie } from 'hono/cookie'
import { type Bindings, type Deps, DEFAULT_MAIL_FROM, defaultDeps, serviceName } from './env'
import { LogMailer, type Mailer, ResendMailer } from './mailer'
import { renderEmail, renderPage } from './page'

export const SESSION_COOKIE = 'demo_sid'
/** Session cookie lifetime; equal to the code lifetime. */
export const SESSION_MAX_AGE_S = 600
/** Code lifetime (task: KV TTL 10 min). KV `expirationTtl` minimum is 60 s. */
export const CODE_TTL_S = 600
/** Task: at most one send per 30 s per session. */
export const SEND_INTERVAL_S = 30

type Env = { Bindings: Bindings }
type Ctx = Context<Env>

interface StoredCode {
  code: string
  /** Epoch ms of the send. */
  sentAt: number
}

export const codeKey = (sessionId: string) => `code:${sessionId}`

/** Uniform 6-digit code from the Web Crypto CSPRNG (rejection sampling avoids modulo bias). */
export function generateCode(): string {
  const buf = new Uint32Array(1)
  const limit = Math.floor(0x1_0000_0000 / 1_000_000) * 1_000_000
  for (;;) {
    crypto.getRandomValues(buf)
    const v = buf[0]!
    if (v < limit) return String(v % 1_000_000).padStart(6, '0')
  }
}

function makeMailer(env: Bindings, deps: Deps): Mailer | null {
  if (env.MAILER === 'log') return new LogMailer(deps)
  if (!env.RESEND_API_KEY) return null
  return new ResendMailer(env.RESEND_API_KEY, deps)
}

async function readSession(c: Ctx, secret: string): Promise<string | null> {
  const v = await getSignedCookie(c, secret, SESSION_COOKIE)
  return typeof v === 'string' && v.length > 0 ? v : null
}

async function readStored(env: Bindings, sessionId: string): Promise<StoredCode | null> {
  const raw = await env.CODES.get(codeKey(sessionId))
  if (raw === null) return null
  try {
    const v = JSON.parse(raw) as Partial<StoredCode>
    return typeof v.code === 'string' && typeof v.sentAt === 'number' ? { code: v.code, sentAt: v.sentAt } : null
  } catch {
    return null
  }
}

export function createApp(overrides: Partial<Deps> = {}) {
  const deps: Deps = { ...defaultDeps, ...overrides }
  const app = new Hono<Env>()

  app.get('/', (c) => {
    c.header('Cache-Control', 'no-store')
    return c.html(renderPage(serviceName(c.env)))
  })

  app.post('/send', async (c) => {
    const secret = c.env.SESSION_SECRET
    const to = c.env.DEMO_TO
    const mailer = makeMailer(c.env, deps)
    if (!secret || !to || !mailer) return c.json({ error: 'not_configured' }, 500)

    const now = deps.now().getTime()
    let sessionId = await readSession(c, secret)
    if (sessionId) {
      const prev = await readStored(c.env, sessionId)
      if (prev && now - prev.sentAt < SEND_INTERVAL_S * 1000) {
        const retryAfter = Math.ceil((prev.sentAt + SEND_INTERVAL_S * 1000 - now) / 1000)
        c.header('Retry-After', String(retryAfter))
        return c.json({ error: 'rate_limited', retryAfter }, 429)
      }
    } else {
      sessionId = crypto.randomUUID()
    }

    const url = new URL(c.req.url)
    const name = serviceName(c.env)
    const code = generateCode()
    const email = renderEmail(name, code, `${url.origin}/`)
    try {
      await mailer.send({ from: `${name} <${c.env.MAIL_FROM || DEFAULT_MAIL_FROM}>`, to, ...email })
    } catch {
      return c.json({ error: 'send_failed' }, 502)
    }

    const stored: StoredCode = { code, sentAt: now }
    await c.env.CODES.put(codeKey(sessionId), JSON.stringify(stored), { expirationTtl: CODE_TTL_S })
    await setSignedCookie(c, SESSION_COOKIE, sessionId, secret, {
      path: '/',
      httpOnly: true,
      secure: url.protocol === 'https:',
      sameSite: 'Lax',
      maxAge: SESSION_MAX_AGE_S,
    })
    return c.json({ sent: true })
  })

  app.post('/verify', async (c) => {
    const secret = c.env.SESSION_SECRET
    if (!secret) return c.json({ error: 'not_configured' }, 500)
    let body: unknown
    try {
      body = await c.req.json()
    } catch {
      body = undefined
    }
    const code =
      typeof body === 'object' && body !== null && typeof (body as { code?: unknown }).code === 'string'
        ? (body as { code: string }).code.trim()
        : null
    if (code === null) return c.json({ error: 'invalid_request' }, 400)

    const sessionId = await readSession(c, secret)
    const stored = sessionId ? await readStored(c.env, sessionId) : null
    // KV expiry is not exact, so the lifetime is also checked against the stored send time.
    if (!sessionId || !stored || deps.now().getTime() - stored.sentAt >= CODE_TTL_S * 1000) {
      return c.json({ result: 'expired' })
    }
    return c.json({ result: code === stored.code ? 'correct' : 'incorrect' })
  })

  return app
}
