// Monthly fill counter in Workers KV: key `usage:<appUserID>:<YYYY-MM>` (UTC), per docs/CONTRACTS.md §5.
// KV API: get(key) / put(key, value, {expirationTtl}) — https://developers.cloudflare.com/kv/api/write-key-value-pairs/
// Note: KV has no atomic increment, so two concurrent fills can be counted once (see README "Known limits").

export function monthKey(now: Date): string {
  const y = now.getUTCFullYear()
  const m = String(now.getUTCMonth() + 1).padStart(2, '0')
  return `${y}-${m}`
}

export function usageKey(appUserID: string, now: Date): string {
  return `usage:${appUserID}:${monthKey(now)}`
}

/** First instant of the next UTC month. */
export function resetsAt(now: Date): Date {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1))
}

/** ISO 8601 without fractional seconds, e.g. "2026-10-01T00:00:00Z". */
export function formatInstant(d: Date): string {
  return d.toISOString().replace(/\.\d{3}Z$/, 'Z')
}

export async function readUsed(kv: KVNamespace, appUserID: string, now: Date): Promise<number> {
  const raw = await kv.get(usageKey(appUserID, now))
  const n = raw === null ? 0 : Number.parseInt(raw, 10)
  return Number.isFinite(n) && n > 0 ? n : 0
}

/** Stores `used` for the current month; the key expires a week after the month ends. */
export async function writeUsed(
  kv: KVNamespace,
  appUserID: string,
  now: Date,
  used: number,
): Promise<void> {
  // Relative TTL (seconds, minimum 60): always >= 7 days here.
  const expirationTtl = Math.ceil((resetsAt(now).getTime() - now.getTime()) / 1000) + 7 * 24 * 3600
  await kv.put(usageKey(appUserID, now), String(used), { expirationTtl })
}
