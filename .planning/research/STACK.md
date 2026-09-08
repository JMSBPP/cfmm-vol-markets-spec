# Stack Research

**Domain:** In-process EVM oracle for a Stack/Cabal Haskell CFMM twin, beginning with Uniswap V3-style Q64.96 tick and full-precision arithmetic  
**Researched:** 2026-09-08  
**Confidence:** MEDIUM — the dependency and API evidence is strong; `hevm-0.58.0` was released/tested on GHC 9.6.5, not this project's GHC 9.10.3, so its resolver/build result must be established by a short integration spike before it becomes a CI requirement.

## Recommendation

Use **`hevm-0.58.0` as a test-only, in-process concrete EVM oracle**, wired through the `EVM` library module. Keep the production `src/` library free of HEVM, bytecode, compiler processes, and solver dependencies. Compile a tiny Solidity adapter around the canonical Uniswap V3 `TickMath` and `FullMath`, check its runtime bytecode and ABI selectors into the test fixture, then execute that bytecode in a concrete HEVM `VM` for fixed vectors and bounded property vectors.

This is the right boundary for this milestone: Haskell remains the fast implementation under test; EVM bytecode defines the oracle; HEVM supplies actual EVM word width, unsigned arithmetic, reverts, shifts, and return-data semantics in the same process. It does **not** prove Solidity source equivalence by itself. The fixture's compiler version, source revision, creation/runtime bytecode, and test vectors must be pinned.

The phrase “standard Stack setup” needs qualification. HEVM's own supported development environment is Nix, and 0.58.0 explicitly moved to GHC 9.6.5. There is no published, GHC-9.10-tested Stack integration recipe. The conservative 2025–2026 Stack pattern is therefore a pinned Hackage dependency in a test component, resolved in the project's snapshot and lockfile, with a source-pinned fallback only if the Hackage package cannot compile on LTS 24.55.

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|---|---:|---|---|
| Stack | 3.11.x; LTS 24.55 | Resolve/build the existing GHC 9.10.3 project | Preserves the current project build and makes HEVM an explicitly locked test dependency rather than a separate runtime. |
| GHC | 9.10.3 | Haskell compiler supplied by LTS 24.55 | Required by the brownfield project. Do not silently downgrade the whole twin to make an oracle compile. |
| `hevm` | **0.58.0** | In-process concrete EVM evaluator (`EVM`, `EVM.Concrete`, `EVM.Exec`, `EVM.Types`) | The package exposes the evaluator as a Haskell library; core semantics are pure and concrete execution gives the required EVM behavior without JSON-RPC or a subprocess. Pin exactly 0.58.0 for fixture stability. |
| Uniswap V3 core reference | commit **f03155670ec1667406b83a539e23dcccf32a03bc** | Canonical `TickMath`/`FullMath` algorithm source | `TickMath.getSqrtRatioAtTick` specifies the Q128.128 square-and-multiply path and final round-up to Q64.96; `FullMath.mulDiv` specifies 512-bit intermediate division and its revert conditions. |
| Solidity fixture compiler | solc **0.7.6** (or Foundry configured to exactly use it) | Compile a minimal test-only wrapper once | Matches the Uniswap V3 core compiler line. Check generated runtime bytecode, source hash, compiler version, and selectors into the repository; do not compile during each Haskell test. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---|---:|---|---|
| `bytestring` | snapshot version | Runtime bytecode, calldata, return-data | Required by HEVM's concrete code representation and by a small fixture encoder/decoder. |
| `binary` | snapshot version | Explicit 32-byte ABI word encoding/decoding | Use only if a small local ABI codec is preferable to hand-written fixed-width byte conversions. For these three pure functions, a local 32-byte codec is less risky than adding a general ABI framework. |
| `QuickCheck` | >=2.13.2 and snapshot-compatible | Bounded randomized differential vectors | Add after deterministic boundary/golden vectors pass. Generate only valid and deliberately-invalid domains, then assert both returned words and revert classification. |
| `tasty` / `tasty-hunit` | snapshot-compatible | Isolated oracle test-suite reporting | Optional. The current monolithic HUnit-style `Spec.hs` can host the first vectors; introduce a dedicated `hevm-oracle` suite when compile time or failures need isolation. |

## Installation

Add HEVM only to a test component in `package.yaml`; do not add it to package-level `dependencies` or the public library. Regenerate the `.cabal` file with hpack.

```yaml
# package.yaml
tests:
  cfmm-vol-markets-spec-hevm:
    main: HevmOracleSpec.hs
    source-dirs: test
    dependencies:
    - cfmm-vol-markets-spec
    - hevm == 0.58.0
    - bytestring
    - QuickCheck
```

```yaml
# stack.yaml
extra-deps:
- hevm-0.58.0
```

```bash
hpack
stack build --test --pedantic
stack test cfmm-vol-markets-spec:cfmm-vol-markets-spec-hevm
```

