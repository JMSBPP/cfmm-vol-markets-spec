# External Integrations

**Analysis Date:** 2026-09-08  
**HEAD:** `f2736e058cfde1a03708f34772bfc2bb47c55cf6`  
**Scope:** `cfmm-vol-markets-spec` repo only (parent `cfmm-theory/` and `.worktrees/` not mapped unless referenced).

This package is a **spec reference / numeric twin**, not a live service. Most “integrations” are **semantic alignment** with on-chain protocols, **downstream Haskell consumers**, and **CI/build fetches** — not runtime API calls from this codebase.

## APIs & External Services

**Downstream Haskell consumer (out of repo):**
- **`apps/evm_spec_rpc` / `cfmm-adapter`** — Depends on the **public** (plot-free) library for bit-packing, tick math, and fixed-point chains over JSON-RPC (per project context). This repo does not contain RPC client code; integration is **compile-time** via Stack/Cabal `build-depends: cfmm-vol-markets-spec`.
- **`evm-spec-bridge`** — Named in `package.yaml` as a consumer that must not pull Chart/cairo; same contract as above.

**Intended EVM runtime (not wired):**
- **hevm** — Planned dependency for symbolic EVM execution → future `EVM.hs`. **Not** in `package.yaml` / `stack.yaml` today. Haskell twin currently validates against staged integer math and Solidity references in docs, not live hevm traces.

**Theorem-proving SaaS (optional, manual):**
- **Aristotle** — External prover invoked via CLI (`aristotle submit`, `lean/README.md`).
  - Auth: `ARISTOTLE_API_KEY` in developer shell (never in repo).
  - Artifacts land in `lean/archive/` (gitignored); not part of CI.

**On-chain protocol semantics (reference twins — no live RPC in this repo):**

