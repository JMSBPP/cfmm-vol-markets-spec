# EVM TickMath Differential Base

This nested Foundry project provides the canonical Uniswap TickMath oracle and
the Phase 2 Seaport-style differential test boundary.

## Pinned dependencies

- `Uniswap/v4-core@v4.0.0`:
  `e50237c43811bd9b526eff40f26772152a42daba`
- `ProjectOpenSea/seaport@1.6`:
  `e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd`
- `foundry-rs/forge-std@v1.16.1`:
  `620536fa5277db4e3fd46772d5cbc1ea0696fb43`

The top-level gitlinks and `foundry.lock` jointly pin the source used by the
local contracts and test suite. Their remappings are:

- `v4-core/` → `lib/v4-core/`
- `@seaport/` → `lib/seaport/test/foundry/`
- `forge-std/` → `lib/forge-std/src/`

## Build

From the repository root:

```sh
forge build --root evm
```

The build is expected to succeed.

## Intentional RED differential seam

The Phase 2 tracer invokes the upstream-named
`test_getSqrtPriceAtTick_isValidMinTick` path through the canonical `v4-core`
client, then swaps its context oracle to `HevmTickMathHarness`.

```sh
forge test --root evm --match-contract HevmDiffTest
```

This command is expected to exit non-zero with `hevm.call not wired`.
That failure proves execution reached the deliberate adapter boundary; it is
not a skipped test and must never become a silent pass.

GREEN is forbidden until Phase 3 replaces only the
`HevmTickMathHarness` body with live bridge wiring. The remaining upstream
TickMath corpus is deliberately deferred to Phase 4. This phase contains no
live `hevm.call`, relay/FFI configuration, or SqrtGrid implementation.
