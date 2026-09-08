# Walking Skeleton — HEVM Bit-Identical Vol-Markets Twin

**Phase:** 1
**Generated:** 2026-09-08

## Capability Proven End-to-End

A package maintainer can run `forge build --root evm` and compile a local harness that delegates to TickMath from the exact `Uniswap/v4-core@v4.0.0` release.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| EVM framework | Nested Foundry project rooted at `evm/` | Keeps Solidity oracle tooling isolated from the existing Haskell and Lean builds while remaining in the parent Git repository. |
| Canonical oracle source | `Uniswap/v4-core@v4.0.0` at `e50237c43811bd9b526eff40f26772152a42daba` | A fixed official release is required for reproducible bit-identity work. |
| Compiler | Solidity `0.8.28` in the default Foundry profile | It satisfies v4-core's `^0.8.0` pragma without legacy v3 compiler profiles. |
| Dependency resolution | Forge Git submodule, generated lock file, and `v4-core/` remapping | The gitlink, lock, and alias jointly preserve source identity and import stability. |
| Integration seam | `evm/src/TickMathHarness.sol` delegates to upstream TickMath | Compiling a real library call proves import and linkage without copying oracle arithmetic. |
| Authentication | Not applicable | This phase creates a local pure build harness, not a deployed or authenticated service. |
| Execution target | Local `forge build --root evm` | The scaffold requires no UI, database, server, or deployment environment. |
| Directory layout | `evm/{src,test,lib}` with config and pin metadata under `evm/` | Later Solidity differential slices can build on the same isolated Foundry root. |

## Stack Touched in Phase 1

- [ ] Project scaffold — nested Foundry root, Solidity compiler configuration, source/test/library directories
- [ ] Dependency — exact v4-core release represented by submodule gitlink and generated lock metadata
- [ ] Import wiring — explicit `v4-core/` remapping consumed by the harness
- [ ] End-to-end build — `forge build --root evm` compiles a real TickMath call
- [ ] Artifact hygiene — Forge cache, output, and broadcast directories remain untracked
- [ ] Local operation — `evm/README.md` records the pin, alias, and build command

## Out of Scope (Deferred to Later Slices)

- Seaport `DifferentialTest`, differential smoke tests, and TickMath corpus reuse
- `evm-spec-bridge`, `hevm.call`, relay configuration, FFI, and bridge-failure handling
- EVM-adapted or Haskell `SqrtGrid` implementation changes
- HEVM/Haskell oracle comparison, non-vacuity counters, and relay skip/probe behavior
- UI, database, authentication, and deployment infrastructure
- Legacy Solidity 0.7.6 compiler profiles or v3 TickMath APIs

## Subsequent Slice Plan

Each later phase adds one runnable vertical slice on this build boundary:

- Phase 2: Compile and exercise a Seaport-style differential base.
- Phase 3: Import the pinned bridge submodule and expose the `hevm.call` seam.
- Phase 4: Run the TickMath corpus through a non-vacuous exact differential scaffold.
- Phase 5: Reach the HEVM oracle through the bridge.
- Phase 6: Make Haskell TickMath/SqrtGrid paths bit-identical.
- Phase 7: Extend exactness to staged `mulDiv` words and revert classes.
- Phase 8: Keep consumers green and close the compatibility/scope ledger.