| Protocol / library | Role in spec | Haskell touchpoints | Solidity / doc reference |
|--------------------|--------------|---------------------|--------------------------|
| **Panoptic** | 4-leg vol replica, `TokenId` bit layout, SFPM liquidity | `src/Panoptic/` (`NId.hs`, `LegChunk.hs`, `Binning.hs`, `MintPlan.hs`) | `PanopticMath.getLiquidityChunk`, `TokenId.sol` offsets; `protocol/protocol_integrations/panoptic.md` |
| **Uniswap V3** | Tick grid λ=1.0001, sqrt price Q64.96, CLMM amounts | `src/SqrtGrid.hs`, `src/Liquidity/`, `src/Payoffs/CLMMPosition.hs` | `Math.getAmount0/1ForLiquidity`, `getLiquidityForAmount0/1`; `docs/BITWIDTHS.md` |
| **Solady** | Continuous log for T0 reference | `src/Payoffs/Log.hs` (`lnWad`, `lnQ96`) | `FixedPointMathLib.lnWad` |
| **Bunni** | Geometric LDF weights | Ladder / `ell` paths | `LibGeometricDistribution.liquidityDensityX96` (`docs/BITWIDTHS.md`) |
| **Adaptive fee algebra** | Fee structure port | `src/Pricing/FeeStructure.hs` etc. | `AdaptiveFee.sol` (TODO #9) |

No Ethereum JSON-RPC endpoints, wallet APIs, or oracle HTTP clients are implemented in this repository.

**Reactive / oracle (documented, not implemented):**
- `protocol/protocol_integrations/panoptic.md` sketches **Reactive Network** + **RealizedVolatility** oracle + **Lens.sol** state viewer — design notes only; no SDK or network calls in `src/`.

## Data Storage

**Databases:**
- **None** — Pure functional spec; no PostgreSQL, Redis, or embedded DB.

**File Storage:**
- **Local `outputs/`** — PNG charts written by exe/tests (`app/Main.hs`, `plot/`); gitignored.
- **Lean `.lake/packages/`** — Mathlib and transitive deps (~7 GB); CI deliberately **not** cached (GitHub Actions 10 GB cap; comment in `.github/workflows/ci.yml`).
- **`lean/archive/`** — Optional Aristotle tarballs; gitignored.

**Caching:**
- **GitHub Actions cache** — Stack only (`~/.stack`, `.stack-work`), keyed on `stack.yaml.lock` + `package.yaml`.
- **Mathlib oleans** — `lake exe cache get` on each CI Lean job (network fetch, no persistent CI cache).

## Authentication & Identity

**Auth Provider:**
- **None in application code** — No user sessions, JWT, or OAuth.

**Developer / CI secrets:**
- **`ARISTOTLE_API_KEY`** — Optional; local Lean workflow only (`lean/README.md`).
- **GitHub Actions** — `permissions: contents: read` only; no deploy secrets in workflow.

## Monitoring & Observability

**Error Tracking:**
- **None** — No Sentry or similar.

**Analytics:**
- **None**.

**Logs:**
- **stdout/stderr** — Stack test output, `app/Main.hs` progress, CI `lake build` capture.
- **GitHub Actions** — Workflow logs for `stack` and `lean` jobs (`.github/workflows/ci.yml`).

## CI/CD & Deployment

**Hosting:**
- **GitHub** — Canonical: `https://github.com/d2p-finance/cfmm-vol-markets-spec`. No Vercel/AWS deploy from this repo.

**CI Pipeline:**
- **GitHub Actions** — `.github/workflows/ci.yml`
  - **Job `stack`:** checkout → apt Cairo/Pango → `haskell-actions/setup@v2` → cache Stack → `stack build --pedantic` → `stack test`.
  - **Job `lean`:** checkout → elan → `lake exe cache get` → `lake build` + sorry/admit grep on compiler output.
  - **Concurrency:** `ci-${{ github.ref }}`, cancel-in-progress on force-push.
  - **Triggers:** `push` / `pull_request` to `main`.

**Package registries (build-time fetches):**
- **Stackage** — `https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/lts/24/55.yaml`
- **Git: Mathlib4** — `https://github.com/leanprover-community/mathlib4.git` @ `v4.28.0`
- **Git: elan installer** — `https://elan.lean-lang.org/elan-init.sh` (CI)

## Cross-repo & documentation links

**Notation / traceability (in-repo, not runtime):**
- `notes/VOLATILITY_INSTRUMENTS.md` — Math anchor.
- `notes/agents/vol_markets/LEAN_TRACEABILITY.md` — Lean theorem ↔ README mapping.
- `docs/BITWIDTHS.md` — EVM bit-width contract for `mulDiv` chains.
- `docs/protocol-import-commit-map.txt`, `docs/lean-import-commit-map.txt` — Provenance from prior repos (`cfmm-replicationPlank`, protocol import).

**Solidity implementation target (external monorepo, not mapped deeply):**
- Project rules point on-chain twins at **`clamm-automaton/src/`** (Foundry, vendored Panoptic/Bunni/etc.) — consumer of this spec, not a dependency of the Haskell package.

**Removed integration:**
- **LeanEVM** (`Philogy/LeanEVM`) — Was a Lake `require`; removed 2026-07-16 (`lakefile.toml`, `lean/README.md`). Restore together with toolchain bump when on-chain Lean proofs resume.

## Environment Configuration

**Development:**
- Required env vars: **none** for Stack build/test or Lake build.
- Optional: `ARISTOTLE_API_KEY` for Aristotle CLI.
- System packages: Cairo/Pango dev libs for Chart-cairo (see CI apt lines).
- Mock/stub services: **N/A** — tests use synthetic ticks/paths in `test/Spec.hs`.

**Staging / Production:**
- **N/A** — Library/spec artifact; downstream `cfmm-adapter` / RPC apps own their env (chain URLs, API keys) outside this repo.

## Webhooks & Callbacks

**Incoming:**
- **None**

**Outgoing:**
- **None** — No callbacks to Stripe, webhooks, or external CRM. CI only clones/fetches build inputs.

## Integration summary diagram

```
┌─────────────────────────────────────────────────────────────┐
│  cfmm-vol-markets-spec (this repo)                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ Haskell src │  │ Lean lean/   │  │ plot/ (internal)    │ │
│  │ Q96 twin    │  │ mathlib4     │  │ Chart-cairo → PNG   │ │
│  └──────┬──────┘  └──────┬───────┘  └─────────────────────┘ │
└─────────┼─────────────────┼─────────────────────────────────┘
          │ compile-time    │ semantic refs
          ▼                 ▼
   cfmm-adapter /      Panoptic · Uniswap V3 · Solady · Bunni
   evm_spec_rpc         (Solidity twins in clamm-automaton / docs)
   (JSON-RPC — ext)     hevm → EVM.hs (planned, not linked)
          │
          ▼
   GitHub Actions (stack test + lake build)
   Stackage LTS · Mathlib cache · elan
```

---

*Integration audit: 2026-09-08*  
*Update when adding hevm, LeanEVM, RPC client code, or live oracle integrations*
