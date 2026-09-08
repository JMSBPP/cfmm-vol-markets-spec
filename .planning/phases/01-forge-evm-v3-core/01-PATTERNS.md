# Phase 1: Forge `evm/` + v3-core - Pattern Map

**Mapped:** 2026-09-08  
**Files analyzed:** 9 files plus one Git submodule gitlink  
**Analogs found:** 8 / 10

Phase naming and stale v3 references are historical. Per D-01/D-02 in
`01-CONTEXT.md`, every Phase 1 artifact must use `Uniswap/v4-core@v4.0.0`
and its `getSqrtPriceAtTick` / `getTickAtSqrtPrice` API. No Seaport,
bridge, HEVM, `.diff.t.sol`, or Haskell files are in this map.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `evm/foundry.toml` | build config | build-time dependency resolution | `/home/jmsbpp/apps/vol-markets/foundry.toml` | role-match; target must be deliberately smaller |
| `evm/remappings.txt` | dependency config | build-time import resolution | `/home/jmsbpp/apps/vol-markets/remappings.txt` | role-match |
| `evm/foundry.lock` | dependency lock | resolved tag-to-revision transform | `/home/jmsbpp/apps/vol-markets/foundry.lock` | exact |
| `.gitmodules` | dependency manifest | Git submodule resolution | greenfield in this repository; Forge-generated metadata | no local analog |
| `evm/lib/v4-core` (gitlink) | vendored external dependency | source dependency input | `/home/jmsbpp/apps/vol-markets/lib/cfmm-types/lib/v4-hooks-public/lib/v4-core` | external/dependency analog |
| `evm/src/TickMathHarness.sol` | Solidity harness contract | pure request-response / delegation | `.../v4-core/src/test/TickMathTest.sol` | exact external analog |
| `evm/README.md` | integration documentation | operator/build guidance | `README.md` | role-match |
| `.gitignore` | repository config | generated-artifact exclusion | `/home/jmsbpp/apps/vol-markets/.gitignore` | role-match |
| `.planning/ROADMAP.md` | planning documentation | traceability update | existing Phase 1 section in the same file | exact |
| `.planning/REQUIREMENTS.md` | requirements documentation | traceability update | existing EVM-01/EVM-02 wording in the same file | exact |

`forge init --empty --use-parent-git evm` creates the `evm/src/` and
`evm/test/` directories, but they are directories rather than separately planned
files. Phase 1 does not require a Solidity test file: compilation of the harness
is the smoke assertion.

## Pattern Assignments

### `evm/foundry.toml` (build config, build-time dependency resolution)

**Analog:** `/home/jmsbpp/apps/vol-markets/foundry.toml`

Use the normal Foundry profile keys and explicit `libs` list, but do not inherit
the analog's `ffi`, `via_ir`, optimizer, compiler profiles, compilation
restrictions, filesystem permissions, RPC endpoints, or fuzz settings. Those
serve vol-markets integration work that this scaffold explicitly defers.

**Config shape** (lines 1-6):
```toml
[profile.default]
src = "src"
out = "out"
script = "foundry-scripts"
test = "test"
libs = ["lib", "node_modules"]
```

**Remapping style** (lines 43-52):
```toml
remappings = [
	   "@cryptoalgebra/volatility-oracle-plugin/=node_modules/@cryptoalgebra/volatility-oracle-plugin/contracts",
	   "@cryptoalgebra/integral-core/=node_modules/@cryptoalgebra/integral-core/contracts",
]
```

**Phase-specific configuration:** use the researched minimal profile:
```toml
[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["lib"]
solc_version = "0.8.28"
remappings = ["v4-core/=lib/v4-core/"]
```

This is intentional scope control: v4-core is `pragma ^0.8.0`, so no v3-era
0.7.6 profiles or restrictions are appropriate.

---

### `evm/remappings.txt` (dependency config, build-time import resolution)

**Analog:** `/home/jmsbpp/apps/vol-markets/remappings.txt`

The analog tracks one alias per line and maps the alias directly to the
dependency source root:

```text
univ4-core/=lib/panoptic-v2-core/lib/v4-core/src/
v4-core/=lib/panoptic-v2-core/lib/v4-core/src/
@uniswap/v4-core/=lib/panoptic-v2-core/lib/v4-core/
```

For this direct `forge install` dependency, retain the generated record for:

```text
v4-core/=lib/v4-core/
```

The lock and generated remappings are source-controlled reproducibility inputs;
do not substitute a floating GitHub URL or a hand-maintained SHA-only note.

