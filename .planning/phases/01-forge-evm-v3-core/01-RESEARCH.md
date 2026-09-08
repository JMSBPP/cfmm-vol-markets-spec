# Phase 1: Forge `evm/` + v3-core - Research

**Researched:** 2026-09-08  
**Domain:** Nested Foundry project scaffold and pinned Uniswap v4 TickMath dependency  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
### TickMath oracle source (was `v3-core@0.8`)
- **D-01:** Use **Uniswap v4 `TickMath`**, not v3-core — **Reversibility:** costly — remappings, install string, and later diff suites bind to v4 API names (`getSqrtPriceAtTick` / `getTickAtSqrtPrice`); switching back to v3 renames every oracle call site.
- **D-02:** Pin **`Uniswap/v4-core@v4.0.0`** via forge install (tag SHA tip at discuss time: `e50237c…` on `v4.0.0`) — **Reversibility:** costly — bit-identity work should stay on a fixed release; floating `main` rejected.
- **D-03:** Interpret historical process phrase `forge install v3-core@0.8` as **solc 0.8 Forge project + official Uniswap TickMath lib** — resolved to v4-core because v4 is `pragma ^0.8.0` and matches the `@0.8` intent; Uniswap/v3-core has no `@0.8` tag.

### Solc / Foundry
- **D-04:** Default `evm/` profile targets **solc 0.8.x** (compatible with v4 `^0.8.0`).
- **D-05:** **No** 0.7.6 `additional_compiler_profiles` / `compilation_restrictions` for the TickMath lib (those were only needed for v3). Dropped after the v4 switch.

### Scope discipline (user confirmed)
- **D-06:** Finish Phase 1 as **scaffold-only**. The Seaport-pattern diff that uses Uniswap TickMath tests as client and compares against **EVM-adapted `SqrtGrid`** is **not** this phase — discuss/plan that in Phase 2+ (base) and Phase 4+ (suite / SqrtGrid side).

### the agent's Discretion
- Exact `foundry.toml` solc patch version (e.g. 0.8.26 vs 0.8.28) within 0.8.x
- Remapping alias names (`v4-core/=…` vs `uniswap/v4-core/=…`) as long as TickMath imports clearly
- Whether smoke is a tiny wrapper contract vs a one-line test that only compiles an import
- Updating ROADMAP/REQUIREMENTS wording from `v3-core@0.8` → `v4-core@v4.0.0` as a docs chore in plan/execute (decision is locked here)

### Deferred Ideas (OUT OF SCOPE)
- Seaport `DifferentialTest` / `DiffTestBase` + smoke `.diff.t.sol` → **Phase 2**
- `evm-spec-bridge` submodule + `hevm.call` + BRIDGE-03 → **Phase 3**
- TickMath.diff suite over Uniswap TickMath.t.sol corpus; non-vacuity / skip doctrine → **Phase 4**
- Second side via HEVM / EVM-adapted SqrtGrid bit-identity → **Phases 5–6**
- Solc profile depth / CI / gitignore gray areas (not selected in discuss) — planner defaults OK unless they block scaffold
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EVM-01 | `evm/` is a working Foundry project (`foundry.toml`, `src/`, `test/`, remappings) under this repo root. | Use `forge init --empty --use-parent-git evm`, a minimal pinned-compiler `evm/foundry.toml`, and a committed `evm/remappings.txt`. |
| EVM-02 | Uniswap `v3-core@0.8` is installed as a forge dependency and TickMath is importable. | CONTEXT D-01/D-02 supersede the stale wording: install `v4-core=Uniswap/v4-core@tag=v4.0.0`, retain its Git submodule plus lock file, and compile a local TickMath wrapper. |
</phase_requirements>

## Summary

