# Session Research: Forge `evm/` + TickMath Seaport Diff + `hevm.call`

**Captured:** 2026-09-08  
**Project:** HEVM Bit-Identical Vol-Markets Twin (`cfmm-vol-markets-spec` / scratchpad)  
**Kind:** integration / TDD process refinement  
**Confidence:** HIGH (paths and APIs verified on disk / GitHub)

> Loaded by GSD context getters via `.planning/research/` and `research-store` / learnings.
> Supplements STACK/FEATURES/ARCHITECTURE/PITFALLS/SUMMARY.md from the parallel research pass.

---

## Locked process (user refinement)

1. Create **`evm/`** — Foundry project in this repo.  
2. **`forge install v3-core@0.8`** — Uniswap TickMath as Solidity reference.  
3. First TDD component: **Seaport-style differential test** over **existing TickMath.sol unit tests** (`t.sol` / `*.diff.t.sol`).  
4. Drive HEVM through **`evm-spec-bridge` submodule** (`feat/2-hevm-call-stdcheats`) — do not reinvent the cheat surface. **On submodule failure → issue on bridge repo + notify user** (forwardable to bridge agent).  
5. Then rewrite Haskell **`SqrtGrid`** so plots/`stack test` stay green and bit-identical.

Done bar unchanged: same plots/tests, **exact** EVM word equality (no tolerances on gated paths). Hybrid: Forge+HEVM oracle first; optional later on-VM hot paths.

---

## Bridge: `hevm.call` (stdcheats) — **submodule**

| Item | Value |
|------|--------|
| Integration | **`evm-spec-bridge` as a git submodule** of this package |
| Repo | `https://github.com/JMSBPP/evm-spec-bridge` |
| Branch | **`feat/2-hevm-call-stdcheats`** |
| Tip (when first captured) | `aad230528f93be04a00d0209f10eaa3084d84de5` |
| Local reference worktree | `/home/jmsbpp/apps/evm_spec_rpc/.worktrees/hevm-call-stdcheats` |
| Library | `solidity/src/Hevm.sol` — `library hevm { function call(method, paramsJson) }` |
| Mechanism | StdCheats-style `vm.ffi` → `relay send` → relayd → HEVM peer |
| Related design | `apps/evm_spec_rpc/docs/superpowers/specs/2026-09-08-foundry-hevm-relay-design.md` |
| Smoke | `solidity/test/HevmCall.t.sol`; profile note `FOUNDRY_PROFILE=hevm` |

**Rules:**
- Consume the submodule; do **not** reinvent relay/cheats in this package.
- Relay product ownership stays on `evm-spec-bridge`.

### Submodule failure protocol (mandatory)

If a failure is attributable to the bridge (submodule build, `hevm.call`, ffi, relay, stdcheats surface, wrong return encoding, etc.):

1. **Open a GitHub issue on the submodule repo** (`JMSBPP/evm-spec-bridge`, or upstream if that is the tracked remote) including: repro steps, expected vs actual, this package commit SHA, submodule SHA, and any `forge`/`relay` logs.
2. **Notify the user in the chat** with the **issue URL** and a short paste-ready brief so they can **forward it to the bridge agent**.
3. Do **not** silently patch around bridge bugs inside `cfmm-vol-markets-spec` unless the user explicitly directs a temporary workaround.

---

## Seaport / vol-markets differential pattern

| Item | Path |
|------|------|
| Base | `/home/jmsbpp/apps/vol-markets/test/diff/PlankDiffTestBase.sol` |
| Import | `@seaport/utils/DifferentialTest.sol` |
| Example suite | `test/types/VegaTarget.diff.t.sol` — swap `Context.oracle`, `assertPass`, packed-word eq, `diffComparisons` non-vacuity |
| Doctrine | Skip/probe if transport down — never silent green (see `SpecHelper.sol` / VolOrder diff plans) |
| Spec write-up | `docs/superpowers/plans/2026-08-27-volorder-tokenid-differential-test.md` |

**Pattern summary:** same `exec` twice with implementation swapped in context → exact equality (tol 0) → require ≥1 comparison ran.

---

## TickMath reference

- Canonical algorithm: Uniswap V3 `TickMath` / `FullMath` (research STACK.md pins core commit `f031556…` for 0.7.6 line).  
- User pin for this wedge: **`v3-core@0.8`** via forge install (execute must record exact remapping/tag).  
- Existing unit tests to **reuse as corpus** (not invent new vectors first): v3-core / v4-core `TickMath.t.sol` / `TickMathTest.sol` trees under vol-markets `lib/` are examples; prefer the installed `v3-core@0.8` test suite once `evm/` exists.

---

## Repo layout intent (this package)

```text
cfmm-vol-markets-spec/
├── src/SqrtGrid.hs          # rewrite AFTER TickMath diff is meaningful
├── test/Spec.hs             # stays HEVM-free fast suite
├── plot/ app/               # unchanged consumers
└── evm/                     # NEW Foundry project
    ├── foundry.toml
    ├── lib/v3-core@0.8
    ├── test/…TickMath….diff.t.sol | t.sol
    └── (hevm.call via bridge stdcheats / remapped Hevm.sol)
```

Public Haskell library: **plot-free, HEVM-free**. HEVM only on Forge/oracle path.

---

## Prior research (still valid)

| Doc | Role |
|-----|------|
| `.planning/research/STACK.md` | hevm 0.58.0 / TickMath/FullMath oracle notes (Haskell-in-process path — **secondary** to Forge wedge) |
| `.planning/research/FEATURES.md` | table stakes / anti-features |
| `.planning/research/ARCHITECTURE.md` | pure src + oracle component split |
| `.planning/research/PITFALLS.md` | Integer≠uint256, fused mulDiv, Double TickMath |
| `.planning/research/SUMMARY.md` | executive synthesis (update Implications: Phase 1 = Forge TickMath diff) |

**Ordering correction vs initial SUMMARY:** Phase 1 is now **Forge `evm/` + Seaport TickMath differential + `hevm.call`**, not “Haskell hevm library spike first.” In-process Haskell `hevm` remains optional v2.

---

## Keys for `gsd-tools research-store`

| Field | Value |
|-------|--------|
| ecosystem | `foundry-hevm` |
| library | `evm-spec-bridge` |
| version | `feat/2-hevm-call-stdcheats` |
| query | `TickMath Seaport differential test via hevm.call for cfmm-vol-markets-spec` |
| kind | `integration` |

---
*Captured for GSD context getters — 2026-09-08*