---

### `evm/foundry.lock` (dependency lock, resolved tag-to-revision transform)

**Analog:** `/home/jmsbpp/apps/vol-markets/foundry.lock`

The established Forge lock format records a library path, a ref kind, ref name,
and immutable revision:

```json
"lib/bunni-v2": {
  "tag": {
    "name": "v1.2.1",
    "rev": "000f79a38bdd3fb2b314dc8c108b2a3d1ca1d440"
  }
}
```

Expected generated equivalent (shown only as the target shape; Forge must
generate the file) is a `lib/v4-core` tag entry for `v4.0.0`, resolving to
`e50237c43811bd9b526eff40f26772152a42daba`. Do not manually author or edit the
lock file.

---

### `.gitmodules` and `evm/lib/v4-core` gitlink (dependency manifest/input, Git submodule resolution)

**Analog:** no existing `.gitmodules` is present in this repository. The useful
external analog is vol-markets' checked-in v4-core dependency tree:
`/home/jmsbpp/apps/vol-markets/lib/cfmm-types/lib/v4-hooks-public/lib/v4-core`.

The Phase 1 submodule must be generated by:

```bash
forge install --root evm v4-core=Uniswap/v4-core@tag=v4.0.0
```

Treat `.gitmodules`, the `evm/lib/v4-core` gitlink, and `evm/foundry.lock` as
one atomic pin. The source side is the official v4 `TickMath` library, which
declares its API and validation boundary as:

```solidity
library TickMath {
    using CustomRevert for bytes4;

    error InvalidTick(int24 tick);
    error InvalidSqrtPrice(uint160 sqrtPriceX96);
}
```

from `.../v4-core/src/libraries/TickMath.sol` lines 10-16. This library is an
external oracle: do not copy or modify its arithmetic in the local harness.

---

### `evm/src/TickMathHarness.sol` (Solidity harness contract, pure request-response/delegation)

**Analog:** `/home/jmsbpp/apps/vol-markets/lib/cfmm-types/lib/v4-hooks-public/lib/v4-core/src/test/TickMathTest.sol`

This is the closest direct shape: an external pure function delegates to
`TickMath`'s internal library function, demonstrating both import resolution and
linkage.

**Imports and forward wrapper** (lines 1-9):
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {TickMath} from "../libraries/TickMath.sol";

contract TickMathTest {
    function getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }
}
```

**Inverse wrapper follows the same delegation rule** (lines 15-18):
```solidity
function getTickAtSqrtPrice(uint160 sqrtPriceX96) external pure returns (int24) {
    return TickMath.getTickAtSqrtPrice(sqrtPriceX96);
}
```

For Phase 1, adapt only the import:

```solidity
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
```

Expose `getSqrtPriceAtTick` at minimum; exposing the inverse is consistent with
the same wrapper pattern but is not needed to introduce test/differential
behavior. Do not add `Test`, `PlankTestBase`, FFI, try/catch wrappers, or error
translation: the dependency's native custom errors must remain observable.

**Secondary import-style analog:** `/home/jmsbpp/apps/vol-markets/test/types/LiquidityDensity.t.sol`
lines 3-7 demonstrates named Solidity imports and a v4 TickMath import:

```solidity
import {PlankTestBase} from "../PlankTestBase.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {FixedPoint96} from "@uniswap/v4-core/src/libraries/FixedPoint96.sol";
```

It is import-style evidence only; it is not a Phase 1 behavioral analog because
it is a Plank integration test.

---

### `evm/README.md` (integration documentation, operator/build guidance)

**Analog:** `README.md`

The repository's documentation is plain Markdown, with a title followed by a
direct definition rather than generated-tool boilerplate:

```markdown
# PRICE_GRID

Fee-deformed sqrt-price quotes; the chunk bounds are identified with them:
```

The new README should remain concise and state: (1) Phase 1 is a Foundry
scaffold/import smoke only; (2) the exact dependency is
`Uniswap/v4-core@v4.0.0` at `e50237c43811bd9b526eff40f26772152a42daba`; (3)
`v4-core/` is the import alias; and (4) the build command is
`forge build --root evm`. It must not document Phase 2+ Seaport/bridge commands
as if installed.

---

### `.gitignore` (repository config, generated-artifact exclusion)

**Analog:** `/home/jmsbpp/apps/vol-markets/.gitignore`

**Foundry build-artifact convention** (lines 1-7):
```gitignore
# Compiler files
cache/
out/

