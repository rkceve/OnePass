/** Worker bindings (wrangler.jsonc vars + KV, and secrets set with `wrangler secret put`). */
export interface Bindings {
  USAGE: KVNamespace
  /** "mock" selects the deterministic stand-in; anything else calls the real API (when a key is set). */
  JEV_MODE?: string
  REVENUECAT_MODE?: string
  JEV_API_KEY?: string
  REVENUECAT_SECRET_KEY?: string
  APP_TOKEN?: string
}

/** Injectable side effects, so tests can control the network and the clock. */
export interface Deps {
  fetch: typeof fetch
  now: () => Date
  /** Per-call timeout for upstream APIs (Jev: 2 s per docs/CONTRACTS.md §5). */
  upstreamTimeoutMs: number
}

export const defaultDeps: Deps = {
  // Wrapped so `fetch` is never invoked with a foreign `this`.
  fetch: (input, init) => fetch(input, init),
  now: () => new Date(),
  upstreamTimeoutMs: 2000,
}

export class TimeoutError extends Error {
  constructor() {
    super('upstream timeout')
  }
}

/**
 * Runs `work` (request + body parsing) under a hard deadline. Rejects with TimeoutError even if
 * the underlying fetch ignores the abort signal.
 */
export async function withTimeout<T>(
  deps: Deps,
  work: (signal: AbortSignal) => Promise<T>,
): Promise<T> {
  const controller = new AbortController()
  let timer: ReturnType<typeof setTimeout> | undefined
  const deadline = new Promise<never>((_, reject) => {
    timer = setTimeout(() => {
      controller.abort()
      reject(new TimeoutError())
    }, deps.upstreamTimeoutMs)
  })
  try {
    return await Promise.race([work(controller.signal), deadline])
  } finally {
    if (timer !== undefined) clearTimeout(timer)
  }
}
