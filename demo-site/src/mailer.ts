// Email sending for the demo. One real implementation (Resend HTTP API) plus a console logger.
//
// Resend "Send Email" (https://resend.com/docs/api-reference/emails/send-email, read 2026-09-23):
//   POST https://api.resend.com/emails, header `Authorization: Bearer re_xxxxxxxxx`,
//   JSON body { from, to, subject, html, text }; `from` accepts `Name <email@example.com>`.
//   Example response: {"id": "49a3999c-0ce1-4ea6-ab68-afcd6dc2e794"}
// Sender restriction (https://resend.com/docs/knowledge-base/403-error-resend-dev-domain):
//   "The resend.dev domain is only available for testing purposes and can only send emails to the
//   email address associated with your Resend account." Otherwise Resend answers 403.

import type { Deps } from './env'

export interface OutgoingEmail {
  /** Display name + address, e.g. `Acme <onboarding@resend.dev>`. */
  from: string
  to: string
  subject: string
  text: string
  html: string
}

export interface Mailer {
  send(email: OutgoingEmail): Promise<void>
}

export const RESEND_URL = 'https://api.resend.com/emails'

export class MailerError extends Error {
  constructor(
    message: string,
    readonly status?: number,
  ) {
    super(message)
  }
}

export class ResendMailer implements Mailer {
  constructor(
    private readonly apiKey: string,
    private readonly deps: Pick<Deps, 'fetch'>,
  ) {}

  async send(email: OutgoingEmail): Promise<void> {
    const res = await this.deps.fetch(RESEND_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: email.from,
        to: [email.to],
        subject: email.subject,
        html: email.html,
        text: email.text,
      }),
    })
    if (!res.ok) {
      // The error body is not logged: it can echo the recipient address.
      throw new MailerError(`resend responded ${res.status}`, res.status)
    }
    const body = (await res.json().catch(() => null)) as { id?: unknown } | null
    if (!body || typeof body.id !== 'string') throw new MailerError('resend response without id')
  }
}

/** Local dev / tests: prints the code email instead of sending it. */
export class LogMailer implements Mailer {
  constructor(private readonly deps: Pick<Deps, 'log'>) {}

  async send(email: OutgoingEmail): Promise<void> {
    this.deps.log(`[MAILER=log] to=${email.to} subject=${email.subject}`)
  }
}
