# Scratchpad π^φ decomposition — π^φ, LVR, CLMM replication

**Status:** approved — plan TBD; TODO #24  
**Date:** 2026-08-22  
**Repo:** `cfmm-theory` / package `scratchpad/`  
**Brainstorm:** π^{c|p}+π^RAN ≡ π^φ ≡ π^φ−π^LVR; π^arb ≡ π_arb^ΔQ; parametrized π^φ  
**Linked TODO:** #24; #7, #19, #21 (RARB legs), #17–#18 (measure)

**Reads:** `scratchpad/README.md`; `Payoffs/CLMMPosition.hs`; `Payoffs/TransactionalFeeCapture.hs`; `Payoffs/Swap.hs`; `docs/superpowers/specs/2026-08-22-scratchpad-rarb-trans-flow-design.md`; `refs/VOLATILITY_INTRUMENTS_MEV.md` (Def 32, normalized returns)

---

## Purpose

Establish the **payoff-level** decomposition linking:

1. **CLMM geometry:** \(\pi^{c|p}+\pi^{\mathrm{RAN}}\equiv\pi^{\varphi}\)
2. **Fee − LVR economics:** \(\pi^{\varphi}\equiv\pi^{\phi}-\pi^{\mathrm{LVR}}\)
3. **Orthogonal parametrization:** trans vs arb swap legs (RARB), with \(\pi^{\mathrm{arb}}\equiv\pi_{\mathrm{arb}}^{\Delta Q}\)

**Out of scope:** full `DiscountFactor` (#17), Milionis closed-form LVR beyond CPMM sanity check, on-chain twins.

---

## §1 — Identity chain (approved)

\[
\pi^{c|p} + \pi^{\mathrm{RAN}}
\;\equiv\;
\pi^{\varphi}
\;\equiv\;
\pi^{\phi} - \pi^{\mathrm{LVR}}.
\]

| Symbol | Meaning | Code |
|--------|---------|------|
| \(\pi^{c\|p}\) | Covered call **or** cash-secured put | `CoveredCall` / `CashSecuredPut` |
| \(\pi^{\mathrm{RAN}}\) | Range accrual note (same strike) | `RangeAccrualNote` |
| Sum | Single-tick CLMM LP | `CLMMPosition` |
| \(\pi^{\phi}\) | Fee-revenue payoff | `TransactionalFeeCapture` |
| \(\pi^{\mathrm{LVR}}\) | LVR / gamma leg (derived) | planned stub |
| \(\pi^{\varphi}\) | Net LP accrual after LVR | compose |

MEV state plant (Def 32): \(x\) includes \(\pi^{\phi}\) and \(\pi^{\phi}-\pi^{\mathrm{LVR}}\) (= \(\pi^{\varphi}\)).

---

## §2 — Functional tags (approved; π^arb = A)

**Transactional channel** (exogenous \(r_{\Delta Q_{\mathrm{trans}}}^{e}\) only):

\[
\pi^{\mathrm{trans}} \equiv \pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e}),
\qquad
\pi^{\phi} = \pi^{\phi}\!\bigl(\pi^{\mathrm{trans}}\bigr)
= \pi^{\phi}(r_\phi^e;\cdot).
\]

**Arb channel** (\(\pi^{\mathrm{arb}}\equiv\pi_{\mathrm{arb}}^{\Delta Q}\) — **not** a separate object):

\[
\pi_{\mathrm{arb}}^{\Delta Q}\!\bigl(r_{\mathrm{arb}}^{e}(\sigma_{IV}-\sigma^{e})\bigr),
\qquad
\pi^{\mathrm{LVR}} = \pi^{\mathrm{LVR}}\!\bigl(\pi_{\mathrm{arb}}^{\Delta Q}\bigr).
\]

**Net accrual (parametrized functional relation π^φ ↔ π_arb):**

\[
\boxed{
\pi^{\varphi}\bigl(r_{\mathrm{trans}}^{e}, r_{\mathrm{arb}}^{e}\bigr)
=
\pi^{\phi}\!\bigl(\pi_{\mathrm{trans}}^{\Delta Q}(r_{\mathrm{trans}}^{e})\bigr)
-
\pi^{\mathrm{LVR}}\!\bigl(\pi_{\mathrm{arb}}^{\Delta Q}(r_{\mathrm{arb}}^{e})\bigr)
}
\]

Subtractive composition: \(\pi^{\varphi}\) depends on arb **only** through \(\pi^{\mathrm{LVR}}(\cdot)\).

**Return level (MEV-normalized, implement first):**

\[
\mathcal{N}_\pi := \frac{1}{\pi^{\mathrm{linear}}(t_0)},
\qquad
r^{\varphi}
=
r^{\phi}(r_{\mathrm{trans}}^{e})
-
r^{\mathrm{LVR}}\!\bigl(r_{\mathrm{arb}}^{e}\bigr),
\qquad
\pi^{\varphi} \approx \mathcal{N}_\pi^{-1}\, r^{\varphi}.
\]

