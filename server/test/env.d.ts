// Typing for `env` from `cloudflare:workers` in tests, per
// https://developers.cloudflare.com/workers/testing/vitest-integration/test-apis/ ("cloudflare:workers exports").
declare module 'cloudflare:workers' {
  interface ProvidedEnv {
    USAGE: KVNamespace
  }
}
export {}