# Ignores development broadcast logs
!/broadcast
/broadcast/*/31337/
/broadcast/**/dry-run/
```

Apply the convention narrowly to the nested project by appending:

```gitignore
evm/cache/
evm/out/
evm/broadcast/
```

Do not ignore `evm/lib/`: unlike vol-markets' explicitly untracked
non-submodule library paths (lines 31-36), `evm/lib/v4-core` is the required
tracked Git submodule.

---

### `.planning/ROADMAP.md` (planning documentation, traceability update)

**Analog:** the existing Phase 1 block in `.planning/ROADMAP.md` lines 20-33.

Update the existing phase title, goal, import criterion, and checklist wording
as a coordinated replacement. The current content exposes the exact stale
phrases to replace:

```markdown
### Phase 1: Forge `evm/` + v3-core
**Goal:** `evm/` Foundry project builds and imports Uniswap TickMath from `v3-core@0.8`
...
  2. TickMath (or wrapper) is importable from the installed `v3-core@0.8` remapping
...
- [ ] 01-02: `forge install v3-core@0.8` + remappings
```

Replace them with the locked v4 target and `v4-core` alias. Preserve Phases
2-8, including their deferred Seaport/bridge work; Phase 1's planned files
must not absorb them.

---

### `.planning/REQUIREMENTS.md` (requirements documentation, traceability update)

**Analog:** the existing EVM-01/EVM-02 block in `.planning/REQUIREMENTS.md`
lines 8-19.

The source's structure is a process list followed by scoped checkbox
requirements:

```markdown
## Process (TDD)

1. Stand up **`evm/`** as a Foundry project inside this repo.
2. **`forge install` Uniswap `v3-core@0.8`** (exact install string as used in execute).
...
### Forge `evm/` scaffold
- [ ] **EVM-01**: `evm/` is a working Foundry project (`foundry.toml`, `src/`, `test/`, remappings) under this repo root
- [ ] **EVM-02**: Uniswap **`v3-core@0.8`** is installed as a forge dependency and TickMath is importable
```

Update Phase 1's install and EVM-02 wording to the authoritative v4 pin. Later
requirements may retain historical v3 references only if explicitly marked
superseded; otherwise they risk directing implementation back to the wrong API.
Do not alter EVM-03, BRIDGE-*, TICK-*, or SQRT-* scope in this phase.

## Shared Patterns

### Dependency reproducibility

**Apply to:** `evm/foundry.toml`, `evm/remappings.txt`, `evm/foundry.lock`,
`.gitmodules`, and `evm/lib/v4-core`.

The configuration alias, Git submodule, and generated lock are one dependency
boundary. Pin with `@tag=v4.0.0`, verify the resolved SHA, and commit all
generated metadata. `forge build --root evm` should consume the local
`v4-core/` alias, never a remote source at build time.

### Solidity import and delegation

**Apply to:** `evm/src/TickMathHarness.sol`.

Use SPDX header, Solidity 0.8 pragma, named import, and pure external wrapper.
The wrapper must call the internal library directly:

```solidity
function getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
    return TickMath.getSqrtPriceAtTick(tick);
}
```

This is a compile/linkage seam, not a reimplementation, a test corpus, or a
differential framework.

### Generated artifacts versus tracked inputs

**Apply to:** `.gitignore` and all `evm/` dependency artifacts.

Ignore compiler/cache/broadcast outputs only. Track the submodule gitlink,
`.gitmodules`, `foundry.lock`, and remappings. This distinction is required for
both a clean worktree and reproducible source resolution.

### No auth, request validation, or application error wrapper

This local build scaffold has no user-facing call path. There are no
authentication, controller, database, logging, or validation patterns to copy.
TickMath's custom errors are part of the imported dependency behavior and
should not be caught or converted by the harness.

## No Analog Found

| File | Role | Data Flow | Reason / planner instruction |
|---|---|---|---|
| `.gitmodules` | dependency manifest | Git submodule resolution | No `.gitmodules` exists in this repository. Generate through Forge install; do not hand-author. |
| `evm/lib/v4-core` gitlink | vendored external dependency | source dependency input | The target direct submodule is greenfield here. Use the official `Uniswap/v4-core@v4.0.0` release, not an existing nested vol-markets copy. |

## Metadata

**Analog search scope:** scratchpad root configuration and planning docs; vol-markets
Foundry configuration, remappings, lock file, ignore rules, Solidity imports,
and vendored Uniswap v4 source.  
**Files scanned:** 10  
**Pattern extraction date:** 2026-09-08

## PATTERNS COMPLETE
