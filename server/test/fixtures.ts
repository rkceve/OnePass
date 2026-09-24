// Upstream payloads copied from the official docs' example payloads (fetched 2026-09-23).
// Only the question id key and the noul value are substituted where noted.

/**
 * Jev response. Source: https://docs.typesafe.ai/api.md, "Noul answer" example response:
 * {"model":"jev-1.13.0","answers":{"is_urgent":{"type":"noul","noul":0.95}},
 *  "usage":{"input_tokens":307,"output_tokens":20}}
 * Substituted: question id `is_urgent` -> `is_code_for_service`, and `noul`.
 */
export function jevResponse(noul: number) {
  return {
    model: 'jev-1.13.0',
    answers: {
      is_code_for_service: {
        type: 'noul',
        noul,
      },
    },
    usage: { input_tokens: 307, output_tokens: 20 },
  }
}

/**
 * RevenueCat v1 "Get or Create Customer" 200 response sample, verbatim.
 * Source: https://www.revenuecat.com/docs/api-v1/customers.md ("Response samples").
 */
export const revenueCatSubscriberSample = {
  request_date: '2019-07-26T17:40:10Z',
  request_date_ms: 1564162810884,
  subscriber: {
    entitlements: {
      pro_cat: {
        expires_date: null,
        grace_period_expires_date: null,
        product_identifier: 'onetime',
        purchase_date: '2019-04-05T21:52:45Z',
      },
    },
    first_seen: '2019-02-21T00:08:41Z',
    management_url: 'https://apps.apple.com/account/subscriptions',
    non_subscriptions: {
      onetime: [
        {
          id: 'cadba0c81b',
          is_sandbox: true,
          purchase_date: '2019-04-05T21:52:45Z',
          store: 'app_store',
        },
      ],
    },
    original_app_user_id: 'XXX-XXXXX-XXXXX-XX',
    original_application_version: '1.0',
    original_purchase_date: '2019-01-30T23:54:10Z',
    other_purchases: {},
    subscriptions: {
      annual: {
        auto_resume_date: null,
        billing_issues_detected_at: null,
        expires_date: '2019-08-14T21:07:40Z',
        grace_period_expires_date: null,
        is_sandbox: true,
        original_purchase_date: '2019-02-21T00:42:05Z',
        ownership_type: 'PURCHASED',
        period_type: 'normal',
        purchase_date: '2019-07-14T20:07:40Z',
        refunded_at: null,
        store: 'play_store',
        store_transaction_id: 'GPA.6801-7988-0152-76034..5',
        unsubscribe_detected_at: '2019-07-17T22:48:38Z',
      },
      onemonth: {
        auto_resume_date: null,
        billing_issues_detected_at: null,
        expires_date: '2019-06-17T22:47:55Z',
        grace_period_expires_date: null,
        is_sandbox: true,
        original_purchase_date: '2019-02-21T00:42:05Z',
        ownership_type: 'PURCHASED',
        period_type: 'normal',
        purchase_date: '2019-06-17T22:42:55Z',
        refunded_at: null,
        store: 'app_store',
        store_transaction_id: 1000000652379790,
        unsubscribe_detected_at: '2019-06-17T22:48:38Z',
      },
      rc_promo_pro_cat_monthly: {
        auto_resume_date: null,
        billing_issues_detected_at: null,
        expires_date: '2019-08-26T01:02:16Z',
        grace_period_expires_date: null,
        is_sandbox: false,
        original_purchase_date: '2019-07-26T01:02:16Z',
        ownership_type: 'FAMILY_SHARED',
        period_type: 'normal',
        purchase_date: '2019-07-26T01:02:16Z',
        refunded_at: null,
        store: 'promotional',
        store_transaction_id: 'a42db3af39530cb82b17eaf9c6576393',
        unsubscribe_detected_at: null,
      },
    },
  },
}

/**
 * The same sample with its single entitlement renamed from `pro_cat` to `entitlementId` and,
 * optionally, `expires_date` replaced (the sample's subscription expiry `2019-08-14T21:07:40Z`
 * is used by the tests as a realistic non-null value).
 */
export function revenueCatWithEntitlement(entitlementId: string, expiresDate: string | null) {
  const { pro_cat } = revenueCatSubscriberSample.subscriber.entitlements
  return {
    ...revenueCatSubscriberSample,
    subscriber: {
      ...revenueCatSubscriberSample.subscriber,
      entitlements: { [entitlementId]: { ...pro_cat, expires_date: expiresDate } },
    },
  }
}

/** Message text in the exact layout of `FetchedMessage.judgeText` (OnePassModels). */
export function judgeText(p: { from: string; to: string; subject: string; date: string; body: string }) {
  return `From: ${p.from}\nTo: ${p.to}\nSubject: ${p.subject}\nDate: ${p.date}\n\n${p.body}`
}
