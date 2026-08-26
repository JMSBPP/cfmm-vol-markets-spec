# Scratchpad — bring the Lean4 spec home; repo becomes `cfmm-vol-markets-spec`

**Date:** 2026-08-26  
**Status:** design; TODO #37. Two-reviewer pass done (Reality Checker, Git Workflow Master); all BLOCKER/MAJOR findings folded in.  
**Notation anchor:** `notes/VOLATILITY_INSTRUMENTS.md` (this repo, after migration)

## 1. Role (taxonomy)

This repository is the **spec reference for protocols building volatility instruments on top of CFMMs**. It has three layers that share one notation contract:

| layer | artifact | what it does |
|---|---|---|
| anchor | `notes/VOLATILITY_INSTRUMENTS.md` + `model/vol_markets/*_ADDENDUM.md` | fixes every glyph (Definitions / Theorems / Rules); `LEAN_TRACEABILITY.md` maps statements to proofs |
| proofs | `lean/{vol_markets,exp,tao}/` (Lean 4 + Mathlib, Aristotle-proved) | machine-checks the statements; no `sorry`, no `axiom` |
| twin | `src/`, `test/` (Haskell) | computes, plots, and regression-tests the proved statements numerically |

Rule: the twin **cites theorem names** (`LadderPrincipal.principal_inRange`, `GeomMixture.xiStar_argmin`, …) and never re-proves.

## 2. Problem

Until now the anchor and the proofs lived in a git worktree of `JMSBPP/cfmm-replicationPlank` (branch `feat/lean4-spec`, tip `fdc714e`) — a Plank/GAMS/Foundry repo. This repo cited them by `~`-relative path, so a fresh clone could not resolve its own notation. A stale mirror (`JMSBPP/cfmm-lean4-spec`) and a stale split branch existed; neither is used.

## 3. Decisions

- All three Lean families move (`vol_markets` 42 modules, `exp` 14, `tao` 8) — zero refactor.
- Anchor + `model/{exp,vol_markets,tao}` move; `model/mev_tax_model_one` and `model/BUILD.md` stay in Plank (they are its GAMS prover).
- History preserved: `git filter-repo` (paths above; `*.tar.gz`/`*.pdf` stripped) then `git merge --allow-unrelated-histories --no-ff`. Result: 113 commits, 109 files, ~640 KB pack. SHAs are rewritten; the old→new commit map is attached to the PR so "integrated 36a560b"-style citations in the imported docs stay traceable.
- **The migration PR is merged with a merge commit** (`gh pr merge --merge`), never squash/rebase.
- Lake files live at the repo root (`lakefile.toml`, `lake-manifest.json`, `lean-toolchain`) beside `package.yaml`; sources stay under `lean/` via `srcDir = "lean"`; package name `cfmmVolMarketsSpec`; module names unchanged.
- CI gains a job named `lake build` (elan + `lake exe cache get` + `lake build`, sorry/admit guard on the compiler warning; no `actions/cache` of `.lake/packages` — 6.9 GB, over the runner budget). After the migration PR merges, ruleset 21150596 requires both `stack build && stack test` and `lake build`.
- Repo renamed to `cfmm-vol-markets-spec` in a follow-up `chore/` PR (`gh repo rename`; GitHub redirects the old URL; Haskell package name unchanged).

## 4. Layout after

```
lakefile.toml  lake-manifest.json  lean-toolchain
lean/{exp,vol_markets,tao}/  lean/README.md
notes/VOLATILITY_INSTRUMENTS.md
model/{exp,vol_markets,tao}/
package.yaml stack.yaml src/ test/ app/        (untouched)
.github/workflows/ci.yml                        (+ lake build)
```

## 5. Known dangling links (left as-is, tracked in TODO #37)

`../refs/DemeterfietalVarianceSwaps.pdf` (anchor, 4 hits), `./tbd.md`, `./pos_spec.md` (addenda).

## 6. Follow-up outside this repo

In `cfmm-replicationPlank`: delete the moved paths, drop its `lean` CI job, point README here, remove the `lean4-spec` remote and the `lean4-spec-split` branch; archive `JMSBPP/cfmm-lean4-spec`. Peer session owning the Lean side is told first.