First run this as an explicit compatibility spike. Keep `hevm-0.58.0` in `extra-deps` only after Stack resolves it against LTS 24.55; commit the resulting `stack.yaml.lock`. If Stack reports a missing non-snapshot dependency, add the exact version suggested by the resolver and re-lock—never use floating Git `main`, blanket `allow-newer`, or a global Cabal package database to make CI pass.

HEVM 0.58.0 links native libraries `secp256k1`, `ff`, and `gmp`, and builds bundled C/C++ sources. CI must install the matching development toolchain/libraries or use a reproducible Nix-provided system dependency layer. The SqrtGrid fixture itself is pure and does not call precompiles, but the HEVM library still links those dependencies.

## Oracle Fixture Pattern

1. Add a `test/solidity/UniswapMathOracle.sol` wrapper with external pure functions for:
   - `sqrtRatioAtTick(int24) returns (uint160)`;
   - `tickAtSqrtRatio(uint160) returns (int24)`;
   - `mulDiv(uint256,uint256,uint256) returns (uint256)`.
2. Vendor only the required reference source at the stated Uniswap commit, retain license headers, and compile with solc 0.7.6. Commit the runtime bytecode and a metadata file containing compiler version, optimizer settings, source commit, bytecode keccak, and selectors.
3. Build a narrow `test/HevmOracle.hs` façade. It owns VM construction, pure-contract deployment/loading, ABI words, calldata, execution-to-halt, and conversion of success/revert/invalid outcomes to a project-local result type. Production modules must not import `EVM.*`.
4. Test exact words, not numerical tolerances. Include `MIN_TICK`, `-1`, `0`, `1`, `MAX_TICK`; `MIN_SQRT_RATIO`, exact tick ratios, and `MAX_SQRT_RATIO - 1`; plus `FullMath` normal, 512-bit-product, denominator-zero, and result-overflow cases.
5. Port `sqrtPriceX96` using the reference integer algorithm, including TickMath's final **round up**, and port `tickFromSqrtPriceX96` using TickMath's greatest-valid-tick rule and its half-open maximum bound. Haskell's current `Double`/`floor`/`round` code cannot pass this oracle.
6. Mirror Solidity preconditions deliberately. `Integer` multiplication itself never overflows, whereas `FullMath.mulDiv` reverts if denominator is zero or its uint256 result would overflow. Validate arguments/results to uint256 and report matching failures before comparing values.

For this SqrtGrid wedge, HEVM should run only bytecode with no RPC, filesystem, cheatcode, SMT, or external calls. That makes each oracle call deterministic and fully in-process; HEVM architecture documents that the core `EVM` semantics are pure, with queries only when outside information is required.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|---|---|---|
| HEVM concrete evaluator embedded as a test dependency | Foundry/`forge test` subprocess or FFI | Use as an independent integration check or for Solidity compilation. It is not an in-process Haskell oracle and makes tests depend on an installed executable/process boundary. |
| HEVM 0.58.0 from Hackage | HEVM source-repository package pinned to the `v0.58.0` tag/commit | Use only if Hackage 0.58.0 fails to resolve/build on LTS 24.55 and a documented source patch is necessary. Pin commit and Cabal revision; do not track `main`. |
| Concrete execution | HEVM symbolic execution / SMT | Use symbolic mode later to search for counterexamples after the concrete fixture is stable. It adds Z3/query and path-explosion concerns but does not replace fixed golden parity vectors. |
| Tiny local ABI façade | Generic Web3/Ethereum ABI client | Use a client only when the target calls deployed contracts or needs RPC. Three fixed static pure calls do not justify networking, provider state, or wider ABI surface. |
| Reference bytecode plus exact differential tests | Hand-port arithmetic with only Haskell unit tests | Never as the evidence for bit-identity: it misses EVM reverts, conversion widths, unsigned shifts, and TickMath's final upward rounding. |

## What NOT to Use

| Avoid | Why | Use Instead |
|---|---|---|
| `dapphub/hevm` | Archived old repository; it is not the maintained HEVM project. | Hackage `hevm-0.58.0` / `argotorg/hevm`. |
| `hevm` CLI subprocess as the unit-test oracle | Violates the in-process requirement, complicates bytecode/calldata transport, and weakens deterministic test isolation. | Import `EVM.*` in the test-only façade. |
| `Double`, `Float`, `log`, `**`, `floor`, or `round` for tick↔sqrtPrice | They cannot reproduce the reference Q128.128 intermediate, TickMath upward rounding, or inverse half-open bounds. | Integer port of TickMath, checked against HEVM. |
| `Integer` `mulDiv` without uint256/revert guards | Gives the correct floor only inside the valid domain; it cannot represent EVM overflow/revert behavior by itself. | Checked Haskell wrapper plus HEVM cases for success and failures. |
| `allow-newer`, unpinned Git dependencies, or an uncommitted system package DB | Hides the 9.10 compatibility problem and destroys reproducibility. | Exact Hackage version, resolver-selected closure, and `stack.yaml.lock`. |
| HEVM in public package dependencies | Pulls a large native/AGPL EVM stack into downstream users and violates the existing plot-free/lightweight library boundary. | Dedicated test suite or private internal test component. |
| Assuming HEVM's AGPL-3.0-only license is irrelevant | In-process linkage/distribution can impose copyleft obligations. This is a release/legal decision, not a technical detail. | Obtain project legal approval before distributing artifacts that link it; otherwise keep HEVM strictly a CI/developer test tool or select a legally acceptable oracle. |

