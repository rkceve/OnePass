/** Worker bindings (wrangler.jsonc vars + KV, and secrets set with `wrangler secret put`). */
export interface Bindings {
  CODES: KVNamespace
  /** Fictional service name shown on the page and in the email (default "Acme"). */
  SERVICE_NAME?: string
  /** The one fixed recipient of every code email (the demo mailbox). */
  DEMO_TO?: string
  /** Sender address; `onboarding@resend.dev` works only when DEMO_TO is the Resend account owner. */
  MAIL_FROM?: string
  /** "log" prints the code to the console instead of sending; anything else uses Resend. */
  MAILER?: string
  RESEND_API_KEY?: string
  /** HMAC secret for the session cookie. */
  SESSION_SECRET?: string
}

/** Injectable side effects, so tests can control the network, the clock and the log. */
export interface Deps {
  fetch: typeof fetch
  now: () => Date
  log: (line: string) => void
}

export const defaultDeps: Deps = {
  // Wrapped so `fetch` is never invoked with a foreign `this`.
  fetch: (input, init) => fetch(input, init),
  now: () => new Date(),
  log: (line) => console.log(line),
}

export const DEFAULT_SERVICE_NAME = 'Acme'
export const DEFAULT_MAIL_FROM = 'onboarding@resend.dev'

/** Service name with characters that would break the From header or HTML removed. */
export function serviceName(env: Bindings): string {
  const cleaned = (env.SERVICE_NAME ?? '').replace(/[<>"\r\n]/g, '').trim()
  return cleaned.length > 0 ? cleaned : DEFAULT_SERVICE_NAME
}
