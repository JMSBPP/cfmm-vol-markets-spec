# Phase 3: Bridge submodule - Pattern Map

**Mapped:** 2026-09-08  
**Files analyzed:** 14 implementation artifacts  
**Analogs found:** 13 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.gitmodules` | config / vendored dependency | file-I/O | existing `evm/lib/{v4-core,seaport,forge-std}` entries | exact |
| `evm/lib/evm-spec-bridge` | pinned git submodule | file-I/O | `evm/lib/seaport` | exact |
| `evm/foundry.lock` | dependency lock config | file-I/O | existing `lib/seaport` lock entry | exact |
| `evm/foundry.toml` | Foundry configuration | request-response | existing default profile and remappings | exact |
| `evm/remappings.txt` | Solidity import configuration | transform | existing `@seaport/` and `forge-std/` aliases | exact |
| `evm/src/HevmTickMathHarness.sol` | Solidity adapter / oracle | request-response | Phase 2 `HevmTickMathHarness.sol`; bridge `solidity/src/Hevm.sol` | role-match |
| `evm/test/diff/TickMath.Hevm.diff.t.sol` | integration differential test | request-response | existing Phase 2 minimum-tick tracer | exact |
| `evm/README.md` | operator documentation | file-I/O | existing Phase 2 RED-boundary documentation | role-match |
| `package.yaml` | Haskell component configuration | transform | existing `plot` internal library and executable stanzas | exact |
| `cfmm-vol-markets-spec.cabal` | generated Cabal manifest | transform | `package.yaml` / current generated manifest | exact |
| `src/HevmTickMathAdapter.hs` | private Haskell adapter | transform | `src/SqrtGrid.hs` | role-match |
| `app/HevmTickMathPeer/Main.hs` | relay data-plane executable | event-driven | bridge `components/relay/app/fake-hevm-echo/Main.hs` | role-match |
| `scripts/hevm-tickmath-relay.sh` | CI lifecycle runner | event-driven | bridge `scripts/hevm-call-smoke.sh` | exact |
| `.github/workflows/ci.yml` | CI orchestration | batch | existing Forge and Stack jobs | exact |

`stack.yaml` is not classified as a mandatory edit: the research explicitly makes its
`hevm-0.58.0` `extra-deps` entry conditional on an initial Stack resolution failure.

## Pattern Assignments

### `.gitmodules`, `evm/lib/evm-spec-bridge`, and `evm/foundry.lock` (pinned dependency, file-I/O)

**Analogs:** `.gitmodules` lines 1-9 and `evm/foundry.lock` lines 1-19.

Follow the existing direct-gitlink layout under `evm/lib`; add the bridge URL as one
new direct submodule, then record the resolved pin in the Foundry lock and assert the
same SHA in CI. Do not use a nested or floating clone.

```ini
[submodule "evm/lib/v4-core"]
	path = evm/lib/v4-core
	url = https://github.com/Uniswap/v4-core
[submodule "evm/lib/seaport"]
	path = evm/lib/seaport
	url = https://github.com/ProjectOpenSea/seaport
