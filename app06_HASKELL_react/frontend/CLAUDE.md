# Frontend (Vite + React 18 + TypeScript + Tailwind)

Scope and API contract: see `../CLAUDE.md` first. This file is
command/layout reference for working in `frontend/` specifically.

```
npm run dev        # Vite dev server on :5173, proxies /api/v1 -> localhost:8080
npm run build       # tsc -b && vite build
npm run test        # vitest
npm run lint        # eslint . --ext ts,tsx
```

Both `npm run build` and `npm run lint` are clean (verified). `tsc -b`
(composite build via `tsconfig.node.json`) emits `vite.config.js` /
`vite.config.d.ts` alongside `vite.config.ts` — that's expected
project-references behavior, not a bug; `eslint.config.js` ignores those two
generated files rather than linting them. `eslint.config.js` (flat config,
required by the `eslint@^9` pinned in `package.json`) also turns off the base
`no-undef` rule for `.ts`/`.tsx` files per typescript-eslint's own guidance —
`React.FormEvent`-style type references (via `@types/react`'s ambient UMD
global, no value import) otherwise read as false positives.

## Pages

- `pages/Dashboard.tsx` — home; framework tiles + a quick-search box that
  now routes to `/threats?q=...` (previously routed to `/frameworks?q=...`,
  which never read that param — dead code, fixed as part of Phase-1 parity).
- `pages/Frameworks.tsx` — framework grid, no filtering.
- `pages/FrameworkDetail.tsx` — one framework's threats, paginated (20/page).
- `pages/Threats.tsx` — cross-framework threat browser: text search,
  severity filter, pagination. This is the only page that exercises
  `api.getThreats`'s `q`/`severity` params.

`api/client.ts` and `types/index.ts` are written directly against the
backend's JSON contract (see `../CLAUDE.md`) — if you change either side,
change both.
