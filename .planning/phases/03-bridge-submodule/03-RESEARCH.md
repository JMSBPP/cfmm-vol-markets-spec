# Phase 03: Bridge submodule - Research

**Researched:** 2026-09-08  
**Domain:** Foundry FFI → AF_UNIX JSON-RPC relay → Haskell/HEVM TickMath peer  
**Confidence:** MEDIUM

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

## Implementation Decisions

### Gray-area focus
- **D-01:** Discussed **harness wire-up** only. Submodule path/pin layout and solc/`^0.8.34` remapping strategy were **not** discussed — planner/implementer discretion (see Discretion + Deferred scout note).

### Harness / `hevm.call`
- **D-02:** Replace Phase 2 stub with **live `hevm.call`** (encode TickMath method/params) — GREEN only when relay/HEVM is up.
- **D-03:** **Dual path:** when `FOUNDRY_PROFILE=hevm` (or equivalent env) is set and the path is live, call through; otherwise **explicit revert** with a distinct “relay/profile down” message (not silent skip, not the old `"hevm.call not wired"` forever).
- **D-04:** First live vector remains **`test_getSqrtPriceAtTick_isValidMinTick`** / harness `getSqrtPriceAtTick` only.

### Haskell / HEVM surface (prerequisite for queryable Side B)
- **D-05:** **`EVM.hs` is not authored here** — use **`module EVM` from the Hackage `hevm` Cabal package** (verified locally as `hevm-0.58.0/src/EVM.hs`).
- **D-06:** Phase 3 **declares `hevm` as a dependency** and adds a **thin adapter** so one TickMath method is callable via the bridge/`hevm.call`.
- **D-07:** Thin adapter **lives in this package** (`src/` module importing `EVM`); this package owns the HEVM-facing TickMath/SqrtGrid entry the relay hits.
- **D-08:** Surface is **one method only** — `getSqrtPriceAtTick` (enough for min-tick GREEN); remaining TickMath API later (Phase 4+).

### CI
- **D-09:** Phase 3 CI **requires GREEN**: start relay + HEVM and expect the min-tick `HevmDiffTest` vector to pass (replaces Phase 2’s intentional-RED/`hevm.call not wired` gate for this suite once wired).

### Already locked (from REQUIREMENTS / prior phases — do not reopen)
- Submodule repo/branch: **`JMSBPP/evm-spec-bridge`**, **`feat/2-hevm-call-stdcheats`**
- Do not reinvent cheats/relay; BRIDGE-03 → issue on bridge repo + notify user (`AGENTS.md` §7)
- Side A = v4-core TickMath; Side B = harness → `hevm.call` → Haskell
- Research tip when captured: `aad230528f93be04a00d0209f10eaa3084d84de5` (confirm at plan/execute time)

### the agent's Discretion
- Exact submodule filesystem path (`evm/lib/…` vs root `lib/…`) and whether to pin tip SHA vs floating branch tip at add time
- How to reconcile bridge `Hevm.sol` `pragma ^0.8.34` with current `evm/` **solc 0.8.28** (bump vs profile/isolation)
- Exact Cabal/`package.yaml` / Stack wiring for `hevm` (version bounds, flags, extra-deps)
- Thin adapter module name, method JSON shape, and how SqrtGrid is referenced from the adapter without a full bit-id rewrite
- Exact dual-path gate (`FOUNDRY_PROFILE=hevm` vs env var vs both) and distinct revert string when down
- CI job shape for bringing up relayd/HEVM (services, scripts, timeouts) — must still satisfy D-09

### Deferred Ideas (OUT OF SCOPE)

## Deferred Ideas

- **Submodule path + pin layout** — gray area 1 not selected; still required work, agent discretion
- **Solc / remapping for `^0.8.34`** — gray area 2 not selected; scout note remains; agent discretion
- Full Uniswap TickMath corpus → **Phase 4**
- Broader `hevm.call` seam / oracle maturity → **Phase 5** (roadmap); Phase 3 still wires the first live path
- Bit-identical SqrtGrid TickMath + `mulDiv` → **Phases 6–7**
- Full TickMath API mirror on the Haskell adapter → later phases
</user_constraints>

## Project Constraints (from AGENTS.md)

