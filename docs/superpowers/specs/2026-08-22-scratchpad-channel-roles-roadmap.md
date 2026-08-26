# Scratchpad roadmap — roles, channels, issue map

**Status:** living tracking doc (not an implementation plan)  
**Date:** 2026-08-22  
**Repo:** `cfmm-theory` / package `scratchpad/`

**Purpose:** Keep the **role of each part** visible while issues ship out of order. Numbered TODOs are **not** execution priority; this doc is.

---

## Two inverse problems (do not conflate)

### A — Transactional channel (GAMS / `volume_path`)

**Targets (ends):** \(\delta_{\mathrm{trans}}^\*\), \(r^{\phi}=\phi\,\delta_{\mathrm{trans}}\), transactional payoffs \(\pi^{\phi}(\pi_{\mathrm{trans}}^{\Delta Q})\).

**Transients (means):** \(\Delta s\), \(\Delta Q_X\), \(\Delta Q_M\), path nodes — **utilities only**. They exist to **realize** the targets; they are not the economic objects we parametrize in Haskell.

```
δ*_trans, r^φ*, V (volTgt)  →  volume_path.gms  →  {ΔQ_X(n), ΔQ_M(n)}
                                      ↓
                              ν_trans, π̄, g = ν_trans/V
                                      ↓
                    π_trans^ΔQ(r_trans^e) → π^φ → r^φ
```

**Role of GAMS:** inverse map from **desired rates / volume** to a **swap sequence**. Scratchpad consumes certified outputs (JSON, \(g\), \(\nu_{\mathrm{trans}}\)); it does not treat \(\Delta Q\) legs as first-class payoff parameters.

| TODO | Issue | Role in lane A |
|------|-------|----------------|
| #23 | [#34](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/34) | Prover-native \(\nu_{\mathrm{trans}}\) / \(g\) from GAMS JSON |
| #19 | — | Exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) → \(\pi_{\mathrm{trans}}^{\Delta Q}\) |
| #7 | [#3](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/3) | \(r^{\phi}=\phi\,\delta_{\mathrm{trans}}\) (return, not \(\pi^{\phi}\)) |
| #9 | [#5](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/5) | \(\phi(\Theta;\sigma^2,\nu)\) — fee schedule **consumes** \(\nu\), not \(\Delta Q\) |

Specs: `2026-08-22-scratchpad-rarb-trans-flow-design.md`; `refs/volume_path.gms`, `VOLUME_PATH.md`.

---

### B — Arbitrageur channel (vol-spread targets)

**Targets (ends):** volatility spread \(\sigma_{\mathrm{IV}}-\sigma^{e}\); arb expected return \(r_{\Delta Q_{\mathrm{arb}}}^{e}\); arb payoff \(\pi_{\mathrm{arb}}^{\Delta Q}\); LVR read \(\pi^{\mathrm{LVR}}(\pi_{\mathrm{arb}}^{\Delta Q})\).

**Contrary structure:** where A starts from \(\delta_{\mathrm{trans}}\) and **generates path**, B starts from **vol state / gap** and **parametrizes** arb return and arb swap payoff. Path geometry for arb (if needed later) is a **different** inverse problem — not `volume_path`’s \(\delta^\*\) shock.

```
σ_IV(u,φ), σ^e  →  VolGap  →  r_arb^e = g(VolGap)  →  π_arb^ΔQ
                                                      ↓
                                              π^LVR(π_arb^ΔQ)
```

| TODO | Issue | Role in lane B |
|------|-------|----------------|
| #20 | — | Latent \(u=\ln(V/L)\); \(\sigma_{\mathrm{IV}}=2\phi e^{u/2}\) |
| #21 | [#31](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/31) | \(\sigma^{e}\), `volGap`, \(r_{\mathrm{arb}}^{e}\), \(\pi_{\mathrm{arb}}^{\Delta Q}\) |
| #22 | [#28](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/28) | Weight \(\beta\) on arb leg in RARB return split |

Specs: `2026-08-22-scratchpad-sigma-iv-latent-u-design.md`; `2026-08-22-scratchpad-expected-volatility-design.md`.

---

### C — Net contractual / CLMM position (composition)

**Already shaped:** contractual volatility / CLMM geometry \(\pi^{c|p}+\pi^{\mathrm{RAN}}\) (`CLMMPosition`).

**Realized net fee accrual:**

\[
\pi^{\varphi}
=
\pi^{\phi}\!\bigl(\pi_{\mathrm{trans}}^{\Delta Q}\bigr)
-
\pi^{\mathrm{LVR}}\!\bigl(\pi_{\mathrm{arb}}^{\Delta Q}\bigr)
\;\equiv\;
\pi^{c|p}+\pi^{\mathrm{RAN}}.
\]

So the position payoff is a **function of net fee revenue** = transactional fee revenue **minus** LVR read from the arb swap leg — not a third independent mixture.