Phase 1 is a small, self-contained nested Foundry project: initialize `evm/` without example contracts and attach it to the existing repository Git worktree, then install the locked Uniswap Git dependency under the explicit `v4-core` alias. [VERIFIED: local Forge 1.5.1 CLI] Forge documents Git submodules in `lib/`, automatic remappings, and `foundry.lock` as the resolved tag/revision record; both the dependency submodule and lock file are therefore part of the reproducible pin. [CITED: https://book.getfoundry.sh/projects/dependencies]

Use `solc_version = "0.8.28"` in `evm/foundry.toml`. This is the minimal Foundry configuration example in the official documentation, while the locked v4 source declares `pragma solidity ^0.8.0`; it satisfies D-04 without adding v3-era compiler profiles. [CITED: https://book.getfoundry.sh/config/overview] [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol]

**Primary recommendation:** Plan one scaffold/pin task and one verification/docs task: use the explicit alias `v4-core`, a compiling local wrapper, committed `evm/foundry.lock` and `evm/remappings.txt`, and correct the Phase 1 stale v3 wording in planning documents.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compile local Solidity sources against TickMath | Build/tooling | Git dependency storage | Foundry resolves the remapping and compiler; the pinned source is stored as a Git submodule. [CITED: https://book.getfoundry.sh/projects/dependencies] |
| Preserve an exact external oracle revision | Git dependency storage | Build/tooling | `.gitmodules` identifies the upstream and `foundry.lock` records tag plus resolved commit. [CITED: https://book.getfoundry.sh/projects/dependencies] |
| Demonstrate a usable TickMath import | Local Solidity source | Build/tooling | A wrapper imports the dependency and exposes calls to its internal library functions, so `forge build` checks the actual integration boundary. [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol] |

## Project Constraints (from AGENTS.md)

- The TODO-to-GitHub branch/issue/PR workflow applies only when working an open `TODO.md` item; this requested Phase research is not such an item. [VERIFIED: `AGENTS.md`]
- If the later `evm-spec-bridge` submodule fails, open an issue on its repository, notify the user with the issue URL and brief, and do not silently patch the bridge locally. That integration is deferred from this phase. [VERIFIED: `AGENTS.md`]
- Phase 1 must not create a Seaport differential, bridge integration, or Haskell/`SqrtGrid` change. [VERIFIED: `01-CONTEXT.md`]

## Standard Stack

### Core

| Library/tool | Version | Purpose | Why standard |
|--------------|---------|---------|--------------|
| Foundry / Forge | 1.5.1-stable installed | Initialize, resolve remappings, and build the nested Solidity project. | The target machine has this version and its CLI supports the required nested init and Git dependency commands. [VERIFIED: local `forge --version`, `forge init --help`, `forge install --help`] |
| Solidity compiler | 0.8.28 | Deterministic default compiler selected by `evm/foundry.toml`. | Official Foundry minimal configuration uses this version; v4 TickMath allows all compatible 0.8 releases. [CITED: https://book.getfoundry.sh/config/overview] [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol] |
| `Uniswap/v4-core` | `v4.0.0`, commit `e50237c43811bd9b526eff40f26772152a42daba` | Canonical TickMath source. | The official release tag resolves to this exact commit. [VERIFIED: `git ls-remote --tags https://github.com/Uniswap/v4-core.git v4.0.0`] |

### Supporting

| Item | Version | Purpose | When to use |
|------|---------|---------|-------------|
| `evm/remappings.txt` | generated from installed dependency | Stable explicit import alias for source, tests, and editor tooling. | Generate after the dependency is installed and commit it with the lock file. [CITED: https://book.getfoundry.sh/projects/dependencies] |
| `evm/foundry.lock` | generated by Forge | Records selected tag and resolved revision. | Commit it; do not hand-edit it. [CITED: https://book.getfoundry.sh/projects/dependencies] |

### Decisions Applied

- Install exactly `v4-core=Uniswap/v4-core@tag=v4.0.0`; the `@tag=` form asks Forge for an exact tag and the alias makes the installation directory `evm/lib/v4-core`. [VERIFIED: local `forge install --help`]
- Add `v4-core/=lib/v4-core/` to the generated/persisted remappings so local imports use `v4-core/src/libraries/TickMath.sol`. This alias is short, unambiguous, and matches the installed directory. [CITED: https://book.getfoundry.sh/projects/dependencies]
- Prefer `src/TickMathHarness.sol` over an import-only test. `TickMath` functions are `internal`; a tiny public wrapper makes import resolution and internal-library linkage a build-time invariant without adding a test framework dependency. [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol]

**Installation:**
```bash
forge init --empty --use-parent-git evm
forge install --root evm v4-core=Uniswap/v4-core@tag=v4.0.0
forge remappings --root evm > evm/remappings.txt
```

`forge install` in Forge 1.5.1 has an opt-in `--commit` flag and no `--no-commit` flag; do not pass `--commit`, so it does not create an unrelated automatic commit. Do not use `--no-git`, because it creates a plain directory and bypasses the lock-file mechanism needed for the pin. [VERIFIED: local `forge install --help`] [CITED: https://book.getfoundry.sh/projects/dependencies]

## Package Legitimacy Audit

This phase installs a GitHub Solidity dependency, not an npm/PyPI/crates package. The required package-legitimacy seam was run with the literal GitHub specifier and returned `SUS` only because npm registry metadata is inapplicable (`exists`, age, downloads, and repository all `null`); it is not evidence against the official GitHub repository. [VERIFIED: `gsd-tools query package-legitimacy check --ecosystem npm Uniswap/v4-core`]

| Dependency | Registry | Age/downloads | Source repo | Verdict | Disposition |
|------------|----------|---------------|-------------|---------|-------------|
| `Uniswap/v4-core@v4.0.0` | GitHub Git dependency; npm audit not applicable | Not applicable | `https://github.com/Uniswap/v4-core` | Official tag verified | Approved, pin exact tag and lock resolution. [VERIFIED: `git ls-remote`] |

**Packages removed due to [SLOP] verdict:** none.  
**Packages flagged as suspicious [SUS]:** none; the seam result is a registry-category mismatch, not a package assessment.

## Architecture Patterns

### System Architecture Diagram

```text
developer command
      |
      v
evm/foundry.toml (solc 0.8.28, lib root)
      |
      +--> evm/remappings.txt: v4-core/ -> lib/v4-core/
      |                                      |
      |                                      v
      |                             Git submodule at v4.0.0
      |                                      |
      v                                      v
src/TickMathHarness.sol  ----------------> TickMath.sol
      |
      v
forge build  ----failure----> repair config/import/pin
      |
      +----success----------> Phase 2 consumer boundary
```

### Recommended Project Structure

```text
evm/
├── foundry.toml              # pinned default compiler and lib root
├── foundry.lock              # generated tag -> resolved commit record
├── remappings.txt            # committed v4-core import alias
├── src/
│   └── TickMathHarness.sol   # import/linkage smoke wrapper only
├── test/                     # present from scaffold; no differential suite in Phase 1
└── lib/
    └── v4-core/              # Git submodule, tracked rather than ignored
```

### Pattern 1: Parent-Git nested Foundry project

**What:** Initialize `evm/` with `--empty --use-parent-git`, keeping the new project inside the existing repository rather than making another repository. [VERIFIED: local `forge init --help`]

**When to use:** Use for EVM-01 because `evm/` is expressly a subtree of this repository.

### Pattern 2: Alias + lock + wrapper smoke

**What:** Use one explicit dependency alias, commit its generated lock/remapping records, and compile a wrapper that imports and calls the library.

**When to use:** Use for EVM-02 and for future differential-suite imports; do not test the upstream corpus in this phase.

**Example:**
```solidity
// evm/src/TickMathHarness.sol
pragma solidity 0.8.28;

import {TickMath} from "v4-core/src/libraries/TickMath.sol";

contract TickMathHarness {
    function getSqrtPriceAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtPriceAtTick(tick);
    }
}
```

### Gitignore Policy

Keep `evm/lib/` tracked: Forge's default Git dependency mode uses a Git submodule, which must be committed together with `.gitmodules` and `evm/foundry.lock`. [CITED: https://book.getfoundry.sh/projects/dependencies] Add or retain these root-relative ignores (or equivalent `evm/.gitignore` entries): `evm/cache/`, `evm/out/`, and `evm/broadcast/`. The current root `.gitignore` contains none of these nested rules, and `git check-ignore` reports no existing match for them. [VERIFIED: local `.gitignore` and `git check-ignore`]

### Anti-Patterns to Avoid

- **Floating `main` dependency:** violates the locked reproducibility decision; use the release tag and commit the generated lock. [VERIFIED: `01-CONTEXT.md`]
- **`--no-git` install:** prevents Forge from adding the dependency to the lock-file mechanism. [CITED: https://book.getfoundry.sh/projects/dependencies]
- **v3 compiler profiles:** v4 TickMath has `pragma ^0.8.0`; profiles/restrictions for 0.7.6 contradict D-05. [VERIFIED: `01-CONTEXT.md`] [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol]
- **Premature differential infrastructure:** Seaport, bridge, HEVM, corpus reuse, and SqrtGrid are explicitly deferred. [VERIFIED: `01-CONTEXT.md`]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tick-to-price and inverse price-to-tick arithmetic | A local approximation or copied TickMath implementation | Pinned Uniswap v4 `TickMath` | The upstream library includes fixed-width assembly, rounding, bounds, and custom error behavior needed for later bit-identity work. [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol] |
| Dependency revision tracking | A hand-maintained SHA note alone | Forge Git submodule plus `foundry.lock` | Forge records tag and resolved revision and checks lock consistency during builds. [CITED: https://book.getfoundry.sh/projects/dependencies] |

**Key insight:** The wrapper is intentionally only an integration seam; it must delegate to the pinned oracle rather than reproduce its arithmetic.

## Common Pitfalls

### Pitfall 1: Following stale v3 wording
**What goes wrong:** The plan installs `v3-core@0.8` or imports v3 method names.  
**Why it happens:** ROADMAP.md and REQUIREMENTS.md predate the locked v4 decision. [VERIFIED: `01-CONTEXT.md`, `ROADMAP.md`, `REQUIREMENTS.md`]  
**How to avoid:** Treat D-01/D-02 as authoritative and include a docs chore replacing the Phase 1 v3 wording with `v4-core@v4.0.0`.  
**Warning signs:** Any Phase 1 task mentions `getSqrtRatioAtTick`, `getTickAtSqrtRatio`, or a 0.7.6 compiler profile. [VERIFIED: `01-CONTEXT.md`]

### Pitfall 2: An unpinned or unrecorded dependency
**What goes wrong:** A later clone resolves a different source revision.  
**Why it happens:** The tag is installed without reviewing/committing its `foundry.lock`, `.gitmodules`, and submodule gitlink.  
**How to avoid:** Use `@tag=v4.0.0`, verify the resolved commit is `e50237c43811bd9b526eff40f26772152a42daba`, and commit all generated dependency metadata. [VERIFIED: `git ls-remote`] [CITED: https://book.getfoundry.sh/projects/dependencies]  
**Warning signs:** `git status` lacks `evm/foundry.lock`, `.gitmodules`, or `evm/lib/v4-core` after install.

### Pitfall 3: An import smoke that does not exercise the library boundary
**What goes wrong:** A source file imports TickMath but nothing links one of its internal functions.  
**Why it happens:** Solidity libraries use `internal` functions, and a no-use import is weaker evidence than a compile-time call. [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol]  
**How to avoid:** Build a minimal public wrapper that delegates at least `getSqrtPriceAtTick`; it remains scaffold-only.  
**Warning signs:** The build succeeds but no local source references `TickMath.getSqrtPriceAtTick`.

### Pitfall 4: Accidentally expanding scope through `forge init`
**What goes wrong:** Generated Counter examples or a new nested Git repository add unrelated artifacts.  
**Why it happens:** Default `forge init` creates examples and initializes Git.  
**How to avoid:** Use both `--empty` and `--use-parent-git`. [VERIFIED: local `forge init --help`]

## Code Examples

### Minimal Foundry configuration

```toml
# evm/foundry.toml
[profile.default]
src = "src"
test = "test"
out = "out"
libs = ["lib"]
solc_version = "0.8.28"
remappings = ["v4-core/=lib/v4-core/"]
```

This configuration is deliberately smaller than the vol-markets example: its `via_ir`, optimizer, FFI, custom profiles, and filesystem permissions address contracts and integration tests that are outside Phase 1. [VERIFIED: `/home/jmsbpp/apps/vol-markets/foundry.toml`] [VERIFIED: `01-CONTEXT.md`]

### Pin and inspect the resolved dependency

```bash
forge install --root evm v4-core=Uniswap/v4-core@tag=v4.0.0
forge remappings --root evm
git -C evm/lib/v4-core rev-parse HEAD
forge build --root evm
```

## State of the Art

| Historical Phase wording | Current locked approach | Impact |
|--------------------------|-------------------------|--------|
| `v3-core@0.8`, v3 API names, possible 0.7.6 profiles | `Uniswap/v4-core@v4.0.0`, v4 API names, one 0.8.x default profile | All Phase 1 install/config/import references must use the v4 target. [VERIFIED: `01-CONTEXT.md`] |
| A mutable ref or handwritten dependency note | Git submodule plus generated `foundry.lock` | Pin reproducibility is checked from repository state. [CITED: https://book.getfoundry.sh/projects/dependencies] |

**Deprecated/outdated:** The Phase 1 v3 wording in ROADMAP.md and REQUIREMENTS.md is superseded by the locked CONTEXT decisions and needs the scoped documentation correction. [VERIFIED: `01-CONTEXT.md`]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | None. All implementation recommendations were checked against installed Forge behavior, the official Foundry documentation, or the locked official Uniswap release source. | — | — |

## Open Questions

1. **Should the docs wording correction include only Phase 1 traceability/success criteria or all historical narrative in REQUIREMENTS.md?**
   - What we know: D-01/D-02 supersede the Phase 1 target, and the discretion explicitly authorizes a docs chore. [VERIFIED: `01-CONTEXT.md`]
   - What's unclear: Whether historical process narrative should be retained with a supersession note.
   - Recommendation: Update every Phase 1 EVM-01/EVM-02 and roadmap occurrence; preserve later historical background only where it is explicitly labeled superseded.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Forge | scaffold, install, build | ✓ | 1.5.1-stable | None; present. [VERIFIED: local `forge --version`] |
| Git | submodule install/pin | ✓ | 2.54.0 | None; present. [VERIFIED: local `git --version`] |
| Solidity compiler | pinned build | ✓ | local `solc` 0.8.30; Forge may resolve configured 0.8.28 | Let Foundry obtain/use the configured compiler; do not silently change the pinned version. [VERIFIED: local `solc --version`] |
| Network access to GitHub | initial `forge install` | ✓ | tag ref reachable | A prepopulated Git cache/mirror could substitute only if it contains the locked commit. [VERIFIED: `git ls-remote`] |

**Missing dependencies with no fallback:** none.  
**Missing dependencies with fallback:** none.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Foundry / Forge 1.5.1-stable. [VERIFIED: local `forge --version`] |
| Config file | `evm/foundry.toml` — Wave 0 creates it. |
| Quick run command | `forge build --root evm` |
| Full suite command | `forge build --root evm && forge test --root evm` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EVM-01 | Nested Foundry configuration and source tree compile. | build smoke | `forge build --root evm` | ❌ Wave 0 |
| EVM-02 | Pinned TickMath resolves through a remapping and a local wrapper links an internal library call. | compile integration smoke | `forge build --root evm && git -C evm/lib/v4-core rev-parse HEAD` | ❌ Wave 0 |

### Required Assertions

1. `forge build --root evm` exits zero.  
2. `forge remappings --root evm` includes `v4-core/=lib/v4-core/`.  
3. `git -C evm/lib/v4-core rev-parse HEAD` equals `e50237c43811bd9b526eff40f26772152a42daba`. [VERIFIED: `git ls-remote`]  
4. `git diff --check` is clean after generated tracking files are added.  

### Sampling Rate

- **Per task commit:** `forge build --root evm`
- **Per wave merge:** `forge build --root evm && forge test --root evm`
- **Phase gate:** Build and wrapper import smoke must be green before `$gsd-verify-work`.

### Wave 0 Gaps

- [ ] `evm/foundry.toml` — pinned compiler and explicit remapping.
- [ ] `evm/src/TickMathHarness.sol` — covers import/linkage smoke for EVM-02.
- [ ] `evm/remappings.txt` and `evm/foundry.lock` — generated reproducibility records.
- [ ] Root `.gitignore` or `evm/.gitignore` rules for generated `cache/`, `out/`, and `broadcast/` artifacts.
- [ ] No unit test file is required for Phase 1; the compiling wrapper is the recommended smoke. Differential tests are deferred.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | No | No user/authentication boundary in a local build scaffold. [VERIFIED: `01-CONTEXT.md`] |
| V3 Session Management | No | No sessions. [VERIFIED: `01-CONTEXT.md`] |
| V4 Access Control | No | No deployed mutable contract behavior is introduced; wrapper functions are pure. |
| V5 Input Validation | Limited | Delegate TickMath input validation and custom errors; do not replace its bounds checks. [VERIFIED: https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol] |
| V6 Cryptography | No | No cryptographic function is in scope. [VERIFIED: `01-CONTEXT.md`] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| Dependency substitution or ref drift | Tampering | Explicit `@tag=v4.0.0`, review exact resolved SHA, and commit submodule/gitlink plus `foundry.lock`. [CITED: https://book.getfoundry.sh/projects/dependencies] |
| Generated bytecode/cache accidentally committed | Tampering | Ignore `evm/cache/`, `evm/out/`, and `evm/broadcast/`; retain the source dependency submodule. [VERIFIED: local `.gitignore`] |
| Scope creep through test-only relay integrations | Elevation of privilege | Do not add FFI, bridge, Seaport, or HEVM configuration in Phase 1. [VERIFIED: `01-CONTEXT.md`] |

## Sources

### Primary

- [Foundry dependency documentation](https://book.getfoundry.sh/projects/dependencies) — Git submodules, aliases, `foundry.lock`, remappings, `--no-git` behavior.
- [Foundry configuration overview](https://book.getfoundry.sh/config/overview) — minimal configuration and `solc_version = "0.8.28"` example.
- [Uniswap v4-core v4.0.0 TickMath](https://raw.githubusercontent.com/Uniswap/v4-core/v4.0.0/src/libraries/TickMath.sol) — pragma, APIs, direct sibling imports, and internal-library behavior.
- [Uniswap v4-core v4.0.0 tag ref](https://api.github.com/repos/Uniswap/v4-core/git/ref/tags/v4.0.0) — release commit.

### Local Verification

- `forge --version`, `forge init --help`, `forge install --help`, and `forge remappings --help`.
- `git ls-remote --tags https://github.com/Uniswap/v4-core.git v4.0.0`.
- Root `.gitignore`, `git check-ignore`, and `/home/jmsbpp/apps/vol-markets/foundry.toml`.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — installed Forge CLI, official Foundry documentation, and release tag were checked.
- Architecture: HIGH — based on the locked phase boundary and confirmed Forge dependency behavior.
- Pitfalls: HIGH — stale internal documents and exact API/dependency conditions were inspected.

**Research date:** 2026-09-08  
**Valid until:** 2026-10-08 for this pinned release and installed Forge command surface.
