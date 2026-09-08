# Technology Stack

**Analysis Date:** 2026-09-08  
**HEAD:** `f2736e058cfde1a03708f34772bfc2bb47c55cf6`  
**Package:** `cfmm-vol-markets-spec` — Haskell executable twin of vol-markets / CFMM variance-vol instruments with EVM fixed-point semantics (Q64.96 / Q96 integer math).

## Languages

**Primary:**
- **Haskell (GHC 9.10.3)** — All spec logic in `src/` (58 modules): payoffs, Panoptic bit-packing, Uniswap-style tick/sqrt math, Greeks, volatility grid. Default language: Haskell2010.
- **Lean 4 (v4.28.0)** — Machine-checked proofs in `lean/` (`exp`, `vol_markets`, `tao` libraries). Executable twin cites theorem names; does not re-prove.

**Secondary:**
- **Markdown / LaTeX** — Notation anchor (`notes/VOLATILITY_INSTRUMENTS.md`), design specs (`docs/superpowers/specs/`), protocol integration notes (`protocol/`).
- **YAML / TOML** — `package.yaml` (Haskell source of truth), `stack.yaml`, `lakefile.toml`.
- **Shell** — CI install steps (`.github/workflows/ci.yml`).

## Runtime

**Environment:**
- **Native compiled binaries** — No long-lived server in-repo. `stack exec cfmm-vol-markets-spec-exe` runs a batch plot/regression driver (`app/Main.hs`); `stack test` runs a large IO regression suite (`test/Spec.hs`, ~2100 lines).
- **Lean interpreter / compiler** — `lake build` compiles proof libraries; no runtime service.
- **Fixed-point semantics** — Integer `Q96 = 2^96` words (`SqrtGrid.pattern Q96`), staged `mulDiv` chains mirroring EVM `FullMath.mulDiv` (`src/SqrtGrid.hs`, `docs/BITWIDTHS.md`). Not a separate VM today; **hevm** is the intended future EVM runtime (`EVM.hs` — not present in repo).

**Package Manager / Build orchestration:**
- **Stack 3.11.x** — Primary Haskell build (`stack build`, `stack test`). Snapshot: **Stackage LTS 24.55** (`stack.yaml`, lock in `stack.yaml.lock`).
- **Cabal 3.0** — Generated from hpack: `cfmm-vol-markets-spec.cabal` (do not hand-edit; regenerate via hpack/stack).
- **hpack 0.39.6** — `package.yaml` → `.cabal`.
- **Lake (Lean)** — `lakefile.toml` + `lake-manifest.json`; toolchain from `lean-toolchain`.
- **elan** — Lean version manager (CI installs from `elan-init.sh`).

## Frameworks

**Core (domain libraries — not web frameworks):**
- **Public Haskell library** (`library:` in `package.yaml`, `source-dirs: src`) — Plot-free numeric core exported to downstream consumers.
- **Internal `plot` library** (`internal-libraries.plot`, `source-dirs: plot`) — Chart wrappers only; not visible to external `build-depends`.
- **Lean proof families** — Three independent libs configured in `lakefile.toml`: `exp`, `vol_markets`, `tao`.

**Testing:**
- **HUnit-style IO assertions** — `test/Spec.hs` via `test-suite cfmm-vol-markets-spec-test` (exitcode-stdio-1.0, threaded RTS `-N`).
- **Lean compiler sorry-guard** — CI fails on `declaration uses 'sorry'/'admit'` (`.github/workflows/ci.yml` job `lean`).

**Build / Dev:**
- **Stack `--pedantic`** — CI builds with strict warnings (`-Wall` family in `package.yaml` `ghc-options`).
- **Chart + Chart-cairo** — PNG panel output (`plot/Plotting/`, `outputs/` gitignored). Requires system Cairo/Pango (CI: `libcairo2-dev`, `libpango1.0-dev`, `libglib2.0-dev`, `pkg-config`).
- **Mathlib4 v4.28.0** — Lean dependency (`lake exe cache get` for precompiled oleans).