- This research task must only create the requested planning research artifact; it must not create branches, commits, issues, PRs, or modify TODO state. [VERIFIED: local `AGENTS.md` and user instruction] (HIGH)
- If implementation exposes a bridge-attributable fault (submodule build, `hevm.call`, FFI, relay, or stdcheats), it must open an issue on the bridge repository with repro, expected/actual, this-package SHA, submodule SHA, and logs; notify the user with the issue URL and paste-ready brief; do not locally patch around the bridge without user authorization. [VERIFIED: local `AGENTS.md` §7] (HIGH)
- If a TODO item is ever implemented, the canonical repository is `d2p-finance/cfmm-vol-markets-spec`; pushes go only to the `JMSBPP` fork and PRs target canonical `main`. That workflow is not invoked by this research-only phase. [VERIFIED: local `AGENTS.md`] (HIGH)

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BRIDGE-01 | Consume `JMSBPP/evm-spec-bridge` as a pinned submodule and import `hevm.call(method, paramsJson)`. | Pin `aad230528f93be04a00d0209f10eaa3084d84de5` at `evm/lib/evm-spec-bridge`; map `evm-spec-bridge/=lib/evm-spec-bridge/solidity/src/`; import `Hevm.sol`. |
| BRIDGE-02 | Document relay and `FOUNDRY_PROFILE=hevm` (or equivalent) prerequisites for CI. | `hevm` Foundry profile must enable FFI; PATH must expose bridge-built `relay`; `RELAY_SOCK`, `relayd`, and the TickMath peer must be live before Forge runs. |
| BRIDGE-03 | Follow the submodule failure issue-and-notify protocol. | README must link both `AGENTS.md` §7 and `REQUIREMENTS.md` BRIDGE-03 and include the required issue evidence checklist. |
</phase_requirements>

## Summary

Implement the bridge as one vertical, pinned path: `evm/lib/evm-spec-bridge` at `aad230528f93be04a00d0209f10eaa3084d84de5`, a single `evm-spec-bridge/` remapping to its `solidity/src`, a default Forge compiler bump to 0.8.34, and a `profile.hevm` that enables FFI. The bridge's verified `hevm.call` emits `relay send <method> <params-json>` through `vm.ffi`; it has no ABI encoder/decoder and returns the peer's raw JSON result bytes. [VERIFIED: `JMSBPP/evm-spec-bridge@aad230528f93be04a00d0209f10eaa3084d84de5`, `solidity/src/Hevm.sol`, remote branch ref] (MEDIUM)

The existing Phase 2 test already performs Side A then Side B for `MIN_TICK`. Replace only the stub behavior with a call to method `getSqrtPriceAtTick` and a JSON parameter array containing the signed tick. Solidity must validate and decode the JSON scalar returned by the Haskell peer into `uint160`, rather than treating the bridge output as ABI returndata. The local bridge smoke demonstrates raw JSON result bytes (`[1]`) rather than ABI encoding. [VERIFIED: local Phase 2 seam and bridge `solidity/test/HevmCall.t.sol`] (MEDIUM)

The current bridge branch contains `relay`, `relayd`, and `fake-hevm-echo`, but no real HEVM-connected TickMath peer. Therefore CI GREEN requires this repository to add the locked thin adapter *and an executable peer process that dials relayd's data socket*. Merely adding `hevm` to Cabal and importing `EVM` cannot make `hevm.call` live: `EVM` is an exposed Haskell library module, not a daemon that accepts this relay protocol. [VERIFIED: bridge relay package, smoke script, Hackage `hevm-0.58.0` cabal] (MEDIUM)

**Primary recommendation:** Pin the bridge under `evm/lib`, use Forge 0.8.34 globally plus `profile.hevm.ffi = true`, and implement a private HEVM adapter library plus a `hevm-tickmath-peer` executable that services exactly one JSON-RPC method over relayd's AF_UNIX data socket.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `hevm.call` invocation and strict result conversion | EVM test/harness | Relay process | The harness owns the Solidity API and must turn bridge stdout into the expected `uint160`. |
| FFI transport and request correlation | External process | EVM test/harness | `relay`/`relayd` own opaque JSON-RPC transfer; Solidity only invokes the CLI. |
| TickMath response | Haskell executable | Haskell private adapter | The peer owns method dispatch; adapter owns the one `SqrtGrid` query and imports Hackage `EVM`. |
| Canonical expected value | EVM test/harness | v4-core dependency | Existing `TickMathTest` remains Side A and supplies `MIN_TICK` / `MIN_SQRT_PRICE`. |
| CI process lifecycle | CI workflow | shell runner script | CI must build binaries, start and probe daemons, set PATH/profile, run test, and always reap processes. |
| Bridge fault escalation | Documentation/process | CI logs | Maintainers need reproducible evidence and must not conceal bridge faults with local fallback code. |

