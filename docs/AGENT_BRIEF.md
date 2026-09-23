# Brief for every implementation agent

1. Read, in order: `docs/CONTRACTS.md` (binding), the fact sheets in `docs/facts/` relevant to you, and the existing code you depend on. Spec: `C:\Users\Ryosuke Kawai\Downloads\SPEC_v2.md` (outside the repo; read-only).
2. Work in your git worktree on branch `wip/<your id>` created from `origin/main`. Touch only the paths you own (CONTRACTS §1). `ios/OnePassCore/Package.swift` and `OnePassModels` are fixed; if you need a change, stop and report it.
3. No imagined APIs (CONTRACTS §0). When a fact sheet does not cover an API you need, read the real source/doc (clone into your temp dir, or WebFetch) and cite file:line or URL in your report.
4. Tests: write them first where feasible. Swift code can only be compiled on macOS CI: once `.github/workflows/ci.yml` exists on `origin/main`, rebase onto `origin/main`, push `wip/<your id>`, and read the run through the GitHub REST API (token: `printf "protocol=https\nhost=github.com\n\n" | git credential fill`, field `password`; never print it). Iterate until green. Node/Python code runs locally.
5. Never push to `main`, never force-push others' branches, never commit secrets, never add features or copy not in the spec. [Open] items → `// OPEN(<area>): ...` and report.
6. Final report (concise, in English): files changed; tests and CI run URL + result; API evidence table (API → source → verified/UNVERIFIED); OPEN markers; known risks.
