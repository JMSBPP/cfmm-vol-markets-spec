# Project Research Summary

**Project:** HEVM Bit-Identical Vol-Markets Twin  
**Domain:** In-process HEVM oracles + EVM bit-identical Haskell fixed-point (Uniswap V3 TickMath / FullMath)  
**Researched:** 2026-09-08  
**Confidence:** MEDIUM–HIGH (architecture/features/pitfalls high; hevm×GHC 9.10.3 Stack resolve needs a spike)

## Executive Summary

This milestone does **not** run all of `src/` inside an EVM. Experts treat HEVM as a **test-only concrete oracle**: pin `hevm-0.58.0`, keep the public library plot- and HEVM-free, compile a tiny Solidity wrapper around Uniswap V3 `TickMath`/`FullMath` once, check in runtime bytecode, and differentially compare exact words and reverts against a rewritten Haskell `SqrtGrid`.

The wedge is clear: **port TickMath + prove `mulDiv` with HEVM**, preserve `plot/`/`app/`/`test/Spec.hs` consumers, document deferred `Double` leaks. Main risk is **GHC 9.10.3 / LTS 24.55 compatibility** with HEVM (developed on 9.6.5) plus native deps (`secp256k1`, `ff`, `gmp`) — resolve with an explicit Stack spike before making oracle tests a CI gate.

## Key Findings

### Recommended Stack

Pin **`hevm == 0.58.0`** as an **extra-dep on a dedicated test suite** (not package-level `dependencies`). Oracle = Uniswap V3 core commit `f031556…` + **solc 0.7.6**, bytecode committed (no compile-during-test). Prefer local 32-byte ABI codecs over a heavy ABI framework for three pure functions.

**Core technologies:**
- **hevm 0.58.0** — in-process concrete `EVM` / `EVM.Exec` — library oracle without JSON-RPC
- **Stack LTS 24.55 / GHC 9.10.3** — keep brownfield compiler; do not downgrade the twin for the oracle
- **Pinned TickMath/FullMath bytecode** — defines EVM truth; HEVM executes it

Details: `.planning/research/STACK.md`

### Expected Features

**Must have (table stakes):**
- Canonical `TickMath.getSqrtRatioAtTick` (and inverse) port — replace `Double`/`(**)`/`floor`
- Exact word + revert semantics at public boundaries (uint widths, zero divisor)
- `FullMath.mulDiv` HEVM coverage including overflow/denom-zero
- In-process test-only HEVM harness
- Boundary/adversarial vector suite + bit-identity scope ledger (`BITWIDTHS.md`)
- Existing plots and `stack test` stay green

**Should have (competitive):**
- Differential QuickCheck against HEVM; proof-carrying fixture corpus; intermediate-stage witnesses

**Defer (v2+):**
- Whole-`src/` on-VM execution; mass `OptionRatio`/`Double` purge; HEVM in public lib; Foundry↔HEVM relay product; tolerance-based “parity”

Details: `.planning/research/FEATURES.md`

### Architecture Approach

**Pure `src/SqrtGrid` rewrite + separate `hevm-test/` component** (fixtures, oracle adapter, pinned `.sol`/`.bin`). Fast `test/Spec.hs` stays HEVM-free; `plot/`/`app/` unchanged. Build order: harness spike → TickMath/`mulDiv` parity → consumer regressions → later ladder (`LiquidityChunk`, replica).

**Major components:**
1. `src/SqrtGrid.hs` — bit-identical numeric core  
2. `hevm-test/` — oracle, fixtures, reference bytecode  
3. `test/Spec.hs` + `plot/`/`app/` — compatibility gates  

Details: `.planning/research/ARCHITECTURE.md`

### Critical Pitfalls

1. **`Integer` ≠ `uint256`** — match success/revert, not only happy paths  
2. **Fusing staged `mulDiv` chains** — preserve floor points per `BITWIDTHS.md`  
3. **TickMath via `Double`/generic sqrt** — must use constant-multiply / round-up algorithm  
4. **Ignoring failure domains** — invalid ticks, `MAX_SQRT_RATIO`, denom zero  
5. **Putting HEVM on the public library** — breaks the lightweight consumer seam  

Details: `.planning/research/PITFALLS.md`

## Implications for Roadmap

> **Refinement (2026-09-08):** Phase 1 is **Forge `evm/` + Seaport TickMath differential + `evm-spec-bridge` submodule (`hevm.call`)**. On bridge failure: issue on submodule + notify user. In-process Haskell `hevm` library spike is deferred/optional. See `HEVM-FORGE-TICKMATH.md`.

### Phase 1: Forge `evm/` + TickMath Seaport differential
**Rationale:** TDD oracle before rewriting SqrtGrid; reuse existing TickMath.sol tests  
**Delivers:** `evm/` Foundry project, `v3-core@0.8`, `*.diff.t.sol` / `t.sol`, `evm-spec-bridge` submodule, failure→issue protocol  
**Avoids:** Silent green without HEVM; reinventing relay/cheats; absorbing bridge bugs here  

### Phase 2: Bit-identical `SqrtGrid` (TickMath + `mulDiv`)
**Rationale:** Foundation for every tick-indexed path once the Forge oracle exists  
**Delivers:** Haskell port + exact differential green; `Spec.hs`/plots green  
**Avoids:** `Double` TickMath; fused mulDiv  

### Phase 3: Scope ledger + consumer regression lock
**Rationale:** Prevent overclaiming “bit-identical” package-wide  
**Delivers:** Updated `BITWIDTHS.md`; documented deferred leaks; CI jobs (fast Spec vs forge-hevm)  

### Phase 4+: Parity ladder (optional / later)
**Rationale:** Only after SqrtGrid is trusted  
**Delivers:** `LiquidityChunk` / replica paths under same harness  

### Phase Ordering Rationale

- Forge TickMath differential before Haskell rewrite (RED first)  
- `evm-spec-bridge` as submodule; bridge defects filed upstream + user notified  
- SqrtGrid before any cross-layer attribution of mismatches  
- Anti-features keep v1 off continuum/`OptionRatio` refactors  

### Research Flags

- **Phase 1:** Exact `v3-core@0.8` forge tag/remapping; submodule pin; relay/`FOUNDRY_PROFILE=hevm` in CI  
- **Phase 2:** Standard TickMath port once oracle is RED — low research, high care on vectors  
- **Optional:** Haskell in-process `hevm-0.58.0` × GHC 9.10 resolve (see STACK.md)  

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | API clear; GHC 9.10 resolve unproven in this tree |
| Features | HIGH | Aligns with PROJECT.md hybrid goals |
| Architecture | HIGH | Matches existing plot-free library seam |
| Pitfalls | HIGH | Matches CONCERNS.md / BITWIDTHS.md |

**Overall confidence:** MEDIUM–HIGH

### Gaps to Address

- **HEVM × GHC 9.10.3:** first execution task is a resolve/build spike  
- **Exact `hevm` adapter API surface:** confirm against 0.58.0 during Phase 1  
- **CI native libs:** document `secp256k1`/`ff`/`gmp` install for GitHub Actions  

## Sources

### Primary
- Hackage / unpacked `hevm-0.58.0` (`EVM.hs`)  
- Uniswap V3 core TickMath/FullMath (commit pinned in STACK.md)  
- Local `.planning/codebase/*`, `docs/BITWIDTHS.md`, `PROJECT.md`

### Secondary
- `evm_spec_rpc` Foundry↔HEVM relay designs (out of v1 scope; integration later)

---
*Research completed: 2026-09-08*  
*Ready for roadmap: yes*