```

```json
"lib/seaport": {
  "tag": {
    "name": "1.6",
    "rev": "e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd"
  }
}
```

The Phase 3 bridge must use the locked path `evm/lib/evm-spec-bridge` and the
researched commit `aad230528f93be04a00d0209f10eaa3084d84de5`.

---

### `evm/foundry.toml` and `evm/remappings.txt` (configuration, request-response / transform)

**Analogs:** `evm/foundry.toml` lines 1-11 and `evm/remappings.txt` lines 1-3.

Keep the default project directory keys and array-based remappings in `foundry.toml`;
mirror every Solidity alias in `remappings.txt`. Change the compiler at the default
profile because `Hevm.sol` is `^0.8.34`, then introduce an opt-in `hevm` profile with
only `ffi = true`.

```toml
[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["lib"]
solc_version = "0.8.28"
remappings = [
    "@seaport/=lib/seaport/test/foundry/",
    "forge-std/=lib/forge-std/src/",
    "v4-core/=lib/v4-core/",
]
```

```text
@seaport/=lib/seaport/test/foundry/
forge-std/=lib/forge-std/src/
v4-core/=lib/v4-core/
```

---

### `evm/src/HevmTickMathHarness.sol` (Solidity adapter, request-response)

**Analogs:** local `evm/src/HevmTickMathHarness.sol` lines 1-10 for the narrow
one-method public surface; bridge
`/home/jmsbpp/apps/evm_spec_rpc/.worktrees/hevm-call-stdcheats/solidity/src/Hevm.sol`
lines 9-24 for FFI delegation and failure propagation.

Retain a single `getSqrtPriceAtTick(int24)` entry. Replace the stub body only after
the profile/socket guard; delegate transport entirely to the bridge library. The
bridge result is JSON stdout—not ABI-encoded `uint160`—so add strict non-empty,
decimal-JSON, and `uint160` range validation before the narrow conversion.

```solidity
/// @title HevmTickMathHarness
/// @notice Phase 2 oracle seam; Phase 3 replaces only this body with live HEVM wiring.
contract HevmTickMathHarness {
    function getSqrtPriceAtTick(int24) external pure returns (uint160) {
        revert("hevm.call not wired");
    }
}
```

```solidity
function call(string memory method, string memory paramsJson) internal returns (bytes memory resultStdout) {
    string[] memory inputs = new string[](4);
    inputs[0] = "relay";
    inputs[1] = "send";
    inputs[2] = method;
    inputs[3] = paramsJson;
    (bool ok, bytes memory ret) = VM_ADDR.call(abi.encodeWithSignature("ffi(string[])", inputs));
    require(ok, "hevm.call: ffi failed");
    resultStdout = abi.decode(ret, (bytes));
}
```

**Required error split:** missing profile/socket must revert
`HevmTickMathHarness: relay/profile unavailable`; do not catch bridge FFI errors or
replace them with a canonical-side value.

---

### `evm/test/diff/TickMath.Hevm.diff.t.sol` (integration differential test, request-response)

**Analog:** `evm/test/diff/TickMath.Hevm.diff.t.sol` lines 8-68.

Preserve the upstream-named min-tick tracer and its Side A → swapped-Side B sequence.
Because the bridge call is stateful FFI, update the oracle interface and execution
function mutability consistently if the harness is no longer `view`; do not change
the test name or add corpus cases in this phase.

```solidity
function test_getSqrtPriceAtTick_isValidMinTick() public {
    FuzzArgs memory args = FuzzArgs({tick: canonical.MIN_TICK()});
    Context memory context =
        Context({oracle: ITickMathOracle(address(canonical)), expectedSqrtPriceX96: canonical.MIN_SQRT_PRICE()});

    test(this.fn, context, args);

    context.oracle = ITickMathOracle(address(hevm));
    this.fn(context, args);

    diffComparisons++;
    _requireComparisonRan();
}
```

```solidity
function fn(Context memory context, FuzzArgs memory args) external view stateless {
    assertEq(
        context.oracle.getSqrtPriceAtTick(args.tick),
        context.expectedSqrtPriceX96,
        "getSqrtPriceAtTick: exact equality"
    );
}
```

---

### `evm/README.md` (operator documentation, file-I/O)

**Analog:** `evm/README.md` lines 23-49.

Replace the intentional-RED section with an operator-oriented live-path section:
bridge pin/remapping, trusted `FOUNDRY_PROFILE=hevm`, bridge-binary `PATH`,
`RELAY_SOCK`, relayd, local peer, and the matched Forge command. State BRIDGE-03's
issue-and-notify rule, linking `../AGENTS.md` section 7 and
`../.planning/REQUIREMENTS.md` BRIDGE-03. Include the required evidence: repro,
expected/actual, package SHA, bridge SHA, and logs.

```markdown
## Intentional RED differential seam

The Phase 2 tracer invokes the upstream-named
`test_getSqrtPriceAtTick_isValidMinTick` path through the canonical `v4-core`
client, then swaps its context oracle to `HevmTickMathHarness`.

```sh
forge test --root evm --match-contract HevmDiffTest
```
```

---

### `package.yaml` and `cfmm-vol-markets-spec.cabal` (private-component configuration, transform)

**Analog:** `package.yaml` lines 22-68.

Keep top-level `dependencies` unchanged. Create a private `hevm-adapter` internal
library rooted in `src` that depends on the public package plus exact
`hevm == 0.58.0`, `aeson`, `network`, and `bytestring`; add the peer executable
depending on that internal library. Regenerate the Cabal manifest from Hpack rather
than hand-diverging it.

```yaml
# Package-level deps are the PURE numeric core only.  Chart/Chart-cairo/colour
# belong to the `plot` internal library alone -- see the note on `library:` below.
dependencies:
- base >= 4.7 && < 5
- mwc-random
- vector

internal-libraries:
  plot:
    source-dirs: plot
    dependencies:
    - cfmm-vol-markets-spec
    - Chart
```

```yaml
executables:
  cfmm-vol-markets-spec-exe:
    main:                Main.hs
    source-dirs:         app
    dependencies:
    - cfmm-vol-markets-spec
    - cfmm-vol-markets-spec:plot
    - directory
```

---

### `src/HevmTickMathAdapter.hs` (private numeric adapter, transform)

**Analog:** `src/SqrtGrid.hs` lines 1-31 and 97-104.

Use an explicit export list and destructure `SqrtPriceX96` at the adapter boundary.
Import the published `EVM` module qualified; never create `src/EVM.hs`. Expose
exactly `getSqrtPriceAtTick`, using existing `SqrtGrid.sqrtPriceX96` and without
changing SqrtGrid's numerical algorithm.

```haskell
module SqrtGrid
  ( Tick
  , SqrtPrice
  , SqrtPriceX96(..)
  , PayoffX96(..)
  , pattern Q96
  , toDouble
  , payoffToDouble
  , sqrtPrice
  , sqrtPriceX96
  ) where

type Tick = Int
newtype SqrtPriceX96 = SqrtPriceX96 Integer deriving (Show, Eq, Ord)
```

```haskell
sqrtPriceX96 :: Tick -> SqrtPriceX96
sqrtPriceX96 i = SqrtPriceX96 $ floor $ sqrtPrice i * fromIntegral Q96
```

---

### `app/HevmTickMathPeer/Main.hs` (relay data-plane executable, event-driven)

**Analog:** bridge
`components/relay/app/fake-hevm-echo/Main.hs` lines 1-81.

Copy its argument/env socket resolution, bounded AF_UNIX connection retry,
line-buffered handle, NDJSON loop, and I/O-exception termination behavior. Substitute
the one-method adapter dispatch for `echo`; reject any wrong method, non-singleton
params, invalid `Int`/int24 range, and malformed request. Return the adapter's
integer as a JSON number through the existing bridge wire codec.

```haskell
resolveSock :: [String] -> IO (Maybe FilePath)
resolveSock ("--sock" : p : _) = pure (Just p)
resolveSock (_ : rest) = resolveSock rest
resolveSock [] = lookupEnv "RELAY_SOCK"

runEcho :: FilePath -> IO ()
runEcho sockPath = do
  sock <- connectRetrying sockPath 50
  h <- socketToHandle sock ReadWriteMode
  hSetBuffering h LineBuffering
  loop h
```

```haskell
case decodeRequest lineBs of
  Right (RpcRequest rid method params)
    | method == "echo" ->
        (BS.hPut h (encodeResponse (RpcResult rid params)) >> hFlush h)
          `catch` \(_ :: IOException) -> pure ()
  _ -> pure ()
```

---

### `scripts/hevm-tickmath-relay.sh` (bounded lifecycle runner, event-driven)

**Analog:** bridge `scripts/hevm-call-smoke.sh` lines 1-55.

Use a single `set -euo pipefail` runner that derives/exports `RELAY_SOCK`, removes
both sockets before starting, records PIDs, waits finitely for `${SOCK}.ctl`, starts
the local peer, probes readiness, then runs the profile-gated Forge test. Cleanup
must kill and `wait` for both child PIDs and remove both sockets.

```bash
cleanup() {
  if [[ -n "${ECHO_PID:-}" ]]; then
    kill "$ECHO_PID" 2>/dev/null || true
    wait "$ECHO_PID" 2>/dev/null || true
  fi
  if [[ -n "${RELAYD_PID:-}" ]]; then
    kill "$RELAYD_PID" 2>/dev/null || true
    wait "$RELAYD_PID" 2>/dev/null || true
  fi
  rm -f "$SOCK" "${SOCK}.ctl"
}
trap cleanup EXIT
```

```bash
ready=0
for _ in $(seq 1 50); do
  if [[ -S "${SOCK}.ctl" ]]; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then
  echo "ERROR: relayd control sock not ready at ${SOCK}.ctl" >&2
  exit 1
fi
```

---

### `.github/workflows/ci.yml` (CI orchestration, batch)

**Analog:** `.github/workflows/ci.yml` lines 20-78 and 80-111.

Extend the existing recursive Forge checkout and explicit pin assertions with the
bridge gitlink/remapping/lock checks. Replace the Phase 2 `set +e` intentional-RED
block with a bounded invocation of the lifecycle runner, which must run
`FOUNDRY_PROFILE=hevm forge test --root evm --match-contract HevmDiffTest -vv`.
Extend the Stack environment only as needed for the private HEVM component and retain
the existing `--pedantic` build and test gates.

```yaml
- name: Assert exact Foundry dependency pins
  run: |
    v4_core_expected=e50237c43811bd9b526eff40f26772152a42daba
    seaport_expected=e9c5a9f17cb5ee658ccc9cb1a8eeab02c1f5a4cd
    forge_std_expected=620536fa5277db4e3fd46772d5cbc1ea0696fb43

    v4_core_actual="$(git -C evm/lib/v4-core rev-parse HEAD)"
    seaport_actual="$(git -C evm/lib/seaport rev-parse HEAD)"
```

```yaml
- name: Assert HevmDiffTest remains intentionally RED
  run: |
    set +e
    out="$(forge test --root evm --match-contract HevmDiffTest -vv 2>&1)"
    rc=$?
    set -e
```

The latter is the code to replace, not preserve.

## Shared Patterns

### Pin provenance
**Sources:** `.gitmodules` lines 1-9, `evm/foundry.lock` lines 1-19, and
`.github/workflows/ci.yml` lines 32-57.  
**Apply to:** Bridge gitlink, lock, remappings, and CI.

The same immutable SHA must be represented and asserted across all four surfaces.

### Cause-specific failure
**Sources:** `evm/src/HevmTickMathHarness.sol` lines 4-9; bridge `Hevm.sol` lines
16-23.  
**Apply to:** Harness and CI test interpretation.

Configuration/readiness absence has the dedicated `relay/profile unavailable` error;
live bridge/FFI failure remains bridge-owned and loud. No skip, fallback, or
intentional-RED assertion remains after this phase.

### Narrow public Haskell boundary
**Sources:** `src/SqrtGrid.hs` lines 3-24 and `package.yaml` lines 22-55.  
**Apply to:** Adapter and peer component configuration.

The public library remains pure/HEVM-free; only the new internal library and
executable may import `EVM`, socket, and JSON packages.

### Bounded Unix-socket process lifecycle
**Sources:** bridge `scripts/hevm-call-smoke.sh` lines 7-55 and bridge
`fake-hevm-echo/Main.hs` lines 39-81.  
**Apply to:** peer executable and CI runner.

Use bounded retries/readiness checks and EXIT cleanup. A bare sleep may only be a
small post-start settle, never the sole readiness guarantee.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `src/HevmTickMathAdapter.hs` | private HEVM adapter | transform | No existing local module imports Hackage `EVM`; combine the local SqrtGrid export/type pattern with the researched Hackage dependency boundary. |

## Metadata

**Analog search scope:** `evm/`, root Haskell package configuration, `src/`, `test/`,
Phase 2 artifacts, and the locally available pinned bridge worktree.  
**Files scanned:** 19 focused artifacts  
**Pattern extraction date:** 2026-09-08

## PATTERN MAPPING COMPLETE