| TODO | Issue | Role in lane C |
|------|-------|----------------|
| #24 | [#35](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/35) | \(\pi^{\varphi}\) decomposition; LVR functional; CLMM identity |
| #17–#18 | — | Measure \(m\), \(\mathbb{E}^{\mathbb{Q}}[m\cdot\pi^{\varphi}]\) |
| #6 | [#2](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/2) | Compose returns → \(r(0)\); **blocked** until A+B returns exist |

Spec: `2026-08-22-scratchpad-pi-varphi-lvr-decomposition-design.md`.

---

## RARB return split (controls, not path)

\[
r_{\Delta Q}^{e}
=
\underbrace{r_{\Delta Q_{\mathrm{trans}}}^{e}}_{\text{lane A control}}
+
\beta\cdot
\underbrace{r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV}-\sigma^{e})}_{\text{lane B control}}
\]

| Object | Lane | Transient? |
|--------|------|------------|
| \(\delta_{\mathrm{trans}}\), \(r^{\phi}\), \(\pi^{\phi}\) | A | No — targets / payoffs |
| \(\{\Delta Q_X,\Delta Q_M,\Delta s\}\) | A | **Yes** — GAMS utilities |
| \(\sigma_{IV},\sigma^{e},\mathrm{VolGap}\), \(r_{\mathrm{arb}}^{e}\), \(\pi_{\mathrm{arb}}^{\Delta Q}\) | B | No — targets / payoffs |
| \(\pi^{\mathrm{LVR}}\), \(\pi^{\varphi}\) | C | No — derived / net |
| \(\nu_{\mathrm{trans}}\) | A | Latent **intensity** from path; not a swap leg |

---

## Suggested execution waves (role-preserving)

Refactor / hygiene can interleave anytime (low semantic impact): **#10–#13, #16**.

| Wave | Goal | TODOs | Start when |
|------|------|-------|------------|
| **0** | Merge in-flight σ^e Slice 1 + docs | PR [#33](https://github.com/d2p-finance/cfmm-vol-markets-spec/pull/33) / #21 Slice 1 | now |
| **1 — Trans controls** | Parametrize \(\pi_{\mathrm{trans}}^{\Delta Q}\); GAMS stays path prover | **#19** (open issue), then **#7** stub [#3](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/3) | after Wave 0 |
| **2 — Prover bridge** | Transients → \(\nu_{\mathrm{trans}}\), \(g\); pin \(\delta_{\mathrm{trans}}\) | **#23** [#34](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/34) | after #19 |
| **3 — Vol / arb controls** | \(\sigma_{IV}\), \(\sigma^{e}\), gap → \(r_{\mathrm{arb}}^{e}\), \(\pi_{\mathrm{arb}}^{\Delta Q}\) | **#20**, **#21** feat, **#22** [#28](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/28) | after Wave 1 (can overlap Wave 2) |
| **4 — Net \(\pi^{\varphi}\)** | Fee − LVR; CLMM check | **#24** [#35](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/35) | after #19 + #21 arb leg enough |
| **5 — \(\pi^{\sigma}=f(\pi^{\varphi})\)** | Pin Panoptic \(f\) linking \(\Pi_{\mathrm{opt}}\) to \(\pi^{\varphi}\) | **#25** | after #24 |
| **6 — Measure + compose** | \(\mathbb{E}^{\mathbb{Q}}\); unblock #6 | **#17**, **#18**, **#6** [#2](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/2) | after Waves 3–4 |
| **Parallel** | Adaptive fee body consuming \(\nu\) | **#9** [#5](https://github.com/d2p-finance/cfmm-vol-markets-spec/issues/5) | after #23 enough for \(\nu\) |
| **Side** | Liquidity / Panoptic density | **#14**, **#15** | anytime |

**First code issue to open and execute:** TODO **#19** (exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\)).

---

## Shipped anchors (do not re-litigate)

| Piece | Status |
|-------|--------|
| \(\pi^{\phi}\) base + mixture | Done (#5 / PR #14) |
| \(\pi^{\Delta Q}(r^e)\) mixture | Done |
| `CLMMPosition` = call\|put + RAN | Done |
| `MarkUpStructure` | Done |
| \(\sigma^{e}\) Slice 1 stub | **Merged** PR [#33](https://github.com/d2p-finance/cfmm-vol-markets-spec/pull/33) |
| `volume_path.gms` prover | In `refs/` — **path utility**, not Haskell payoff |

---

## One-line memory aid

> **GAMS invents swaps to hit \(\delta_{\mathrm{trans}}\) / \(r^{\phi}\).**  
> **Arb invents returns to hit \(\sigma_{IV}-\sigma^{e}\).**  
> **CLMM \(\pi^{\varphi}\) is fee(trans) − LVR(arb).**  
> **\(\pi^{\sigma}=\Delta Q_{v}\cdot\Pi^{\sigma}_{\mathrm{opt}}\) (Panoptic); \(f(\pi^{\varphi})\) is open (#25).**  
> **\(\Delta Q,\Delta s\) are never the story — targets and net \(\pi^{\varphi}\) are.**
