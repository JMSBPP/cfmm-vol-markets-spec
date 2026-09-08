# Phase 1: Forge `evm/` + v3-core - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-09-08
**Phase:** 1-Forge `evm/` + v3-core
**Areas discussed:** `v3-core@0.8` pin (only gray area selected)

---

## Gray area selection

| Option | Description | Selected |
|--------|-------------|----------|
| 1. `v3-core@0.8` pin | Exact forge install / what `@0.8` means | ✓ |
| 2. Solc / Foundry profile | via_ir / optimizer depth | |
| 3. Repo hygiene / CI | gitignore, CI job for forge | |
| 4. Smoke test shape | import-only vs tiny wrapper | |

**User's choice:** `1` only
**Notes:** Bridge, Seaport diffs, SqrtGrid out of Phase 1 scope by design.

---

## Q1 — What should `forge install v3-core@0.8` resolve to?

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Official Uniswap/v3-core (0.7.6) | Ignore @0.8 wording; pin release | |
| 2. Solc 0.8 Forge + official v3-core as lib | Isolate lib with compiler profile | ✓ (then superseded) |
| 3. Uniswap v4 TickMath (0.8+) | Use v4-core TickMath | (later override) |
| 4. Other | Paste exact forge install | |

**User's choice:** `2`
**Notes:** Later user switched to v4 TickMath after clarifying no Uniswap tag `@0.8`.

---

## Q2 / Q3 — Pin + isolation (v3 path, before override)

| Option | Description | Selected |
|--------|-------------|----------|
| Q2: v1.0.0 / commit / you decide | v3-core git pin | (superseded by v4) |
| Q3: profiles+restrictions / separate profile / you decide | Isolate 0.7.6 under 0.8 | User: isolation `1`; then dropped |

**User's choice:** freeform `the tag @0.8, 1` then `lets use the v4 tick math then`
**Notes:** `@0.8` is not a Uniswap/v3-core tag. User chose v4 TickMath instead.

---

## Q — v4-core pin

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Uniswap/v4-core@v4.0.0 | Release tag | ✓ |
| 2. main / floating | Not for bit-identity | |
| 3. You decide | Planner picks v4.0.0 | |

**User's choice:** `1`

---

## Scope check — is Phase 1 the Seaport TickMath↔SqrtGrid driver?

| Option | Description | Selected |
|--------|-------------|----------|
| 1. Finish Phase 1 CONTEXT scaffold-only; discuss driver in Phase 2+ | | ✓ |
| 2. Re-scope Phase 1 to include Seaport TickMath.diff RED | | |
| 3. Write CONTEXT noting driver = Phase 2+; jump discuss | | |

**User's choice:** `1`
**Notes:** Driver = Uniswap TickMath tests as client vs EVM-adapted SqrtGrid (Seaport pattern) — deferred to Phase 2 (base) / 4+ (suite).

---

## the agent's Discretion

- Exact 0.8.x solc patch, remapping alias spelling, smoke import shape
- Docs chore to rename ROADMAP/REQUIREMENTS `v3-core@0.8` → `v4-core@v4.0.0`

## Deferred Ideas

- Seaport DifferentialTest base → Phase 2
- Bridge submodule / hevm.call → Phase 3
- TickMath.diff corpus + SqrtGrid twin → Phases 4–6
- Unselected gray areas (profile depth, CI, smoke detail)
