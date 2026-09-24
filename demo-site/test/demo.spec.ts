import { env } from 'cloudflare:workers'
import { describe, expect, it } from 'vitest'
import { CODE_TTL_S, SEND_INTERVAL_S, SESSION_COOKIE, codeKey, createApp, generateCode } from '../src/app'
import type { Bindings, Deps } from '../src/env'
import { RESEND_URL } from '../src/mailer'

const DEMO_TO = 'onepass.demo@example.com'
const ORIGIN = 'https://onepass-demo.example.workers.dev'

/** Resend "Send Email" example response, verbatim: https://resend.com/docs/api-reference/emails/send-email */
const RESEND_OK = { id: '49a3999c-0ce1-4ea6-ab68-afcd6dc2e794' }
/** Resend 403 message for resend.dev senders, verbatim: https://resend.com/docs/api-reference/errors */
const RESEND_403 =
  'You can only send testing emails to your own email address (youremail@domain.com). To send emails to other recipients, please verify a domain at resend.com/domains, and change the `from` address to an email using this domain.'

interface Call {
  url: string
  init: RequestInit
}

function harness(opts: { bindings?: Partial<Bindings>; resend?: () => Response } = {}) {
  const calls: Call[] = []
  const logs: string[] = []
  let now = new Date('2026-09-23T12:00:00Z').getTime()
  const deps: Partial<Deps> = {
    fetch: (async (input: RequestInfo | URL, init: RequestInit = {}) => {
      const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url
      calls.push({ url, init })
      return opts.resend ? opts.resend() : Response.json(RESEND_OK)
    }) as typeof fetch,
    now: () => new Date(now),
    log: (line) => logs.push(line),
  }
  const bindings: Bindings = {
    CODES: env.CODES,
    SERVICE_NAME: 'Acme',
    DEMO_TO,
    MAIL_FROM: 'onboarding@resend.dev',
    MAILER: 'resend',
    RESEND_API_KEY: 're_test_key',
    SESSION_SECRET: 'test-session-secret',
    ...opts.bindings,
  }
  const app = createApp(deps)
  let cookie: string | null = null
  const withCookie = (h: Record<string, string> = {}) => (cookie ? { ...h, Cookie: cookie } : h)
  return {
    calls,
    logs,
    advance: (seconds: number) => {
      now += seconds * 1000
    },
    get cookie() {
      return cookie
    },
    set cookie(v: string | null) {
      cookie = v
    },
    page: () => app.request(`${ORIGIN}/`, {}, bindings),
    send: async () => {
      const res = await app.request(`${ORIGIN}/send`, { method: 'POST', headers: withCookie() }, bindings)
      const set = res.headers.get('Set-Cookie')
      if (set) cookie = set.split(';')[0]!
      return res
    },
    verify: (code: unknown) =>
      app.request(
        `${ORIGIN}/verify`,
        {
          method: 'POST',
          headers: withCookie({ 'Content-Type': 'application/json' }),
          body: JSON.stringify({ code }),
        },
        bindings,
      ),
  }
}

/** The code the last Resend call carried, read from its subject. */
function sentCode(call: Call): string {
  const body = JSON.parse(String(call.init.body)) as { subject: string }
  const m = /is (\d{6})$/.exec(body.subject)
  if (!m) throw new Error(`no code in subject: ${body.subject}`)
  return m[1]!
}

describe('GET /', () => {
  it('serves the one-time-code entry screen', async () => {
    const res = await harness().page()
    expect(res.status).toBe(200)
    expect(res.headers.get('Content-Type')).toContain('text/html')
    const html = await res.text()
    expect(html).toMatch(/<input[^>]*autocomplete="one-time-code"[^>]*>/)
    const input = /<input[^>]*>/.exec(html)![0]
    expect(input).toContain('inputmode="numeric"')
    expect(input).toContain('maxlength="6"')
    expect(html).toContain('Enter verification code')
    expect(html).toContain('>Verify<')
    expect(html).toContain('Acme')
    expect(html).toContain('name="viewport"')
  })

  it('uses SERVICE_NAME and escapes it', async () => {
    const html = await (await harness({ bindings: { SERVICE_NAME: 'Globex & Co' } }).page()).text()
    expect(html).toContain('Globex &amp; Co')
  })

  it('defaults SERVICE_NAME to Acme', async () => {
    const html = await (await harness({ bindings: { SERVICE_NAME: undefined } }).page()).text()
    expect(html).toContain('<div class="brand-name">Acme</div>')
  })
})

