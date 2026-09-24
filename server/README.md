# OnePass server (Cloudflare Worker + Hono)

Implements `docs/CONTRACTS.md` §5: `POST /v1/judge`, `POST /v1/fills`, `GET /v1/usage`.
Scaffolded from Hono's `cloudflare-workers` template (https://github.com/honojs/starter/tree/main/templates/cloudflare-workers).

## Local

```sh
npm install
cp .dev.vars.example .dev.vars   # git-ignored; mock modes, APP_TOKEN=dev-app-token
npm run dev                      # http://localhost:8787
npm test                         # vitest + @cloudflare/vitest-plugin (workerd)
npm run typecheck
```

## Configuration

| Name | Kind | Notes |
|---|---|---|
| `USAGE` | KV binding | monthly fill counter, key `usage:<appUserID>:<YYYY-MM>` (UTC) |
| `JEV_MODE` | var | `live` (default) or `mock`; mock is also used when `JEV_API_KEY` is empty |
| `REVENUECAT_MODE` | var | `live` (default) or `mock` (always plan `free`); mock is also used when the key is empty |
| `APP_TOKEN` | secret | must equal the app's `OnePassAppToken`; unset = every request is 401 |
| `JEV_API_KEY` | secret | TypeSafe API key |
| `REVENUECAT_SECRET_KEY` | secret | RevenueCat **secret** API key (v1 REST) |

Plans, entitlement ids and limits live only in `src/plans.ts` (placeholder values, OPEN).

## Deploy

```sh
npx wrangler login
npx wrangler kv namespace create USAGE        # paste the printed id into wrangler.jsonc "kv_namespaces"[0].id
npx wrangler secret put APP_TOKEN
npx wrangler secret put JEV_API_KEY
npx wrangler secret put REVENUECAT_SECRET_KEY
npm run deploy                                # wrangler deploy --minify
```

The deployed `https://onepass-server.<subdomain>.workers.dev` URL goes into `OnePassServerURL`
(`ios/Config/Secrets.xcconfig`, CI secret `ONEPASS_SERVER_URL`); the same `APP_TOKEN` value goes into
`OnePassAppToken` / `ONEPASS_APP_TOKEN`.

## Known limits

- KV has no atomic increment: two concurrent `/v1/fills` for the same user can be counted once.
- KV is eventually consistent across locations: a count written in one location may take time to be visible in another.
- No request logging: message text and metadata are never logged or stored.
