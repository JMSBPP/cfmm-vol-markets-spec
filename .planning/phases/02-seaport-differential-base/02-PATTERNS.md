# Phase 2 — Pattern Map

> Research skipped; patterns derived from CONTEXT + Phase 1 + vol-markets analogs.

## Files to create/modify

| Path | Role | Analog |
|------|------|--------|
| `evm/lib/seaport` | Seaport@1.6 submodule | Phase 1 `evm/lib/v4-core` |
| `evm/lib/forge-std` | Dedicated forge-std | vol-markets / Foundry default |
| `evm/foundry.toml` / `remappings.txt` | `@seaport/`, `forge-std/` | vol-markets remappings |
| `evm/test/diff/DiffTestBase.sol` | Seaport helpers | `PlankDiffTestBase.sol` (sans Plank) |
| `evm/src/HevmTickMathHarness.sol` | HEVM stub | `TickMathHarness.sol` |
| `evm/test/diff/TickMath.Hevm.diff.t.sol` | Skeleton diff | `VegaTarget.diff.t.sol` |
| `.github/workflows/ci.yml` | pins + RED assert | Phase 1 forge job |
| `evm/README.md` | RED doctrine | existing README |

## Patterns

- Inherit upstream test client; swap oracle in Context (vol-markets).
- `DifferentialTest.assertPass` + `stateless` modifier.
- CI recursive submodules already required for v4-core; extend pin asserts.

## PATTERNS COMPLETE