describe('POST /send', () => {
  it('emails a 6-digit code to DEMO_TO through Resend and stores it for the session', async () => {
    const h = harness()
    const res = await h.send()
    expect(res.status).toBe(200)
    expect(await res.json()).toEqual({ sent: true })

    expect(h.calls).toHaveLength(1)
    const call = h.calls[0]!
    expect(call.url).toBe(RESEND_URL)
    expect(call.init.method).toBe('POST')
    const headers = new Headers(call.init.headers)
    expect(headers.get('Authorization')).toBe('Bearer re_test_key')
    expect(headers.get('Content-Type')).toBe('application/json')
    const body = JSON.parse(String(call.init.body))
    const code = sentCode(call)
    expect(body.from).toBe('Acme <onboarding@resend.dev>')
    expect(body.to).toEqual([DEMO_TO])
    expect(body.subject).toBe(`Your Acme verification code is ${code}`)
    expect(body.text).toContain(code)
    expect(body.text).toContain(`${ORIGIN}/`)
    expect(body.html).toContain(code)
    expect(body.html).toContain(`href="${ORIGIN}/"`)

    // Signed, HttpOnly, short-lived session cookie.
    const setCookie = res.headers.get('Set-Cookie')!
    expect(setCookie).toContain(`${SESSION_COOKIE}=`)
    expect(setCookie).toContain('HttpOnly')
    expect(setCookie).toContain('Secure')
    expect(setCookie).toContain('Max-Age=600')
    const sessionId = decodeURIComponent(h.cookie!.split('=').slice(1).join('=')).split('.')[0]!
    const stored = JSON.parse((await env.CODES.get(codeKey(sessionId)))!)
    expect(stored.code).toBe(code)
  })

  it('does not store a code or set a session when Resend rejects the send', async () => {
    const h = harness({ resend: () => new Response(RESEND_403, { status: 403 }) })
    const res = await h.send()
    expect(res.status).toBe(502)
    expect(await res.json()).toEqual({ error: 'send_failed' })
    expect(res.headers.get('Set-Cookie')).toBeNull()
  })

  it('logs instead of sending when MAILER=log', async () => {
    const h = harness({ bindings: { MAILER: 'log', RESEND_API_KEY: undefined } })
    const res = await h.send()
    expect(res.status).toBe(200)
    expect(h.calls).toHaveLength(0)
    expect(h.logs).toHaveLength(1)
    const code = /is (\d{6})$/.exec(h.logs[0]!)![1]!
    expect((await (await h.verify(code)).json() as any).result).toBe('correct')
  })

  it('answers 500 when DEMO_TO, SESSION_SECRET or the Resend key is missing', async () => {
    for (const b of [{ DEMO_TO: '' }, { SESSION_SECRET: undefined }, { RESEND_API_KEY: undefined }]) {
      const h = harness({ bindings: b })
      const res = await h.send()
      expect(res.status).toBe(500)
      expect(h.calls).toHaveLength(0)
    }
  })

  it('allows at most one send per 30 s per session', async () => {
    const h = harness()
    expect((await h.send()).status).toBe(200)
    h.advance(SEND_INTERVAL_S - 1)
    const limited = await h.send()
    expect(limited.status).toBe(429)
    expect(await limited.json()).toEqual({ error: 'rate_limited', retryAfter: 1 })
    expect(limited.headers.get('Retry-After')).toBe('1')
    expect(h.calls).toHaveLength(1)

    h.advance(1)
    expect((await h.send()).status).toBe(200)
    expect(h.calls).toHaveLength(2)
  })

  it('rate-limits per session, not globally', async () => {
    const a = harness()
    const b = harness()
    expect((await a.send()).status).toBe(200)
    expect((await b.send()).status).toBe(200)
  })

  it('replaces the previous code on a resend', async () => {
    const h = harness()
    await h.send()
    const first = sentCode(h.calls[0]!)
    h.advance(SEND_INTERVAL_S)
    await h.send()
    const second = sentCode(h.calls[1]!)
    if (first !== second) expect((await (await h.verify(first)).json() as any).result).toBe('incorrect')
    expect((await (await h.verify(second)).json() as any).result).toBe('correct')
  })
})

describe('POST /verify', () => {
  it('accepts the emailed code', async () => {
    const h = harness()
    await h.send()
    const res = await h.verify(sentCode(h.calls[0]!))
    expect(res.status).toBe(200)
    expect(await res.json()).toEqual({ result: 'correct' })
  })

  it('rejects a wrong code', async () => {
    const h = harness()
    await h.send()
    const code = sentCode(h.calls[0]!)
    const wrong = String((Number(code) + 1) % 1_000_000).padStart(6, '0')
    expect(await (await h.verify(wrong)).json()).toEqual({ result: 'incorrect' })
  })

  it('reports an expired code after 10 minutes', async () => {
    const h = harness()
    await h.send()
    const code = sentCode(h.calls[0]!)
    h.advance(CODE_TTL_S - 1)
    expect(await (await h.verify(code)).json()).toEqual({ result: 'correct' })
    h.advance(1)
    expect(await (await h.verify(code)).json()).toEqual({ result: 'expired' })
  })

  it('reports expired without a session or with a tampered cookie', async () => {
    const h = harness()
    expect(await (await h.verify('123456')).json()).toEqual({ result: 'expired' })
    await h.send()
    const code = sentCode(h.calls[0]!)
    const [name, value] = [h.cookie!.split('=')[0], decodeURIComponent(h.cookie!.slice(h.cookie!.indexOf('=') + 1))]
    const [sid, sig] = value.split('.') as [string, string]
    h.cookie = `${name}=${encodeURIComponent(`${sid}x.${sig}`)}`
    expect(await (await h.verify(code)).json()).toEqual({ result: 'expired' })
  })

  it('rejects a malformed body with 400', async () => {
    const h = harness()
    expect((await h.verify(123456)).status).toBe(400)
  })
})

describe('generateCode', () => {
  it('always returns 6 digits', () => {
    for (let i = 0; i < 1000; i++) expect(generateCode()).toMatch(/^\d{6}$/)
  })
})
