// Workers Vitest integration. The package is `@cloudflare/vitest-plugin` (formerly
// `@cloudflare/vitest-pool-workers`; renamed per
// https://developers.cloudflare.com/changelog/post/2026-08-19-vitest-plugin/). Config shape from
// https://developers.cloudflare.com/workers/testing/vitest-integration/get-started/write-your-first-test/
import { cloudflareTest } from '@cloudflare/vitest-plugin'
import { defineConfig } from 'vitest/config'

export default defineConfig({
  plugins: [
    cloudflareTest({
      wrangler: { configPath: './wrangler.jsonc' },
    }),
  ],
})
