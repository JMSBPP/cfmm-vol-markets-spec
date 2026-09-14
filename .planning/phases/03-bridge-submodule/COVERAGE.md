# Phase 3 Bridge API Coverage

**Scope:** Pinned `JMSBPP/evm-spec-bridge` consumer surface needed to make one `getSqrtPriceAtTick` vector live through `hevm.call`.

## Capability Matrix

| External capability | Decision | Phase 3 coverage | Reason |
|---------------------|----------|------------------|--------|
| `hevm.call(method, paramsJson)` | INTEGRATE | Import pinned `Hevm.sol`; exercise transport probe and TickMath harness | Locked BRIDGE-01 and D-02 surface. |
| Bridge `Vm.ffi` delegation | INTEGRATE | Use transitively through `hevm.call`; FFI enabled only in `profile.hevm` | Avoids a local cheat wrapper and confines host execution. |
| `relay send <method> <params-json>` CLI | INTEGRATE | Transport smoke, readiness probe, and Solidity FFI path | This is the bridge-owned synchronous request client. |
| `relayd` control/data AF_UNIX transport | INTEGRATE | Bounded startup, private socket, readiness, cleanup | Required for a real call and owned by the bridge. |
| Raw JSON `result` bytes on stdout | INTEGRATE | Probe asserts `[1]`; harness strictly parses a decimal `uint160` | `hevm.call` does not return ABI-encoded returndata. |
| JSON-RPC request IDs and peer responses | INTEGRATE | Local peer preserves IDs and emits result/error envelopes | Required to interoperate with relayd without replacing it. |
| Bridge FFI error propagation | INTEGRATE | Configured transport failures remain `hevm.call: ffi failed` | Supports cause-specific diagnosis and BRIDGE-03 ownership. |
| `FOUNDRY_PROFILE=hevm` | INTEGRATE | Trusted profile enables FFI; harness checks selected profile | Locked D-03 and BRIDGE-02 readiness contract. |
| `RELAY_SOCK` | INTEGRATE | Required harness/runner/peer environment contract | Prevents silent or ambiguous relay-down behavior. |
| Method `getSqrtPriceAtTick` with `[int24]` params | INTEGRATE | Sole local peer method and sole live differential vector | Locked D-04 and D-08 scope. |
| Hackage `hevm-0.58.0` `module EVM` | INTEGRATE | Private adapter executes compiled TickMath runtime bytecode | Locked D-05/D-06; produces canonical minimum-tick result without changing SqrtGrid. |
| Bridge `fake-hevm-echo` | OPT-OUT | Allowed only in transport-contract smoke; excluded from TickMath acceptance and CI GREEN | It proves relay mechanics but cannot prove the local adapter or exact oracle. |
| Generic arbitrary-method peer | OPT-OUT | Reject every method except `getSqrtPriceAtTick` | D-08 deliberately limits the Phase 3 API and reduces evaluator exposure. |
| Full TickMath method/vector corpus | OPT-OUT | No additional methods or vectors | Deferred to Phase 4+ by CONTEXT.md. |
| Local replacement for `relay`, `relayd`, or `Vm` | OPT-OUT | Consume pinned bridge implementations | REQUIREMENTS forbids reinventing the cheat/relay surface. |
| Consumer-side edits to bridge source | OPT-OUT | Bridge defect triggers issue + user notification | BRIDGE-03 preserves submodule ownership. |
| Direct current `SqrtGrid.sqrtPriceX96` result as Side B | OPT-OUT | Use HEVM-executed canonical runtime for this tracer | Current min-tick output is `4295128738`, not canonical `4295128739`; algorithm rewrite is deferred. |
| Full bit-identical SqrtGrid/FullMath implementation | OPT-OUT | No numerical algorithm changes | Deferred to Phases 6–7. |

## Coverage Gate

Phase 3 bridge coverage is complete when:

1. The exact bridge gitlink, lock entry, and remapping agree.
2. The consumer transport probe validates raw JSON bytes through relayd.
3. The local peer accepts only `getSqrtPriceAtTick([int24])`.
4. The matched minimum-tick differential is GREEN with the real EVM-backed peer.
5. Profile/socket absence and configured FFI failure remain distinct and loud.
6. Documentation and CI enforce BRIDGE-02/03.

No in-scope bridge capability is left undecided.
