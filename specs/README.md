# Specs

Living spec set for the **Criarte / Filhos** mobile app. Each file pairs a specification with an actionable task checklist so work can be picked up without re-discovering context.

| File | What it covers |
|------|----------------|
| [business.md](business.md) | Product vision, audience, the parents/teachers split, monetization, compliance, success metrics |
| [system.md](system.md) | Architecture, stack, data flow, networking, persistence, build/release, observability |
| [design.md](design.md) | Design tokens (colors, type, spacing), component conventions, navigation patterns, accessibility |
| [features.md](features.md) | Feature inventory — what each of the 28 features does and its open work |
| [review.md](review.md) | Multi-expert review (Flutter / mobile / backend / DevOps) with P0–P2 findings and tasks |

**Conventions for these specs**
- Lead with current state, end with a `## Tasks` checklist using GitHub-flavored task syntax (`- [ ] …`).
- Tasks are explicit: include feature area, acceptance criteria, and which flavor(s) they apply to (`[parents]`, `[professores]`, `[both]`).
- When a task ships, tick it and add a one-liner referencing the commit/PR — don't delete it (history matters).
- Keep specs source-of-truth-aligned with code. If code drifts, update the spec or open a task to reconcile.

Higher-level project guidance for Claude lives in [`../CLAUDE.md`](../CLAUDE.md).
