// The only screen of the demo site: a one-time-code entry form for a fictional service.
// `autocomplete="one-time-code"` is the field shape the CI probe (probe-site/index.html,
// ios/UITests/ProbeAutoFillTests.swift) showed iOS offers our credential provider's code for.

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

export function renderPage(serviceName: string): string {
  const name = escapeHtml(serviceName)
  const initial = escapeHtml(serviceName.charAt(0).toUpperCase())
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${name} – Verification</title>
<style>
  :root { color-scheme: light; --fg: #16181d; --muted: #5f6673; --line: #d4d8df; --accent: #2f5bea; --ok: #1b7f3b; --ng: #c0322b; }
  * { box-sizing: border-box; }
  body { margin: 0; min-height: 100vh; background: #f5f6f8; color: var(--fg);
         font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
         padding: max(48px, env(safe-area-inset-top)) 20px 32px; }
  main { max-width: 400px; margin: 0 auto; }
  .brand { display: flex; align-items: center; gap: 10px; margin-bottom: 40px; }
  .logo { width: 36px; height: 36px; border-radius: 9px; background: var(--accent); color: #fff;
          display: grid; place-items: center; font-weight: 700; font-size: 19px; }
  .brand-name { font-weight: 650; font-size: 20px; letter-spacing: -0.01em; }
  h1 { font-size: 26px; line-height: 1.2; margin: 0 0 8px; letter-spacing: -0.01em; }
  .hint { color: var(--muted); font-size: 16px; line-height: 1.4; margin: 0 0 28px; }
  label { display: block; font-size: 14px; color: var(--muted); margin-bottom: 8px; }
  input { width: 100%; font-size: 28px; letter-spacing: 0.35em; padding: 14px 16px; border: 1px solid var(--line);
          border-radius: 12px; background: #fff; color: var(--fg); font-variant-numeric: tabular-nums; }
  input:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px rgba(47, 91, 234, 0.18); }
  button { width: 100%; margin-top: 16px; padding: 15px; font-size: 17px; font-weight: 600; border: 0;
           border-radius: 12px; background: var(--accent); color: #fff; }
  button:active { opacity: 0.85; }
  #result { min-height: 24px; margin: 20px 0 0; font-size: 17px; font-weight: 600; text-align: center; }
  #result.ok { color: var(--ok); }
  #result.ng { color: var(--ng); }
</style>
</head>
<body>
<main>
  <div class="brand"><div class="logo" aria-hidden="true">${initial}</div><div class="brand-name">${name}</div></div>
  <h1>Enter verification code</h1>
  <p class="hint">We sent a 6-digit code to your email.</p>
  <form id="form" novalidate>
    <label for="code">Verification code</label>
    <input id="code" name="code" type="text" autocomplete="one-time-code" inputmode="numeric" maxlength="6" aria-label="Verification code">
    <button id="verify" type="submit">Verify</button>
  </form>
  <p id="result" role="status" aria-live="polite"></p>
</main>
<script>
  (function () {
    var result = document.getElementById('result');
    var input = document.getElementById('code');
    function show(text, cls) { result.textContent = text; result.className = cls; }

    // Send the code email once per browser session (the server also rate-limits per cookie session).
    var sent = false;
    try { sent = sessionStorage.getItem('codeSent') === '1'; } catch (e) {}
    if (!sent) {
      fetch('/send', { method: 'POST', credentials: 'same-origin' }).then(function (r) {
        if (r.ok) { try { sessionStorage.setItem('codeSent', '1'); } catch (e) {} }
      }).catch(function () {});
    }

    document.getElementById('form').addEventListener('submit', function (ev) {
      ev.preventDefault();
      fetch('/verify', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ code: input.value.trim() })
      }).then(function (r) { return r.json(); }).then(function (b) {
        if (b.result === 'correct') show('Correct', 'ok');
        else if (b.result === 'expired') show('Code expired', 'ng');
        else show('Incorrect', 'ng');
      }).catch(function () { show('Incorrect', 'ng'); });
    });
  })();
</script>
</body>
</html>
`
}

export interface CodeEmail {
  subject: string
  text: string
  html: string
}

/** Subject fixed by the task: "Your <SERVICE_NAME> verification code is <code>". */
export function renderEmail(serviceName: string, code: string, pageUrl: string): CodeEmail {
  const subject = `Your ${serviceName} verification code is ${code}`
  const text = [
    `Your ${serviceName} verification code is ${code}.`,
    '',
    'It expires in 10 minutes.',
    '',
    `Enter it at ${pageUrl}`,
  ].join('\n')
  const name = escapeHtml(serviceName)
  const url = escapeHtml(pageUrl)
  const html = `<!doctype html>
<html><body style="margin:0;padding:24px;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#16181d;">
<p style="font-size:16px;margin:0 0 16px;">Your ${name} verification code is:</p>
<p style="font-size:32px;font-weight:700;letter-spacing:6px;margin:0 0 16px;">${code}</p>
<p style="font-size:14px;color:#5f6673;margin:0 0 16px;">It expires in 10 minutes.</p>
<p style="font-size:14px;margin:0;">Enter it at <a href="${url}">${url}</a></p>
</body></html>`
  return { subject, text, html }
}