## Key Dependencies

**Critical (public library — stays lightweight):**
- **base** (>= 4.7 && < 5) — Prelude / core types.
- **vector** — Numeric grids (volatility surfaces, paths).
- **mwc-random** — Seeded stochastic paths in tests and demos.

**Plot / dev-only (internal `plot` lib, exe, test):**
- **Chart**, **Chart-cairo**, **colour** — Cairo-backed chart rendering; isolated so downstream RPC adapters avoid native graphics deps (`package.yaml` comment: evm-spec-bridge / JSON-RPC consumers).

**Lean:**
- **mathlib4** @ `v4.28.0` (`rev` `8f9d9cff6bd728b17a24e163c9402775d9e6a365`) — Proof infrastructure.
- Transitive Lake packages (inherited): `plausible`, `LeanSearchClient`, `importGraph`, etc. (`lake-manifest.json`).

**Executable-only:**
- **directory** — Creates `outputs/` tree from `app/Main.hs`.

**Explicitly removed / planned:**
- **hevm** — Not a dependency; intended path to on-chain symbolic execution → future `EVM.hs`.
- **LeanEVM** (`Philogy/LeanEVM`) — Removed 2026-07-16 from `lakefile.toml` (toolchain mismatch; restore with on-chain proofs).

## Configuration

**Environment:**
- **No `.env` or runtime secrets in-repo** — Spec package is offline-first.
- **Optional external:** `ARISTOTLE_API_KEY` for Lean theorem-proving workflow (`lean/README.md`); never committed.

**Build:**
| File | Role |
|------|------|
| `package.yaml` | Haskell package definition (libraries, exe, test, deps) |
| `stack.yaml` | Stackage LTS 24.55 snapshot URL |
| `stack.yaml.lock` | Pinned snapshot SHA |
| `cfmm-vol-markets-spec.cabal` | hpack-generated Cabal file |
| `lakefile.toml` | Lean libs, Mathlib pin, default targets |
| `lake-manifest.json` | Locked Lean package revisions |
| `lean-toolchain` | `leanprover/lean4:v4.28.0` |

**Outputs:**
- `outputs/` — Generated PNG panels from exe/tests (gitignored per `.gitignore`).
- `.stack-work/`, `.lake/` — Build artifacts (gitignored).

## Platform Requirements

**Development:**
- **Linux / macOS / WSL** — CI targets `ubuntu-latest`. Cairo/Pango dev headers required for Chart-cairo (Stack job only).
- **GHC 9.10.3** — Provided by Stack LTS 24.55.
- **Stack >= 3.11** (CI: `haskell-actions/setup@v2`, `enable-stack: true`).
- **elan + Lake** — For Lean work; ~7 min Mathlib cache fetch on cold CI (`lake exe cache get`).
- **Network** — Stackage snapshot, Mathlib cache, git deps for Lake.

**Production / distribution:**
- **Hackage-style library** — Public lib is plot-free for embedding in downstream Haskell apps (e.g. `apps/evm_spec_rpc` / `cfmm-adapter` per project context).
- **GitHub canonical repo** — `d2p-finance/cfmm-vol-markets-spec` (fork workflow: `JMSBPP` → upstream PRs per `AGENTS.md`).
- **No containerized deploy in-repo** — Artifact is compiled Haskell library + Lean proof objects, not a deployed service.

## Library layout (build targets)

```
cfmm-vol-markets-spec          # public: src/
cfmm-vol-markets-spec:plot     # internal: plot/
cfmm-vol-markets-spec-exe      # app/Main.hs → outputs/**
cfmm-vol-markets-spec-test     # test/Spec.hs
lake: exp | vol_markets | tao  # lean/
```

Downstream must depend only on `cfmm-vol-markets-spec` (not `:plot`) to avoid Cairo.

---

*Stack analysis: 2026-09-08*  
*Update after major dependency changes (GHC/LTS bump, hevm integration, LeanEVM restore)*