## Standard Stack

### Core

| Component | Pin/version | Purpose | Prescriptive use |
|-----------|-------------|---------|------------------|
| `JMSBPP/evm-spec-bridge` | branch `feat/2-hevm-call-stdcheats`, commit `aad230528f93be04a00d0209f10eaa3084d84de5` | `hevm.call`, `relay`, and `relayd` | Add as the direct submodule `evm/lib/evm-spec-bridge`, then record/assert its SHA. [VERIFIED: remote branch and local worktree] |
| Foundry / Forge | installed `1.5.1-stable`; project solc `0.8.34` | compiles the bridge import and runs trusted FFI test profile | Set `solc_version = "0.8.34"` in `evm/foundry.toml`; set only `ffi = true` in `[profile.hevm]`. [CITED: https://www.getfoundry.sh/config/profiles; https://www.getfoundry.sh/config/testing] |
| Hackage `hevm` | `0.58.0` | provides the existing exposed `EVM` module | Add an exact `hevm == 0.58.0` dependency only to a private adapter component, not the public library. [CITED: https://hackage.haskell.org/package/hevm-0.58.0/hevm.cabal] |
| existing `SqrtGrid` | local module | supplies the Phase 3 numerical result | Call existing `sqrtPriceX96` without changing its algorithm; this is query plumbing, not Phase 6 bit-identical port work. [VERIFIED: local `src/SqrtGrid.hs`] |

### Supporting

| Component | Version/pin | Purpose | When to use |
|-----------|-------------|---------|-------------|
| `relay`, `relayd` | bridge submodule at the pinned SHA | short-lived FFI client and long-lived AF_UNIX daemon | Build from submodule with its own `stack.yaml`; prepend its local install `bin` directory to PATH. [VERIFIED: bridge smoke script] |
| `hevm-tickmath-peer` | new local executable | real relay data-plane peer and one-method dispatcher | Start after relayd's control socket is ready and before `forge test`. [ASSUMED] |
| `aeson`, `network`, `bytestring` | resolver-selected | local peer JSON-RPC and AF_UNIX transport | Put in the private adapter/executable component; reuse bridge protocol behavior, not its source. [ASSUMED] |

### Discretion Decisions — Recommendation

1. **Submodule path/pin:** use `evm/lib/evm-spec-bridge` and commit the gitlink at `aad230528f93be04a00d0209f10eaa3084d84de5`; do not leave a floating branch checkout. It matches all existing Forge dependencies under `evm/lib`, keeps `libs = ["lib"]` correct, and makes CI SHA assertion straightforward. [VERIFIED: local `.gitmodules`, `evm/foundry.toml`, and remote branch] (MEDIUM)
2. **Compiler:** raise `evm/foundry.toml` default `solc_version` from 0.8.28 to 0.8.34. A profile-only compiler override cannot preserve a default build once the default source graph imports `Hevm.sol` with `pragma ^0.8.34`. Existing imported Phase 2 / Seaport test utilities use compatible `^0.8.x` pragmas; only the selected TickMath graph must compile. [VERIFIED: bridge `Hevm.sol`; local Phase 2 sources; local Seaport/v4 pragma scan] (MEDIUM)
3. **Haskell wiring:** preserve COMPAT-03 with an `internal-libraries.hevm-adapter` component using `source-dirs: src` and `dependencies: [cfmm-vol-markets-spec, hevm == 0.58.0, aeson, network, bytestring]`; add an executable that depends on this internal library. Keep top-level `dependencies` unchanged so the public `library` remains HEVM-free. Add `hevm-0.58.0` to `stack.yaml` `extra-deps` only if `stack build` reports it absent from LTS. [CITED: https://hackage.haskell.org/package/hevm-0.58.0/hevm.cabal; VERIFIED: local `package.yaml` and `stack.yaml`] (MEDIUM)
4. **Wire format:** use request `{"jsonrpc":"2.0","id":<id>,"method":"getSqrtPriceAtTick","params":[-887272]}` and result as one JSON decimal integer, e.g. `4295128739`; adapter rejects all other methods/arity/types. Harness constructs `[<decimal signed int24>]`, checks relay bytes are non-empty, parses decimal JSON, checks `<= type(uint160).max`, and returns `uint160`. The exact adapter JSON shape is a planner-owned implementation detail, but this shape minimizes Phase 3 surface. [ASSUMED]
5. **Dual-path gate:** gate by `FOUNDRY_PROFILE=hevm` as the authoritative Foundry switch and use `vm.envOr("RELAY_SOCK", "")` as a second explicit readiness guard. Revert with `HevmTickMathHarness: relay/profile unavailable` if either condition is absent; do not catch, skip, or substitute Side A. The running relay then determines live connectivity, and bridge FFI failure remains loud. [CITED: https://www.getfoundry.sh/config/profiles; https://www.getfoundry.sh/config/testing] (MEDIUM)
6. **CI:** replace the intentional-RED test step with a bounded runner that builds bridge relay executables and the local peer, exports their bins/PATH and `RELAY_SOCK`, starts `relayd`, waits for `${RELAY_SOCK}.ctl`, starts peer, waits for the data-plane connection using a health/probe, runs `FOUNDRY_PROFILE=hevm forge test --root evm --match-contract HevmDiffTest -vv`, and reaps all PIDs/sockets in an EXIT trap. Use the bridge smoke script as lifecycle precedent, but CI must use a real local peer—not `fake-hevm-echo`. [VERIFIED: bridge smoke script and relay design] (MEDIUM)

## Architecture Patterns

### System Architecture Diagram

```text
CI runner
  │ builds bridge relay binaries + local HEVM peer
  │ exports PATH, RELAY_SOCK, FOUNDRY_PROFILE=hevm
  ▼
forge test / HevmDiffTest
  │ Side A: v4-core TickMathTest.getSqrtPriceAtTick(MIN_TICK)
  │ Side B: HevmTickMathHarness.getSqrtPriceAtTick(MIN_TICK)
  ▼
hevm.call("getSqrtPriceAtTick", "[-887272]")
  │ vm.ffi: relay send …
  ▼
relay CLI ──control AF_UNIX──► relayd ──data AF_UNIX JSON-RPC──► hevm-tickmath-peer
                                                                    │
                                                                    ▼
                                              private `src/HevmTickMathAdapter`
                                              imports `EVM` and `SqrtGrid`
                                                                    │
                                                                    ▼
                                              JSON integer result → exact uint160 comparison
```

### Pattern 1: Pinned vendored Forge library

**What:** A direct git submodule under the Foundry project's `lib` directory plus an explicit remapping and SHA assertion.  
**When to use:** Always for the locked bridge branch.  
**Implementation:** Add `.gitmodules` entry for `evm/lib/evm-spec-bridge`, add `evm-spec-bridge/=lib/evm-spec-bridge/solidity/src/` to both `foundry.toml` and `remappings.txt`, and import `hevm` from `evm-spec-bridge/Hevm.sol`. [VERIFIED: existing local remapping/pin conventions and bridge source] (MEDIUM)

### Pattern 2: Trusted opt-in FFI profile

**What:** Default Forge configuration retains FFI disabled; `[profile.hevm]` inherits all settings and enables FFI.  
**When to use:** Only in the dedicated relay-up command / CI job.  
**Why:** Foundry documents FFI as arbitrary external-process execution and warns it should only be enabled in trusted environments. [CITED: https://www.getfoundry.sh/config/testing] (MEDIUM)

### Pattern 3: Private HEVM adapter boundary

**What:** A `src/HevmTickMathAdapter.hs` module importing `EVM` and `SqrtGrid`, compiled in a private internal library, consumed by a local peer executable.  
**When to use:** The only local Haskell bridge-side method in this phase.  
**Why:** It respects D-05–D-08 while avoiding the direct conflict between D-06's HEVM adapter and COMPAT-03's public-library HEVM-free requirement. [VERIFIED: `package.yaml` public library design and `REQUIREMENTS.md` COMPAT-03] (MEDIUM)

### Pattern 4: Cause-specific live-path failure

**What:** Configuration/readiness absence reverts with one distinct harness message; actual relay/FFI failure propagates from bridge's `require(ok, "hevm.call: ffi failed")`.  
**When to use:** All non-HEVM runs of `HevmDiffTest` and bridge transport failures.  
**Why:** A CI gate can distinguish forgotten profile/setup from bridge execution failure without creating a silent-green route. [VERIFIED: Phase 2 RED doctrine and bridge `Hevm.sol`] (MEDIUM)

## Don't Hand-Roll

| Problem | Do not build | Use instead | Why |
|---------|--------------|-------------|-----|
| Foundry cheat/FFI transport | a local `Vm` interface, custom `ffi` wrapper, or direct socket code in Solidity | bridge `hevm.call` | It is the locked shared stdcheats surface and preserves bridge ownership. [VERIFIED: CONTEXT D-02 and AGENTS §7] |
| Relay request correlation / AF_UNIX control protocol | a replacement relay in this repository | bridge `relay` + `relayd` | The bridge already owns request IDs, disconnects, bounds, errors, and CLI contract. [VERIFIED: bridge relay design] |
| `EVM.hs` | a local module named `EVM` | Hackage `hevm-0.58.0`, module `EVM` | The published library exposes `EVM`; a local shadow copy would violate D-05 and fork semantics. [CITED: https://hackage.haskell.org/package/hevm-0.58.0/hevm.cabal] |
| TickMath exact implementation | Phase 6 algorithm rewrite | existing `SqrtGrid.sqrtPriceX96` for only the query plumbing | Full bit parity is explicitly later work; Phase 3's job is connectivity. [VERIFIED: CONTEXT deferred ideas] |
| CI daemon lifecycle | unbounded background processes | a bounded runner with readiness checks, `trap`, and explicit PID cleanup | Stale sockets/processes make an FFI result nondeterministic. [VERIFIED: bridge smoke script] |

## Common Pitfalls

### Pitfall 1: Treating `hevm.call` output as ABI bytes
**What goes wrong:** `hevm.call` returns raw stdout from `relay send`, which is JSON result encoding, not `abi.encode(uint160)`.  
**Avoid:** Define one decimal JSON-result contract and explicitly validate/decode it in the harness. [VERIFIED: bridge `Hevm.sol` and `HevmCall.t.sol`] (MEDIUM)

### Pitfall 2: Leaving the Phase 2 RED CI assertion in place
**What goes wrong:** CI rejects a green test or requires obsolete `"hevm.call not wired"` text.  
**Avoid:** Replace the RED assertion with success-only `HevmDiffTest` execution under the HEVM runner; assert `diffComparisons > 0` through the existing test. [VERIFIED: local `.github/workflows/ci.yml` and Phase 2 test] (MEDIUM)

### Pitfall 3: Solc profile split that leaves the import graph uncompilable
**What goes wrong:** `Hevm.sol` is `^0.8.34` while the root test source imports it under 0.8.28.  
**Avoid:** Bump the default project compiler to 0.8.34, then validate `forge build --root evm` and profile build. [VERIFIED: local `evm/foundry.toml` and bridge `Hevm.sol`] (MEDIUM)

### Pitfall 4: Using `fake-hevm-echo` as Phase 3 acceptance
**What goes wrong:** The echo peer proves relay mechanics but never reaches the local adapter or `SqrtGrid`; exact min-tick equality would fail.  
**Avoid:** Keep echo only as bridge-owned smoke; Phase 3 CI starts the local one-method peer. [VERIFIED: bridge fake-peer implementation and smoke script] (MEDIUM)

### Pitfall 5: Accidentally adding HEVM to the public Haskell library
**What goes wrong:** Top-level `dependencies` in `package.yaml` feed the public library, violating COMPAT-03 and pulling HEVM/native dependencies into downstream consumers.  
**Avoid:** Place `hevm` in a private internal library/executable stanza. This is a required design reconciliation to be checked in the Phase 3 plan. [VERIFIED: local `package.yaml`, `REQUIREMENTS.md`] (MEDIUM)

### Pitfall 6: Collapsing bridge and local ownership
**What goes wrong:** A bridge failure is patched in the consumer, losing upstream reproducibility.  
**Avoid:** Stop, capture package/submodule SHAs and logs, issue upstream, and notify the user exactly as AGENTS §7 requires. [VERIFIED: local `AGENTS.md` §7] (HIGH)

## Code Examples

### Forge profile and bridge import

```toml
# evm/foundry.toml
[profile.default]
solc_version = "0.8.34"
libs = ["lib"]

[profile.hevm]
ffi = true

remappings = [
  "evm-spec-bridge/=lib/evm-spec-bridge/solidity/src/",
]
```

```solidity
import {hevm} from "evm-spec-bridge/Hevm.sol";

function getSqrtPriceAtTick(int24 tick) external returns (uint160) {
    if (bytes(vm.envOr("RELAY_SOCK", "")).length == 0) {
        revert("HevmTickMathHarness: relay/profile unavailable");
    }
    bytes memory result = hevm.call("getSqrtPriceAtTick", string.concat("[", vm.toString(tick), "]"));
    return _decodeJsonUint160(result);
}
```

The profile selection and FFI setting follow Foundry documentation; the import and call signature are verified in the pinned bridge. [CITED: https://www.getfoundry.sh/config/profiles; https://www.getfoundry.sh/config/testing] (MEDIUM)

### Local Haskell peer boundary

```haskell
-- src/HevmTickMathAdapter.hs, private internal-library module
module HevmTickMathAdapter (getSqrtPriceAtTick) where

import qualified EVM  -- published `hevm` module; never create src/EVM.hs
import SqrtGrid (SqrtPriceX96 (..), sqrtPriceX96)

getSqrtPriceAtTick :: Int -> Integer
getSqrtPriceAtTick tick =
  let SqrtPriceX96 price = sqrtPriceX96 tick
  in price
```

The module name, JSON dispatcher, and precise `EVM` API use are implementation discretion; using `EVM` as an import is locked, while the one-method `SqrtGrid` call is verified locally. This example intentionally does not claim Phase 6 bit identity. [ASSUMED]

### Bounded CI lifecycle

```bash
set -euo pipefail
export RELAY_SOCK="${RUNNER_TEMP}/cfmm-hevm.sock"
bridge_root="$GITHUB_WORKSPACE/evm/lib/evm-spec-bridge"

stack --stack-yaml "$bridge_root/stack.yaml" build \
  evm-spec-bridge-relay:exe:relay evm-spec-bridge-relay:exe:relayd
export PATH="$(stack --stack-yaml "$bridge_root/stack.yaml" path --local-install-root)/bin:$PATH"
stack build hevm-tickmath-peer

relayd --sock "$RELAY_SOCK" & relayd_pid=$!
trap 'kill "$peer_pid" "$relayd_pid" 2>/dev/null || true; rm -f "$RELAY_SOCK" "$RELAY_SOCK.ctl"' EXIT
until [[ -S "${RELAY_SOCK}.ctl" ]]; do sleep 0.1; done
stack exec -- hevm-tickmath-peer -- --sock "$RELAY_SOCK" & peer_pid=$!
# peer-health probe with a finite retry belongs here
FOUNDRY_PROFILE=hevm forge test --root evm --match-contract HevmDiffTest -vv
```

The bridge smoke provides the build/PATH/socket/trap sequence; replacing its fake peer with the local one is required by D-06–D-09. [VERIFIED: bridge `scripts/hevm-call-smoke.sh`; ASSUMED: local peer command and health probe]

## Environment Availability

| Dependency | Required by | Available | Version / state | Fallback |
|------------|-------------|-----------|-----------------|----------|
| Forge | BRIDGE-01 / CI | ✓ | 1.5.1-stable | none |
| Stack | local peer and bridge relay build | ✓ | 3.11.1 | none |
| Cabal | Hackage inspection / diagnostics | ✓ | 3.16.1.0 | Stack is the project build path |
| Hackage `hevm` metadata/source | D-05 / D-06 | ✓ | 0.58.0 source and official Cabal verified | pin as Stack extra-dep if resolver lacks it |
| `relay`, `relayd`, fake peer binaries | CI live path | ✗ on PATH | supplied by bridge source but not currently built | build their bridge Stack targets |
| actual local HEVM TickMath peer | D-09 | ✗ | not implemented in either tree inspected | Phase 3 must add it |

**Missing dependencies with no fallback:**
- A real local `hevm-tickmath-peer` protocol implementation is required for the mandated CI-green min-tick call; the bridge's echo peer cannot replace it. [VERIFIED: bridge contents] (MEDIUM)

**Missing dependencies with fallback:**
- `hevm` absent from the LTS snapshot can be supplied as the pinned Hackage `extra-deps` entry; confirm by running `stack build` after the component is declared. [ASSUMED]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Forge 1.5.1-stable, Foundry project under `evm/`; Stack 3.11.1 for Haskell build/test. [VERIFIED: local commands/config] |
| Config file | `evm/foundry.toml`, `stack.yaml`, `.github/workflows/ci.yml`. [VERIFIED: local files] |
| Quick run command | `FOUNDRY_PROFILE=hevm RELAY_SOCK=/tmp/cfmm-hevm.sock forge test --root evm --match-contract HevmDiffTest -vv` (after services are ready). |
| Full suite command | `forge build --root evm && <relay-up runner> && stack build --pedantic && stack test && lake build`. [VERIFIED: existing CI commands, ASSUMED: local relay runner] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File exists? |
|--------|----------|-----------|-------------------|--------------|
| BRIDGE-01 | Pinned bridge source is initialized, remapped, import compiles, and harness executes `hevm.call`. | build + integration | `git submodule status -- evm/lib/evm-spec-bridge`; `forge build --root evm`; relay-up Forge test | ❌ Wave 0 |
| BRIDGE-02 | HEVM profile has FFI and the README tells developers how to bring up relay/peer. | config/doc + integration | `FOUNDRY_PROFILE=hevm forge config --root evm`; relay-up Forge test | ❌ Wave 0 |
| BRIDGE-03 | README points to AGENTS §7 and requirements, including issue evidence. | documentation assertion | `rg -q 'AGENTS.md.*§7|BRIDGE-03' evm/README.md` | ❌ Wave 0 |
| Expanded D-02/D-04/D-09 | `MIN_TICK` Side B returns a valid `uint160` and existing exact assertion passes with `diffComparisons > 0`. | end-to-end differential | relay-up `forge test --root evm --match-contract HevmDiffTest -vv` | test exists; live path ❌ |
| D-03 | No HEVM profile/socket produces the distinct configuration failure, never old stub or silent green. | negative integration | `forge test --root evm --match-contract HevmDiffTest -vv` and assert marker/non-zero | ❌ Wave 0 |
| D-05–D-08 | Adapter imports package `EVM`, exposes only `getSqrtPriceAtTick`, and public library dependency remains HEVM-free. | Haskell build + static audit | `stack build --pedantic`; `rg` package component checks | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `forge build --root evm` plus the targeted local test applicable to the changed component. [VERIFIED: existing CI build gate] (MEDIUM)
- **Per wave merge:** relay-up `HevmDiffTest` command and `stack build --pedantic`. [ASSUMED]
- **Phase gate:** recursive submodules initialized; all CI jobs green; live min-tick differential green with `FOUNDRY_PROFILE=hevm`; no intentional-RED assertion remains. [VERIFIED: D-09 and existing CI] (MEDIUM)

### Wave 0 Gaps

- [ ] Add `evm/lib/evm-spec-bridge` submodule, remapping, lock/pin assertion, and import compilation check.
- [ ] Add private `src/HevmTickMathAdapter.hs` plus its component configuration and one-method unit/build check.
- [ ] Add `hevm-tickmath-peer` executable implementing only relay data-plane JSON-RPC request/response and a readiness health probe.
- [ ] Replace the harness stub with strict request/result conversion and a distinct `relay/profile unavailable` negative-path assertion.
- [ ] Replace CI's intentional-RED step with a trapped relay-up green runner and test its cleanup/readiness limits.
- [ ] Add `evm/README.md` setup and BRIDGE-03 protocol references.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | No | AF_UNIX local CI transport has no user-auth surface in this phase. [VERIFIED: bridge relay design] |
| V3 Session Management | No | Relay has a single short-lived local session, not web sessions. [VERIFIED: bridge relay design] |
| V4 Access Control | Yes | Enable FFI only in `profile.hevm`; ensure CI runs checked-out trusted bridge code at an asserted SHA. [CITED: https://www.getfoundry.sh/config/testing] |
| V5 Input Validation | Yes | Adapter permits one method and exact signed-int24 array; Solidity validates JSON decimal result range before narrowing. [ASSUMED] |
| V6 Cryptography | No | This phase moves an integer oracle result; it introduces no application cryptographic primitive. [VERIFIED: phase scope] |

### Known Threat Patterns

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Untrusted FFI command substituted through PATH | Elevation of privilege | FFI only in `hevm` profile; construct CI PATH from known Stack local-install roots; pin bridge gitlink. [CITED: https://www.getfoundry.sh/config/testing] |
| Stale/malicious AF_UNIX socket or peer | Tampering | runner removes socket before start, verifies relayd control socket, uses job-private temp path, and always cleans it. [VERIFIED: bridge smoke script] |
| Method/parameter confusion | Tampering | fixed method allowlist of one, strict JSON shape/type/range checks, no generic evaluator exposure. [ASSUMED] |
| Bridge defect silently hidden locally | Repudiation | BRIDGE-03 issue + SHA/log evidence + user notification. [VERIFIED: `AGENTS.md` §7] |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | A same-repository private internal Haskell library plus executable can satisfy the local ownership constraint while keeping the public package HEVM-free. | Discretion / Pattern 3 | Cabal/hpack component layout may need a separate local package or a user decision. |
| A2 | The proposed one-method decimal JSON schema and Solidity decoder are compatible with the eventual HEVM peer. | Discretion / Code Examples | Peer/harness protocol could need revision before live test passes. |
| A3 | A custom local peer must use `EVM` directly rather than only import it to meet D-05's intended semantic purpose. | Summary / Code Example | The adapter may link HEVM without using its evaluator meaningfully; user may need to refine the intended use. |
| A4 | `hevm-0.58.0` may need an explicit Stack `extra-deps` entry and native CI packages. | Haskell wiring / Environment | Stack resolution or Linux linking can fail. |

## Open Questions

1. **What concrete HEVM behavior must the peer execute for `getSqrtPriceAtTick`?**
   - What we know: D-05 locks the Hackage `EVM` module, and D-06 locks an adapter/one-method local endpoint.
   - What's unclear: The bridge implements relay transport but contains no real HEVM peer protocol implementation; existing `fake-hevm-echo` only reflects JSON.
   - Recommendation: Plan a short Wave 0 compile/protocol spike to define the peer's use of `EVM`; fail closed and ask the user if the intended answer is merely calling `SqrtGrid` rather than evaluating EVM semantics.

2. **How does the adapter retain `COMPAT-03`?**
   - What we know: Context requires a `hevm` dependency in this package, while requirements forbid a public library HEVM dependency.
   - What's unclear: Whether “this package” permits a private internal component/executable.
   - Recommendation: Adopt the private-component layout above and add a static package dependency audit; escalate only if Hpack cannot express it.

3. **What OS packages does `hevm-0.58.0` require in GitHub Actions?**
   - What we know: Its Cabal file declares native `secp256k1`, `ff`, and `gmp` libraries.
   - What's unclear: Exact Ubuntu package names and whether Stack can supply any of them.
   - Recommendation: Make the first CI task build the local peer, capture link errors, and treat a bridge fault separately from a local HEVM dependency failure. [CITED: https://hackage.haskell.org/package/hevm-0.58.0/hevm.cabal]

## Sources

### Primary (verified local/official)

- `JMSBPP/evm-spec-bridge@aad230528f93be04a00d0209f10eaa3084d84de5` — remote branch SHA, `Hevm.sol`, relay source, smoke lifecycle. [VERIFIED: local worktree and `git ls-remote`]
- `https://www.getfoundry.sh/config/profiles` — profile inheritance and `FOUNDRY_PROFILE`. [CITED]
- `https://www.getfoundry.sh/config/testing` — FFI configuration and trusted-environment warning. [CITED]
- `https://hackage.haskell.org/package/hevm-0.58.0/hevm.cabal` — version, AGPL license, exposed `EVM`, native libraries, Cabal bounds. [CITED]
- local `evm/`, Phase 2 context, requirements, CI, `package.yaml`, `stack.yaml`, and `src/SqrtGrid.hs` — current seam and compatibility boundary. [VERIFIED]

### Secondary (MEDIUM confidence)

- Bridge relay design document — control/data sockets, error semantics, daemon lifecycle, and explicit non-goals. [VERIFIED: local bridge worktree]

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM — pins/source and official Foundry/Hackage configuration verified; local peer is not implemented.
- Architecture: MEDIUM — existing bridge transport and current seam verified; actual HEVM peer behavior remains an explicit integration gap.
- Pitfalls: MEDIUM — directly derived from source/configuration and the locked Phase 2 RED-to-GREEN transition.

**Research date:** 2026-09-08  
**Valid until:** 2026-10-08 for stable pins; reconfirm bridge SHA before execution.