## Stack Patterns by Variant

**If `hevm-0.58.0` resolves and builds under LTS 24.55 / GHC 9.10.3:**
- Use the Hackage extra-dep and commit `stack.yaml.lock`.
- Keep HEVM in its own test suite and make that suite a required CI job.

**If 0.58.0 has a narrow GHC-9.10 compilation failure:**
- First determine whether an upstream 0.58.x patch release fixes it; otherwise use a source-repository package pinned to a reviewed patch commit and record the patch rationale.
- Do not change the project compiler, relax version bounds globally, or rewrite SqrtGrid around a different emulator to avoid the failure.

**If native HEVM dependencies make the default CI image unsuitable:**
- Build the HEVM test job in a Nix shell/container whose system libraries are pinned, while retaining Stack for the Haskell package itself.
- The existing non-HEVM `stack test` remains a separate fast job.

**If the licensing review rejects HEVM linkage:**
- Preserve the same checked bytecode and vector corpus, run it with Foundry in a separate CI oracle job, and state explicitly that this no longer meets the in-process requirement.
- Do not claim the subprocess setup is equivalent to an embedded HEVM oracle.

## Version Compatibility

| Package A | Compatible With | Notes |
|---|---|---|
| `cfmm-vol-markets-spec` / LTS 24.55 | GHC 9.10.3 | Existing project baseline. |
| `hevm-0.58.0` | `base >= 4.9 && < 5` | Its Cabal bounds admit GHC 9.10's `base-4.20`, but that is a solver constraint, not proof of support. |
| `hevm-0.58.0` | GHC 9.6.5 | Explicitly updated/tested compiler in the 0.58.0 changelog; highest verified upstream compiler evidence found. |
| `hevm-0.58.0` | GHC 9.10.3 | **Unverified; medium/low confidence.** Run the dedicated Stack resolver/build spike before implementation/CI commitment. |
| `hevm-0.58.0` | `aeson < 2.3`, `bytestring < 0.13`, `vector < 0.14`, `time < 1.15`, `containers < 0.8` | LTS 24.55 must be checked against all bounds by Stack. Do not force them with `allow-newer`. |
| Uniswap V3 core `f031556…` | solc 0.7.6 | Canonical compilation era for V3 core. The oracle wrapper should preserve its source/optimizer metadata in the fixture. |
| `TickMath` | `FullMath` | Complementary rather than interchangeable: TickMath uses its own Q128.128 bit-decomposition and round-up; FullMath supplies generic 512-bit `floor(a*b/d)` semantics. |

## Sources

- [HEVM architecture](https://hevm.dev/architecture.html) — `VM`/`exec1` core semantics, concrete/symbolic interpreter structure, and pure-core/query boundary. **High confidence.**
- [Hackage: hevm-0.58.0](https://hackage.haskell.org/package/hevm-0.58.0) and inspected `hevm.cabal` — exposed `EVM.*` modules, AGPL-3.0-only license, native libraries, and dependency bounds. **High confidence.**
- [HEVM 0.58.0 changelog](https://hackage.haskell.org/package/hevm-0.58.0/changelog) — explicit GHC 9.6.5 update; no GHC 9.10 validation found. **High confidence.**
- [Uniswap V3 TickMath](https://github.com/Uniswap/v3-core/blob/f03155670ec1667406b83a539e23dcccf32a03bc/contracts/libraries/TickMath.sol) — tick bounds, Q64.96 constants, Q128.128 computation, round-up, inverse domain. **High confidence.**
- [Uniswap V3 FullMath](https://github.com/Uniswap/v3-core/blob/412d9b236a1e75a98568d49b1aeb21e3a1430544/contracts/libraries/FullMath.sol) — full-precision `mulDiv` and revert behavior. **High confidence.**
- Project sources: `.planning/PROJECT.md`, `.planning/codebase/STACK.md`, `package.yaml`, `stack.yaml`, `docs/BITWIDTHS.md`, and `src/SqrtGrid.hs` — scope, current constraints, and known non-identical paths. **High confidence.**

---
*Stack research for: in-process HEVM oracle and bit-identical Uniswap V3 fixed-point math*
*Researched: 2026-09-08*
