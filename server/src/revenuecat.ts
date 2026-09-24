// RevenueCat REST API v1 plan lookup.
//   GET https://api.revenuecat.com/v1/subscribers/{app_user_id}, `Authorization: Bearer <secret key>`
//   response {subscriber: {entitlements: {<id>: {expires_date: string | null, ...}}}}
//   ("Dictionary of the entitlements of this Customer (including any expired entitlements)")
//   Source: https://www.revenuecat.com/docs/api-v1/customers.md ("Get or Create Customer",
//   response sample) and https://www.revenuecat.com/docs/api-v1 (auth), fetched 2026-09-23.

import { type Deps, withTimeout } from './env'
import { FREE_PLAN, PAID_PLANS, type Plan } from './plans'

export const REVENUECAT_BASE = 'https://api.revenuecat.com/v1'

interface SubscriberResponse {
  subscriber?: {
    entitlements?: Record<string, { expires_date?: string | null } | undefined>
  }
}

/** Active = `expires_date` null (lifetime) or in the future. */
export function isEntitlementActive(expiresDate: string | null | undefined, now: Date): boolean {
  if (expiresDate === null) return true
  if (typeof expiresDate !== 'string') return false
  const t = Date.parse(expiresDate)
  return !Number.isNaN(t) && t > now.getTime()
}

/** First plan in PAID_PLANS order whose entitlement is active; otherwise the free plan. */
export function planFromSubscriber(body: SubscriberResponse, now: Date): Plan {
  const entitlements = body.subscriber?.entitlements ?? {}
  for (const plan of PAID_PLANS) {
    if (plan.entitlementId === null) continue
    const ent = entitlements[plan.entitlementId]
    if (ent !== undefined && isEntitlementActive(ent.expires_date, now)) return plan
  }
  return FREE_PLAN
}

export interface RevenueCatConfig {
  mode: 'live' | 'mock'
  secretKey: string
}

export async function lookupPlan(
  deps: Deps,
  rc: RevenueCatConfig,
  appUserID: string,
): Promise<Plan> {
  if (rc.mode === 'mock') return FREE_PLAN
  try {
    return await withTimeout(deps, async (signal) => {
      const res = await deps.fetch(
        `${REVENUECAT_BASE}/subscribers/${encodeURIComponent(appUserID)}`,
        {
          method: 'GET',
          headers: { Authorization: `Bearer ${rc.secretKey}`, Accept: 'application/json' },
          signal,
        },
      )
      if (!res.ok) throw new Error(`revenuecat http ${res.status}`)
      return planFromSubscriber((await res.json()) as SubscriberResponse, deps.now())
    })
  } catch {
    // OPEN(billing): behaviour when RevenueCat is unreachable is not decided; degrade to the free plan.
    return FREE_PLAN
  }
}