Refs CPMM specialization: \(r^{\mathrm{LVR}}=\sigma_t^2\Delta t/8\), \(r^{\phi}=\phi_t\delta_{\mathrm{trans},t}\).

---

## §3 — RARB orthogonality (unchanged)

Return split:

\[
r_{\Delta Q}^{e}
=
r_{\Delta Q_{\mathrm{trans}}}^{e}
+
\beta\cdot r_{\Delta Q_{\mathrm{arb}}}^{e}(\sigma_{IV}-\sigma^{e}).
\]

Payoff composition for \(\pi^{\varphi}\) is **not** a single mixture on undifferentiated \(\pi^{\Delta Q}\):

- Trans mixture: **only** \(r_{\mathrm{trans}}^{e}\) → `TransactionalExpectedReturn` (RARB spec)
- Arb mixture: **only** \(r_{\mathrm{arb}}^{e}\) → `ArbExpectedReturn` (#21)
- \(\pi^{\varphi}\): fee on trans **minus** LVR functional of arb leg

Disambiguate \(\beta\) (RARB weight, #22) from any future \(\beta_{\mathrm{LVR}}\) if payoff-level affine is added later.

---

## §4 — π^LVR(π_arb^ΔQ) — minimal stub

**Default (this cycle):** read **normalized return** from evaluated arb swap leg:

1. Build \(\pi_{\mathrm{arb}}^{\Delta Q}\) via `runArbSwapAlongTenorMixture` (deferred #21; test with zero / placeholder leg until then).
2. `lvrReturnFromArbSwap` = payoff along tenor / \(\pi^{\mathrm{linear}}(t_0)\) (MEV \(\mathcal{N}_\pi^{-1}\) convention).
3. **CPMM sanity:** when arb leg is fair at pinned vol, recover \(r^{\mathrm{LVR}}=\sigma^2\Delta t/8\) within test tolerance.

**Not:** independent Milionis scalar bypassing \(\pi_{\mathrm{arb}}^{\Delta Q}\).

**Sign:** LVR is **subtracted** from \(\pi^{\phi}\); arb leg evaluation convention must match MEV (positive LVR cost).

---

## §5 — Module map and slices

| Slice | Deliverable | Depends |
|-------|-------------|---------|
| **0** | Spec + README pointer | — |
| **1** | `lvrReturnFromArbSwap` stub (return-only); tests with placeholder arb=0 | RARB trans tag optional |
| **2** | `piVarphiFromTransArb` = fee path − LVR functional | #21 arb mixture, Slice 1 |
| **3** | CLMM identity test: \(\pi^{c\|p}+\pi^{\mathrm{RAN}}\) vs \(\pi^{\varphi}\) at witness strike | Slice 2, `CLMMPosition` |
| **4** | \(\mathbb{E}^{\mathbb{Q}}[m\cdot\pi^{\varphi}]\) | #17–#18 |

**Planned modules:**

- `Payoffs.LvrFromArbSwap` — `lvrReturnFromArbSwap`, later `lvrPayoffFromArbSwap`
- `Payoffs.PiVarphi` — compose fee capture − LVR (or return-level first)

---

## §6 — Economic meaning

For a concentrated-liquidity LP position decomposed as short option + range accrual (`CLMMPosition`), **net fee accrual after arbitrageur extraction** is \(\pi^{\varphi}=\pi^{\phi}-\pi^{\mathrm{LVR}}\). Fee revenue \(\pi^{\phi}\) accrues on **transactional** flow (\(\pi^{\mathrm{trans}}\) channel); LVR is the **gamma cost** read from the **arb swap leg** \(\pi_{\mathrm{arb}}^{\Delta Q}\), not from transactional mixture weights. The MEV tax objective maximizes \(\mathbb{E}[r^{\phi}-r^{\mathrm{LVR}}]=\mathbb{E}[r^{\varphi}]\) — this spec makes that identity explicit at the payoff level before measure #17–#18.

---

## §7 — Testing

| Test | Slice |
|------|-------|
| `lvrReturnFromArbSwap` zero when arb leg zero | 1 |
| CPMM: \(r^{\mathrm{LVR}}\approx\sigma^2\Delta t/8\) given fair arb fixture | 1–2 |
| `piVarphi`: trans-only ⇒ equals fee capture path | 2 |
| CLMM witness: call+RAN vs put+RAN unchanged; vs \(\pi^{\varphi}\) deferred until Slice 3 | 3 |

---

## Self-review

- [x] π^arb ≡ π_arb^ΔQ explicit (choice A)
- [x] No claim π^LVR = π_arb identically — functional read-off
- [x] Orthogonal trans/arb parametrization consistent with RARB spec
- [x] CLMM and MEV refs mapped to shipped modules
- [x] Scope bounded; arb mixture deferred to #21
