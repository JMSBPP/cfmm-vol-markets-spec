# EVM TickMath Oracle Scaffold

This nested Foundry project provides the compile-time integration seam for the
canonical Uniswap TickMath oracle.

## Pinned dependency

- Release: `Uniswap/v4-core@v4.0.0`
- Resolved revision: `e50237c43811bd9b526eff40f26772152a42daba`
- Import alias: `v4-core/` → `lib/v4-core/`

The submodule gitlink, `foundry.lock`, and `remappings.txt` jointly pin the
source used by `TickMathHarness`.

## Build

From the repository root:

```sh
forge build --root evm
```

## Scope

This is a scaffold-only compile boundary. It intentionally contains no Seaport
differential suite, bridge or relay wiring, HEVM/FFI configuration, or SqrtGrid
implementation.
