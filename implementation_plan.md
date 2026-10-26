# implementation_plan.md — moved

This file is not the plan. It is kept only because tooling and older notes
reference the path.

The governing plan is:

- **`docs/spine/plans/2026-10-07-house-rebuild-branch-1.md`** — the current
  branch's plan, task by task.

Supporting documents:

- `docs/spine/plans/` — the earlier plans, in date order.
- `.spine/progress.md` — the build history: one line per completed task, with
  commit ranges and review outcomes.
- `docs/design/nuvetrix-app-design-system.md` — the vendored house design
  system every contract test reads its values from.

## Why this file was emptied

It previously held a PRD for a React + Vite + Capacitor app with a
`src/styles/jinatra.tokens.css` token sheet, Archivo / Inter / JetBrains Mono
type and 0px corners. None of that describes this repository: Lockout is a
Flutter Android app using Bricolage Grotesque and Figtree with an 8-36dp
corner scale. The document was last touched by the initial commit and was
never updated, so a reader pointed at it was being misled about the product,
the stack and the design language at once. It is replaced with this pointer
rather than deleted, and no plan content is restated here — the plans above
are the single source.
