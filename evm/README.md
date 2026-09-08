# EVM TickMath + HEVM bridge

Nested Foundry project for the Uniswap TickMath oracle and the live
`hevm.call` differential against a local HEVM peer.

## Pinned dependencies

- `Uniswap/v4-core@v4.0.0`:
  `e50237c43811bd9b526eff40f26772152a42daba`
- `ProjectOpenSea/seaport@1.6`:
  `e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd`
- `foundry-rs/forge-std@v1.16.1`:
  `620536fa5277db4e3fd46772d5cbc1ea0696fb43`
- `JMSBPP/evm-spec-bridge` branch `feat/2-hevm-call-stdcheats`:
  `aad230528f93be04a00d0209f10eaa3084d84de5`

Remappings (see `remappings.txt` / `foundry.toml`):

- `v4-core/` → `lib/v4-core/`
- `@seaport/` → `lib/seaport/test/foundry/`
- `forge-std/` → `lib/forge-std/src/`
- `evm-spec-bridge/` → `lib/evm-spec-bridge/solidity/src/`

Compiler: **solc 0.8.34** (required by bridge `Hevm.sol` `pragma ^0.8.34`).
FFI is **off** in the default profile and **on** only under
`FOUNDRY_PROFILE=hevm`.

## Build

From the repository root:

```sh
git submodule update --init --recursive
forge build --root evm
```

## Transport-only smoke (bridge echo peer)

Proves `hevm.call` → `relay` → `relayd` with the bridge-owned fake echo peer.
Does **not** prove TickMath correctness.

```sh
bash scripts/hevm-bridge-transport-smoke.sh
```

## Live min-tick differential (acceptance)

Requires Stack, Forge, and native libs for Hackage `hevm-0.58.0` (e.g.
`libsecp256k1`, `libff`, `gmp`). The runner:

1. Builds Forge artifacts, bridge `relay`/`relayd`, and local `hevm-tickmath-peer`
2. Starts `relayd` on a private `RELAY_SOCK`, sets `HEVM_LIVE=1`
3. Probes `relay send getSqrtPriceAtTick '[-887272]'` until `"4295128739"`
4. Runs `FOUNDRY_PROFILE=hevm` matched `HevmDiffTest` (GREEN expected)
5. Reaps processes and sockets

```sh
bash scripts/hevm-tickmath-relay.sh
```

Allowed peer method: only `getSqrtPriceAtTick` with params JSON `[<int24>]`.
Result wire format: JSON **string** decimal (quotes required) so Foundry `vm.ffi`
does not hex-decode digit-only stdout.

Harness readiness: missing `HEVM_LIVE=1` or empty `RELAY_SOCK` reverts with
`HevmTickMathHarness: relay/profile unavailable`. Configured FFI/relay failures
propagate as bridge-owned `hevm.call: ffi failed` (do not catch or substitute
Side A / current `SqrtGrid` arithmetic).

Full TickMath corpus → Phase 4+. Bit-identical `SqrtGrid` → Phases 6–7.

## BRIDGE-03 — submodule failure protocol

If a failure is attributable to the bridge (submodule build, `hevm.call`, ffi,
relay, stdcheats, wrong encoding owned by the bridge):

1. Open a GitHub issue on **`JMSBPP/evm-spec-bridge`** with:
   - reproduction command
   - expected vs actual
   - this package commit SHA
   - submodule SHA (`git -C evm/lib/evm-spec-bridge rev-parse HEAD`)
   - `FOUNDRY_PROFILE` / `HEVM_LIVE` / `RELAY_SOCK` facts
   - forge / relay logs
2. Notify the user in chat with the **issue URL** and a short paste-ready brief
   for the bridge agent.
3. Do **not** silently patch around bridge bugs in this package unless the user
   explicitly directs a temporary workaround.

See also [`../AGENTS.md`](../AGENTS.md) §7 and
[`../.planning/REQUIREMENTS.md`](../.planning/REQUIREMENTS.md) **BRIDGE-03**.

Local HEVM / Stack / native dependency failures are **not** automatically
BRIDGE-03 — treat them as consumer integration issues unless the root cause is
clearly in the pinned bridge source or relay tools.
