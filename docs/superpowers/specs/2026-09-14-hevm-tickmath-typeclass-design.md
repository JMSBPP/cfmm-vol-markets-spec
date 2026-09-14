# HEVM TickMath adapter as a typeclass; runtime owns lookup

**Date:** 2026-09-14  
**Status:** design; approved in chat (class vs instance, error split, test surface)  
**Follows:** `HevmSqrtGrid` / `HevmExec` split (session is `SolcContract`, not a file path)

## 1. Problem

`HevmSqrtGrid.getSqrtPriceAtTick` still reads like glue: it searches the ABI map, throws if the method is missing, then encodes, executes, and decodes. Adapters are supposed to feel like writing the Solidity surface. Artifact load, method lookup, ABI encode/decode, and “method not found” belong in the runtime.

## 2. Goal

A Haskell TickMath adapter is only the typed contract interface. The HEVM instance performs the call. Callers bind a loaded Foundry artifact once and run `getSqrtPriceAtTick tick` inside that session.

## 3. Architecture

### 3.1 Class (adapter)

`HevmSqrtGrid` exports the class and nothing that mentions `SolcContract`, ABI maps, or session errors:

```haskell
class TickMath m where
  getSqrtPriceAtTick :: Tick -> m SqrtPriceX96
```

One method this slice. Name and argument match `TickMathHarness.getSqrtPriceAtTick(int24)`. `m` is the session/runtime; the class does not take the contract as an extra argument.

The class stays on the HEVM adapter library. It does not move onto the public `cfmm-vol-markets-spec` library (that would infect `Spec.hs` / chunks / payoffs).

### 3.2 Instance (runtime)

A `Hevm` newtype (next to `HevmExec`) is the `TickMath` instance. It is `ExceptT EvmError` over `ReaderT SolcContract IO`: the session is in the reader; EVM revert is `ExceptT` (`Left` at `runHevm`); session `ioError` is thrown in the underlying `IO`. A runtime `call` combinator owns:

- lookup of the Solidity method by name
- ABI encode of the tick as `int24`
- `execRuntime` of the contract’s runtime bytecode
- ABI decode of success bytes as `uint160` wrapped in `SqrtPriceX96`

Edge:

```haskell
runHevm :: SolcContract -> Hevm a -> IO (Either EvmError a)
```

Peer and tests load Foundry JSON once (existing `readJSON Foundry` path, `ast = true`) and call `runHevm session (getSqrtPriceAtTick tick)`.

`HevmExec.execRuntime` stays the bytecode runner. It does not grow ABI lookup.

## 4. Errors

Two kinds. Do not collapse them.

| Event | Observed at | Shape |
|---|---|---|
| TickMath revert (Uniswap-illegal tick; bytecode is the spec) | `runHevm` | `Left EvmError` |
| Success `uint160` | `runHevm` | `Right (SqrtPriceX96 …)` |
| Missing method, broken success-ABI, non-concrete output | process | `ioError` — broken session, not a TickMath outcome |

`getSqrtPriceAtTick` on the class never mentions session failures. `Hevm` must not turn an EVM revert into a Haskell exception; revert stays `Left` at `runHevm`.

JSON-RPC `int24` width stays on the peer. Uniswap tick bounds stay in bytecode. No Haskell `MIN_TICK` / `MAX_TICK`. No custom `HevmSqrtGridError`.

## 5. Testing

Existing public behaviors, rewritten only as far as the new edge (`runHevm session (getSqrtPriceAtTick tick)`):

1. Min tick `-887272` → `Right (SqrtPriceX96 4295128739)`.
2. Tick `887273` (int24-legal, Uniswap-illegal) → `Left` some `EvmError`, not a price, not `ioError`.

Do not add tests of lookup internals (missing method-name string, `abiMap` `find`). A later session-broken case, if any, is observed at `runHevm` on a `SolcContract` with no TickMath ABI — not a unit test of the finder.

Peer probe/dispatch unchanged in product behavior: one artifact at startup; JSON-RPC `-32000` on `Left EvmError`.

## 6. Out of scope

- Pure `SqrtGrid` / `Identity` `TickMath` instance (public library stays HEVM-free; integer `sqrtPriceX96` port is separate).
- `getTickAtSqrtPrice` on the class.
- ABI/TH codegen of adapters from the artifact.
- Putting `hevm` on the public library.
- Switching the peer onto `Bridge.Relay.Wire`.
- FilePath / JSON / hex decode inside the adapter class.
- Custom error type for missing methods.

## 7. Next

Repo pipeline: `/to-prd` (GitHub PRD issue) → `/to-issues` (ordered vertical slices) → `/tdd` (one failing public test, then minimum code).
