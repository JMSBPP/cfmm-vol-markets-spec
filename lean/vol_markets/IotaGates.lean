module

public import Mathlib

@[expose] public section

open scoped BigOperators Topology

set_option autoImplicit false

/-!
# Pinning the ladder resolution `ι` by gamma gates and by position building

`GeomProfile.lean` proves that the geometric weights
`ℓ(ξ, ι; i) = ξ^i (1 - ξ) / (1 - ξ^ι)` form a partition of unity for every
`ι ≥ 1`.  That fact is `ι`-blind, so it cannot select `ι`.  This file states
and proves relationships that *do* depend on `ι`, so `ι` can be solved for:

1. **Flat dollar gamma (variance-swap gate).**  At the log-contract base
   `ξ* = 1.0001^(-Δi/2)` the dollar gamma `Γ p²` of every rung, evaluated at
   its grid price, is the same number
   `G(ι) = (L̄/2) (1 - ξ*) / (1 - ξ*^ι)` (`rungDollarGamma_flat`).
   `G` is strictly decreasing in `ι` (`gammaLevel_strictAnti`), with
   `G(1) = L̄/2` and `G(ι) ↓ L̄(1 - ξ)/2`.  A gamma level `g` therefore pins
   `ι` through `ξ^ι = 1 - L̄(1 - ξ)/(2g)` (`gammaLevel_eq_iff`,
   `iota_eq_log_div_log`), and a gamma *floor* `G(ι) ≥ g` is exactly
   `ι < iotaGammaCap` (`gammaGate_iff`).
2. **Position building (budget identity).**  Building the ladder rung by rung
   at a common dollar gamma `g` costs total liquidity
   `L̄ = 2g (1 - ξ^ι)/(1 - ξ)` (`budget_identity`): target vega, gamma level and
   `ι` are tied by one equation.
3. **Gamma set.**  Gating the untruncated strip `c ξ^i` at level `g` keeps
   exactly the first `iotaGammaSet` ticks (`gammaSet_iff`); the liquidity left
   outside is below `g/(1 - ξ)` (`gammaSet_tail_lt`); and renormalizing the
   kept mass returns `ℓ(ξ, ι; ·)` (`truncation_eq_geomWeight`).
4. **Coverage.**  A ladder of `ι` rungs carries the fraction `1 - ξ^ι` of the
   untruncated strip (`captured_mass`).  A tail tolerance `ξ^ι ≤ ε` is
   exactly `iotaCover ε ≤ ι` (`cover_iff`).
5. **Joint feasibility = minimum order size.**  The coverage requirement and the
   gamma floor can both hold iff they hold at `ι = iotaCover ε`, i.e. iff
   `L̄ ≥ 2g (1 - ξ^{iotaCover ε})/(1 - ξ)` (`feasible_iff`, `feasible_iff_budget`).
6. **Per-rung cost against the uncovered tail.**  `J(ι) = c ι + A ξ^ι` is
   minimized at `iotaCost`, the first `ι` with `A ξ^ι (1 - ξ) ≤ c`
   (`iotaCost_isMin`).
7. **Integer liquidity per leg (Proposition 8 of the note).**  Rounding each
   leg down gives `Q - ι < Σ ⌊Q ℓ_i⌋ ≤ Q` (`floor_ladder_le`,
   `floor_ladder_gt`).  The smallest leg `ℓ(ξ, ι; ι - 1)` is strictly
   decreasing in `ι` (`lastWeight_strictAnti`).

The definitions `geomWeight` and `priceGrid` are copied verbatim from
`GeomProfile.lean`.  They are repeated here because `GeomProfile.lean`
imports `vol_markets.Flow`, which is not part of this project, so this
file can be checked on its own.
-/

namespace IotaGates

/-! ## Definitions -/

/-- Geometric weight `ℓ(ξ, ι; i) = ξ^i (1 - ξ)/(1 - ξ^ι)` (verbatim copy of
`GeomProfile.geomWeight`). -/
noncomputable def geomWeight (ξ : ℝ) (ι : ℕ) (i : ℕ) : ℝ :=
  ξ ^ i * (1 - ξ) / (1 - ξ ^ ι)

/-- Price grid `K_i = 1.0001^(i Δi)` (verbatim copy of `GeomProfile.priceGrid`). -/
noncomputable def priceGrid (Δi : ℝ) (i : ℕ) : ℝ :=
  (1.0001 : ℝ) ^ ((i : ℝ) * Δi)

/-- The log-contract liquidity base `ξ* = 1.0001^(-Δi/2)`. -/
noncomputable def xiStar (Δi : ℝ) : ℝ :=
  (1.0001 : ℝ) ^ (-(Δi / 2))

/-- Dollar gamma `Γ p²` of rung `i` at its grid price `p = K_i`.  For the
Uniswap-v3 (`χ = 1/2`) member, `Γ = -½ L p^(-3/2)` in range, so
`Γ p² = -½ L p^(1/2)` with rung liquidity `L = L̄ ℓ(ξ, ι; i)`. -/
noncomputable def rungDollarGamma (Lbar ξ Δi : ℝ) (ι i : ℕ) : ℝ :=
  -(1 / 2) * (Lbar * geomWeight ξ ι i) * (priceGrid Δi i) ^ (1 / 2 : ℝ)

/-- The dollar-gamma level of a ladder of `ι` rungs at base `ξ` and total
liquidity `L̄`: `G(ι) = (L̄/2) (1 - ξ)/(1 - ξ^ι)`. -/
noncomputable def gammaLevel (Lbar ξ : ℝ) (ι : ℕ) : ℝ :=
  Lbar / 2 * ((1 - ξ) / (1 - ξ ^ ι))

/-- Gamma floor `g`: the first `ι` at which the floor `G(ι) ≥ g` fails.  The
largest admissible resolution is `iotaGammaCap - 1`. -/
noncomputable def iotaGammaCap (Lbar ξ g : ℝ) : ℕ :=
  sInf {n : ℕ | ξ ^ n < 1 - Lbar * (1 - ξ) / (2 * g)}

/-- Gamma set: the number of ticks on which the untruncated strip `c ξ^i`
reaches the gate `g`. -/
noncomputable def iotaGammaSet (c ξ g : ℝ) : ℕ :=
  sInf {n : ℕ | c * ξ ^ n < g}

/-- Coverage: the least `ι` whose uncovered strip fraction `ξ^ι` is at most `ε`. -/
noncomputable def iotaCover (ξ ε : ℝ) : ℕ :=
  sInf {n : ℕ | ξ ^ n ≤ ε}

/-- Cost trade-off `J(ι) = c ι + A ξ^ι`: per-rung cost `c` against the cost
`A ξ^ι` of the uncovered tail of the strip. -/
noncomputable def ladderCost (c A ξ : ℝ) (ι : ℕ) : ℝ :=
  c * ι + A * ξ ^ ι

/-- The minimizer of `ladderCost`: the first `ι` at which the marginal tail
reduction `A ξ^ι (1 - ξ)` no longer exceeds the per-rung cost `c`. -/
noncomputable def iotaCost (c A ξ : ℝ) : ℕ :=
  sInf {n : ℕ | A * ξ ^ n * (1 - ξ) ≤ c}

/-! ## Basic facts -/

lemma geomWeight_sum (ξ : ℝ) (ι : ℕ) (h0 : 0 < ξ) (h1 : ξ < 1) (hι : 1 ≤ ι) :
    ∑ i ∈ Finset.range ι, geomWeight ξ ι i = 1 := by
  have hd : 1 - ξ ^ ι ≠ 0 := by
    have := pow_lt_one₀ h0.le h1 (by omega : ι ≠ 0); linarith
  have hd' : ξ - 1 ≠ 0 := by linarith
  have hd'' : 1 - ξ ≠ 0 := by linarith
  simp only [geomWeight, ← Finset.sum_div, ← Finset.sum_mul]
  rw [geom_sum_eq h1.ne]
  field_simp
  ring

lemma geomWeight_nonneg (ξ : ℝ) (ι i : ℕ) (h0 : 0 < ξ) (h1 : ξ < 1) :
    0 ≤ geomWeight ξ ι i := by
  have := pow_le_one₀ (n := ι) h0.le h1.le
  exact div_nonneg (mul_nonneg (pow_nonneg h0.le _) (by linarith)) (by linarith)

/-- For an upward-closed nonempty set of naturals, `i < sInf S ↔ i ∉ S`. -/
private lemma lt_sInf_iff_not_mem {S : Set ℕ} (hS : S.Nonempty)
    (hup : ∀ m n, m ≤ n → m ∈ S → n ∈ S) (i : ℕ) : i < sInf S ↔ i ∉ S := by
  constructor
  · exact Nat.notMem_of_lt_sInf
  · intro hi
    by_contra h
    exact hi (hup _ _ (not_lt.1 h) (Nat.sInf_mem hS))

/-- `G(ι) = g` iff `L̄ (1 - ξ) = 2 g (1 - ξ^ι)`. -/
private lemma gammaLevel_eq_iff_mul (Lbar ξ g : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    gammaLevel Lbar ξ ι = g ↔ Lbar * (1 - ξ) = 2 * g * (1 - ξ ^ ι) := by
  have hd : 0 < 1 - ξ ^ ι := by have := pow_lt_one₀ h0.le h1 (by omega : ι ≠ 0); linarith
  rw [show gammaLevel Lbar ξ ι = Lbar * (1 - ξ) / (2 * (1 - ξ ^ ι)) by unfold gammaLevel; rw [div_mul_div_comm],
    div_eq_iff (by positivity)]
  constructor <;> intro h <;> linarith

/-- `g ≤ G(ι)` iff `2 g (1 - ξ^ι) ≤ L̄ (1 - ξ)`. -/
private lemma gammaLevel_ge_iff_mul (Lbar ξ g : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    g ≤ gammaLevel Lbar ξ ι ↔ 2 * g * (1 - ξ ^ ι) ≤ Lbar * (1 - ξ) := by
  have hd : 0 < 1 - ξ ^ ι := by have := pow_lt_one₀ h0.le h1 (by omega : ι ≠ 0); linarith
  rw [show gammaLevel Lbar ξ ι = Lbar * (1 - ξ) / (2 * (1 - ξ ^ ι)) by unfold gammaLevel; rw [div_mul_div_comm],
    le_div_iff₀ (by positivity)]
  constructor <;> intro h <;> linarith

/-! ## 1. Flat dollar gamma at `ξ*` -/

/-- **Flat dollar gamma.**  At `ξ = ξ*` every rung has dollar gamma `-G(ι)` at
its grid price, independently of the rung index. -/
theorem rungDollarGamma_flat (Lbar Δi : ℝ) (ι i : ℕ) :
    rungDollarGamma Lbar (xiStar Δi) Δi ι i = -gammaLevel Lbar (xiStar Δi) ι := by
  have key : xiStar Δi ^ i * priceGrid Δi i ^ (1 / 2 : ℝ) = 1 := by
    unfold xiStar priceGrid
    rw [← Real.rpow_natCast, ← Real.rpow_mul (by norm_num), ← Real.rpow_mul (by norm_num),
      ← Real.rpow_add (by norm_num)]
    ring_nf
    simp
  unfold rungDollarGamma gammaLevel geomWeight
  calc -(1 / 2) * (Lbar * (xiStar Δi ^ i * (1 - xiStar Δi) / (1 - xiStar Δi ^ ι)))
          * priceGrid Δi i ^ (1 / 2 : ℝ)
        = -(Lbar / 2 * ((1 - xiStar Δi) / (1 - xiStar Δi ^ ι)))
          * (xiStar Δi ^ i * priceGrid Δi i ^ (1 / 2 : ℝ)) := by ring
    _ = _ := by rw [key, mul_one]

lemma xiStar_pos (Δi : ℝ) : 0 < xiStar Δi := by
  exact Real.rpow_pos_of_pos (by norm_num) _

lemma xiStar_lt_one (Δi : ℝ) (hΔ : 0 < Δi) : xiStar Δi < 1 := by
  exact Real.rpow_lt_one_of_one_lt_of_neg (by norm_num) (by linarith)

/-- `G(1) = L̄/2`: a single rung carries all the gamma. -/
theorem gammaLevel_one (Lbar ξ : ℝ) (h1 : ξ ≠ 1) : gammaLevel Lbar ξ 1 = Lbar / 2 := by
  simp [gammaLevel, div_self (sub_ne_zero.2 h1.symm)]

/-- **Monotonicity.**  More rungs means less dollar gamma per rung. -/
theorem gammaLevel_strictAnti (Lbar ξ : ℝ) (hL : 0 < Lbar) (h0 : 0 < ξ) (h1 : ξ < 1)
    {m n : ℕ} (hm : 1 ≤ m) (hmn : m < n) :
    gammaLevel Lbar ξ n < gammaLevel Lbar ξ m := by
  have hm' : ξ ^ m < 1 := pow_lt_one₀ h0.le h1 (by omega)
  have hnm : ξ ^ n < ξ ^ m := pow_lt_pow_right_of_lt_one₀ h0 h1 hmn
  unfold gammaLevel
  apply mul_lt_mul_of_pos_left _ (by linarith)
  exact div_lt_div_of_pos_left (by linarith) (by linarith) (by linarith)

/-- The level always stays above `L̄(1 - ξ)/2`. -/
theorem gammaLevel_gt_floor (Lbar ξ : ℝ) (hL : 0 < Lbar) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    Lbar * (1 - ξ) / 2 < gammaLevel Lbar ξ ι := by
  have hι' : ξ ^ ι < 1 := pow_lt_one₀ h0.le h1 (by omega)
  have hp : 0 < ξ ^ ι := pow_pos h0 ι
  have hd : 0 < 1 - ξ ^ ι := by linarith
  unfold gammaLevel
  have : 1 - ξ < (1 - ξ) / (1 - ξ ^ ι) := by
    rw [lt_div_iff₀ hd]; nlinarith
  nlinarith

/-- ...and converges to it as `ι → ∞`. -/
theorem gammaLevel_tendsto (Lbar ξ : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1) :
    Filter.Tendsto (gammaLevel Lbar ξ) Filter.atTop (𝓝 (Lbar * (1 - ξ) / 2)) := by
  have hp : Filter.Tendsto (fun n : ℕ => ξ ^ n) Filter.atTop (𝓝 0) :=
    tendsto_pow_atTop_nhds_zero_of_lt_one h0.le h1
  have h := ((tendsto_const_nhds (x := 1 - ξ)).div (tendsto_const_nhds.sub hp)
    (by norm_num : (1 : ℝ) - 0 ≠ 0)).const_mul (Lbar / 2)
  unfold gammaLevel
  convert h using 2
  ring

/-- **Solving for `ι` from a gamma level.** -/
theorem gammaLevel_eq_iff (Lbar ξ g : ℝ) (hg : 0 < g) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    gammaLevel Lbar ξ ι = g ↔ ξ ^ ι = 1 - Lbar * (1 - ξ) / (2 * g) := by
  rw [gammaLevel_eq_iff_mul Lbar ξ g h0 h1 ι hι]
  constructor
  · intro h; field_simp; linarith
  · intro h; rw [h]; field_simp; ring

/-- Closed form: `ι = log(1 - L̄(1 - ξ)/(2g)) / log ξ`. -/
theorem iota_eq_log_div_log (Lbar ξ g : ℝ) (hg : 0 < g) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) (h : gammaLevel Lbar ξ ι = g) :
    (ι : ℝ) = Real.log (1 - Lbar * (1 - ξ) / (2 * g)) / Real.log ξ := by
  have hx := (gammaLevel_eq_iff Lbar ξ g hg h0 h1 ι hι).1 h
  have hl : Real.log ξ ≠ 0 := (Real.log_neg h0 h1).ne
  rw [eq_div_iff hl, ← hx, Real.log_pow]

/-- **Gamma floor.**  `G(ι) ≥ g` iff `ξ^ι ≥ 1 - L̄(1 - ξ)/(2g)`. -/
theorem gammaLevel_ge_iff (Lbar ξ g : ℝ) (hg : 0 < g) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    g ≤ gammaLevel Lbar ξ ι ↔ 1 - Lbar * (1 - ξ) / (2 * g) ≤ ξ ^ ι := by
  rw [gammaLevel_ge_iff_mul Lbar ξ g h0 h1 ι hι, sub_le_iff_le_add, ← sub_le_iff_le_add',
    le_div_iff₀ (by positivity)]
  constructor <;> intro h <;> linarith

/-- **The gamma floor caps `ι`.**  If the floor is above the limit level,
`g > L̄(1 - ξ)/2`, the admissible resolutions are exactly `1 ≤ ι < iotaGammaCap`. -/
theorem gammaGate_iff (Lbar ξ g : ℝ) (hL : 0 < Lbar) (hg : Lbar * (1 - ξ) / 2 < g)
    (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ) (hι : 1 ≤ ι) :
    g ≤ gammaLevel Lbar ξ ι ↔ ι < iotaGammaCap Lbar ξ g := by
  have hg0 : 0 < g := by have : 0 < Lbar * (1 - ξ) / 2 := by
                            have : 0 < 1 - ξ := by linarith
                            positivity
                         linarith
  have hr : 0 < 1 - Lbar * (1 - ξ) / (2 * g) := by
    rw [sub_pos, div_lt_one (by positivity)]; linarith
  have hne : ({n : ℕ | ξ ^ n < 1 - Lbar * (1 - ξ) / (2 * g)} : Set ℕ).Nonempty :=
    exists_pow_lt_of_lt_one hr h1
  rw [gammaLevel_ge_iff Lbar ξ g hg0 h0 h1 ι hι, iotaGammaCap,
    lt_sInf_iff_not_mem hne (fun m n hmn hm => lt_of_le_of_lt
      (pow_le_pow_of_le_one h0.le h1.le hmn) hm)]
  simp

/-- If the floor is at most the limit level, it never binds. -/
theorem gammaGate_slack (Lbar ξ g : ℝ) (hL : 0 < Lbar) (hg : g ≤ Lbar * (1 - ξ) / 2)
    (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ) (hι : 1 ≤ ι) :
    g ≤ gammaLevel Lbar ξ ι := by
  exact hg.trans (gammaLevel_gt_floor Lbar ξ hL h0 h1 ι hι).le

/-! ## 2. Building the position at a common dollar gamma -/

/-- **Budget identity.**  Rung `i` carries dollar gamma `g` at sqrt price
`ξ^(-i)` iff its liquidity is `2g ξ^i`; summing over `ι` rungs, the ladder uses
`L̄ = 2g (1 - ξ^ι)/(1 - ξ)`. -/
theorem budget_identity (g ξ : ℝ) (h1 : ξ ≠ 1) (ι : ℕ) :
    ∑ i ∈ Finset.range ι, 2 * g * ξ ^ i = 2 * g * (1 - ξ ^ ι) / (1 - ξ) := by
  have h2 : ξ - 1 ≠ 0 := sub_ne_zero.2 h1
  have h3 : 1 - ξ ≠ 0 := sub_ne_zero.2 h1.symm
  rw [← Finset.mul_sum, geom_sum_eq h1]
  field_simp
  ring

/-- The budget identity is the gamma-level identity read backwards. -/
theorem budget_iff_gammaLevel (Lbar ξ g : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) :
    Lbar = ∑ i ∈ Finset.range ι, 2 * g * ξ ^ i ↔ gammaLevel Lbar ξ ι = g := by
  have h3 : 1 - ξ ≠ 0 := by linarith
  rw [budget_identity g ξ h1.ne ι, gammaLevel_eq_iff_mul Lbar ξ g h0 h1 ι hι, eq_div_iff h3]

/-! ## 3. The gamma set of the untruncated strip -/

/-- The gamma set of the untruncated strip `c ξ^i` at gate `g` is the initial
segment of length `iotaGammaSet c ξ g`. -/
theorem gammaSet_iff (c ξ g : ℝ) (hg : 0 < g) (h0 : 0 < ξ) (h1 : ξ < 1) (i : ℕ) :
    g ≤ c * ξ ^ i ↔ i < iotaGammaSet c ξ g := by
  have hne : ({n : ℕ | c * ξ ^ n < g} : Set ℕ).Nonempty := by
    rcases le_or_gt c 0 with hc | hc
    · exact ⟨0, by simp; linarith⟩
    · obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one (div_pos hg hc) h1
      exact ⟨n, by simp only [Set.mem_setOf_eq]; rwa [lt_div_iff₀' hc] at hn⟩
  have hup : ∀ m n, m ≤ n → m ∈ {n : ℕ | c * ξ ^ n < g} → n ∈ {n : ℕ | c * ξ ^ n < g} := by
    intro m n hmn hm
    simp only [Set.mem_setOf_eq] at hm ⊢
    rcases le_or_gt 0 c with hc | hc
    · exact lt_of_le_of_lt (mul_le_mul_of_nonneg_left
        (pow_le_pow_of_le_one h0.le h1.le hmn) hc) hm
    · have : c * ξ ^ n < 0 := mul_neg_of_neg_of_pos hc (pow_pos h0 n)
      linarith
  rw [iotaGammaSet, lt_sInf_iff_not_mem hne hup]
  simp

/-- The liquidity left outside the gamma set is below `g/(1 - ξ)`. -/
theorem gammaSet_tail_lt (c ξ g : ℝ) (hc : 0 ≤ c) (hg : 0 < g) (h0 : 0 < ξ) (h1 : ξ < 1) :
    ∑' i : ℕ, c * ξ ^ (iotaGammaSet c ξ g + i) < g / (1 - ξ) := by
  have hne : ({n : ℕ | c * ξ ^ n < g} : Set ℕ).Nonempty := by
    rcases eq_or_lt_of_le hc with hc | hc
    · exact ⟨0, by simp [← hc]; linarith⟩
    · obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one (div_pos hg hc) h1
      exact ⟨n, by simp only [Set.mem_setOf_eq]; rwa [lt_div_iff₀' hc] at hn⟩
  have hN : c * ξ ^ iotaGammaSet c ξ g < g := Nat.sInf_mem hne
  have e : ∀ i : ℕ, c * ξ ^ (iotaGammaSet c ξ g + i) = c * ξ ^ iotaGammaSet c ξ g * ξ ^ i := by
    intro i; rw [pow_add]; ring
  simp_rw [e]
  rw [tsum_mul_left, tsum_geometric_of_lt_one h0.le h1, ← div_eq_mul_inv]
  exact div_lt_div_of_pos_right hN (by linarith)

/-- Renormalizing the strip `c ξ^i` on its first `ι` ticks gives `ℓ(ξ, ι; ·)`. -/
theorem truncation_eq_geomWeight (c ξ : ℝ) (hc : c ≠ 0) (h0 : 0 < ξ) (h1 : ξ < 1)
    (ι : ℕ) (hι : 1 ≤ ι) (i : ℕ) :
    c * ξ ^ i / ∑ j ∈ Finset.range ι, c * ξ ^ j = geomWeight ξ ι i := by
  have hd : 1 - ξ ^ ι ≠ 0 := by
    have := pow_lt_one₀ h0.le h1 (by omega : ι ≠ 0); linarith
  have hd' : ξ ^ ι - 1 ≠ 0 := by intro h; apply hd; linarith
  have h2 : ξ - 1 ≠ 0 := by linarith
  have h3 : 1 - ξ ≠ 0 := by linarith
  rw [← Finset.mul_sum, geom_sum_eq h1.ne, geomWeight]
  field_simp
  ring

/-! ## 4. Coverage of the strip -/

/-- A ladder of `ι` rungs carries the fraction `1 - ξ^ι` of the normalized
untruncated strip `(1 - ξ) ξ^i`. -/
theorem captured_mass (ξ : ℝ) (ι : ℕ) :
    ∑ i ∈ Finset.range ι, (1 - ξ) * ξ ^ i = 1 - ξ ^ ι := by
  rw [← Finset.mul_sum, mul_comm, geom_sum_mul_neg]

/-- **Coverage requirement.**  The uncovered tail `ξ^ι` is at most `ε` exactly
from `iotaCover ξ ε` rungs on. -/
theorem cover_iff (ξ ε : ℝ) (hε : 0 < ε) (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ) :
    ξ ^ ι ≤ ε ↔ iotaCover ξ ε ≤ ι := by
  have hne : ({n : ℕ | ξ ^ n ≤ ε} : Set ℕ).Nonempty := by
    obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hε h1
    exact ⟨n, hn.le⟩
  constructor
  · intro h; exact Nat.sInf_le h
  · intro h
    exact (pow_le_pow_of_le_one h0.le h1.le h).trans (Nat.sInf_mem hne)

/-- Closed-form bracket: `iotaCover ξ ε` is the ceiling of `log ε / log ξ`. -/
theorem iotaCover_eq_ceil (ξ ε : ℝ) (hε : 0 < ε) (h0 : 0 < ξ) (h1 : ξ < 1) :
    iotaCover ξ ε = ⌈Real.log ε / Real.log ξ⌉₊ := by
  have hl : Real.log ξ < 0 := Real.log_neg h0 h1
  have key : ∀ n : ℕ, iotaCover ξ ε ≤ n ↔ ⌈Real.log ε / Real.log ξ⌉₊ ≤ n := by
    intro n
    rw [← cover_iff ξ ε hε h0 h1 n, Nat.ceil_le, div_le_iff_of_neg hl,
      ← Real.log_le_log_iff (pow_pos h0 n) hε, Real.log_pow]
  exact le_antisymm ((key _).2 le_rfl) ((key _).1 le_rfl)

/-! ## 5. Joint feasibility -/

/-- **Joint feasibility.**  Coverage `ξ^ι ≤ ε` and the gamma floor
`G(ι) ≥ g` can hold together iff they hold at the least covering resolution. -/
theorem feasible_iff (Lbar ξ g ε : ℝ) (hL : 0 < Lbar) (hε : 0 < ε) (hε1 : ε < 1)
    (h0 : 0 < ξ) (h1 : ξ < 1) :
    (∃ ι : ℕ, 1 ≤ ι ∧ ξ ^ ι ≤ ε ∧ g ≤ gammaLevel Lbar ξ ι) ↔
      g ≤ gammaLevel Lbar ξ (iotaCover ξ ε) := by
  have hcov1 : 1 ≤ iotaCover ξ ε := by
    by_contra h
    have h' : iotaCover ξ ε ≤ 0 := by omega
    have := (cover_iff ξ ε hε h0 h1 0).2 h'
    simp at this; linarith
  constructor
  · rintro ⟨ι, hι, hcov, hg⟩
    have hle := (cover_iff ξ ε hε h0 h1 ι).1 hcov
    rcases eq_or_lt_of_le hle with h | h
    · rwa [h]
    · exact hg.trans (gammaLevel_strictAnti Lbar ξ hL h0 h1 hcov1 h).le
  · intro hg
    exact ⟨iotaCover ξ ε, hcov1, (cover_iff ξ ε hε h0 h1 _).2 le_rfl, hg⟩

/-- **Minimum order size.**  The same condition read as a budget:
`L̄ ≥ 2g (1 - ξ^n)/(1 - ξ)` with `n = iotaCover ξ ε`. -/
theorem feasible_iff_budget (Lbar ξ g ε : ℝ) (hL : 0 < Lbar)
    (hε : 0 < ε) (hε1 : ε < 1) (h0 : 0 < ξ) (h1 : ξ < 1) :
    (∃ ι : ℕ, 1 ≤ ι ∧ ξ ^ ι ≤ ε ∧ g ≤ gammaLevel Lbar ξ ι) ↔
      2 * g * (1 - ξ ^ iotaCover ξ ε) / (1 - ξ) ≤ Lbar := by
  have hcov1 : 1 ≤ iotaCover ξ ε := by
    by_contra h
    have h' : iotaCover ξ ε ≤ 0 := by omega
    have := (cover_iff ξ ε hε h0 h1 0).2 h'
    simp at this; linarith
  rw [feasible_iff Lbar ξ g ε hL hε hε1 h0 h1, gammaLevel_ge_iff_mul Lbar ξ g h0 h1 _ hcov1,
    div_le_iff₀ (by linarith)]

/-! ## 6. Per-rung cost against tail cost -/

/-- **Optimal resolution.**  `iotaCost c A ξ` minimizes `J(ι) = c ι + A ξ^ι`. -/
theorem iotaCost_isMin (c A ξ : ℝ) (hc : 0 < c) (hA : 0 ≤ A) (h0 : 0 < ξ) (h1 : ξ < 1)
    (n : ℕ) :
    ladderCost c A ξ (iotaCost c A ξ) ≤ ladderCost c A ξ n := by
  set N := iotaCost c A ξ with hN
  have hne : ({n : ℕ | A * ξ ^ n * (1 - ξ) ≤ c} : Set ℕ).Nonempty := by
    rcases eq_or_lt_of_le hA with hA0 | hA0
    · exact ⟨0, by simp [← hA0]; linarith⟩
    · obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one
        (div_pos hc (mul_pos hA0 (by linarith : (0:ℝ) < 1 - ξ))) h1
      refine ⟨n, ?_⟩
      simp only [Set.mem_setOf_eq]
      rw [lt_div_iff₀ (mul_pos hA0 (by linarith))] at hn
      nlinarith
  have hNmem : A * ξ ^ N * (1 - ξ) ≤ c := Nat.sInf_mem hne
  have step : ∀ k : ℕ, ladderCost c A ξ (k + 1)
      = ladderCost c A ξ k + (c - A * ξ ^ k * (1 - ξ)) := by
    intro k; simp only [ladderCost, pow_succ]; push_cast; ring
  have up : ∀ k, N ≤ k → ladderCost c A ξ k ≤ ladderCost c A ξ (k + 1) := by
    intro k hk
    rw [step]
    have : A * ξ ^ k * (1 - ξ) ≤ A * ξ ^ N * (1 - ξ) :=
      mul_le_mul_of_nonneg_right (mul_le_mul_of_nonneg_left
        (pow_le_pow_of_le_one h0.le h1.le hk) hA) (by linarith)
    linarith
  have down : ∀ k, k < N → ladderCost c A ξ (k + 1) ≤ ladderCost c A ξ k := by
    intro k hk
    have hk' : ¬ (A * ξ ^ k * (1 - ξ) ≤ c) := Nat.notMem_of_lt_sInf hk
    rw [step]; push_neg at hk'; linarith
  rcases le_total N n with h | h
  · induction n, h using Nat.le_induction with
    | base => exact le_rfl
    | succ m hm ih => exact ih.trans (up m hm)
  · have key : ∀ m, n ≤ m → m ≤ N → ladderCost c A ξ m ≤ ladderCost c A ξ n := by
      intro m hnm
      induction m, hnm using Nat.le_induction with
      | base => intro _; exact le_rfl
      | succ m hm ih => intro hmN; exact (down m (by omega)).trans (ih (by omega))
    exact key N h le_rfl

/-- Closed-form bracket for the optimal resolution (when `A (1 - ξ) > c`). -/
theorem iotaCost_eq_ceil (c A ξ : ℝ) (hc : 0 < c) (hA : 0 < A) (h0 : 0 < ξ)
    (h1 : ξ < 1) :
    iotaCost c A ξ = ⌈Real.log (c / (A * (1 - ξ))) / Real.log ξ⌉₊ := by
  have hp : 0 < A * (1 - ξ) := mul_pos hA (by linarith)
  have hset : iotaCost c A ξ = iotaCover ξ (c / (A * (1 - ξ))) := by
    unfold iotaCost iotaCover
    congr 1
    ext n
    simp only [Set.mem_setOf_eq]
    rw [le_div_iff₀ hp]
    constructor <;> intro h <;> linarith
  rw [hset, iotaCover_eq_ceil ξ _ (div_pos hc hp) h0 h1]

/-! ## 7. Integer liquidity per leg -/

/-- **Lens obligation (Proposition 8, upper half).**  Rounding each leg down
never delivers more than the stored target `Q`. -/
theorem floor_ladder_le (Q ξ : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ)
    (hι : 1 ≤ ι) :
    ∑ i ∈ Finset.range ι, (⌊Q * geomWeight ξ ι i⌋ : ℝ) ≤ Q := by
  calc ∑ i ∈ Finset.range ι, (⌊Q * geomWeight ξ ι i⌋ : ℝ)
      ≤ ∑ i ∈ Finset.range ι, Q * geomWeight ξ ι i :=
        Finset.sum_le_sum fun i _ => Int.floor_le _
    _ = Q := by rw [← Finset.mul_sum, geomWeight_sum ξ ι h0 h1 hι, mul_one]

/-- **Lens obligation (lower half).**  The rounding shortfall is below `ι` units:
more rungs cost more rounding. -/
theorem floor_ladder_gt (Q ξ : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ) (hι : 1 ≤ ι) :
    Q - ι < ∑ i ∈ Finset.range ι, (⌊Q * geomWeight ξ ι i⌋ : ℝ) := by
  have hne : (Finset.range ι).Nonempty := Finset.nonempty_range_iff.2 (by omega)
  calc Q - ι = ∑ i ∈ Finset.range ι, (Q * geomWeight ξ ι i - 1) := by
        rw [Finset.sum_sub_distrib, ← Finset.mul_sum, geomWeight_sum ξ ι h0 h1 hι]
        simp
    _ < ∑ i ∈ Finset.range ι, (⌊Q * geomWeight ξ ι i⌋ : ℝ) :=
        Finset.sum_lt_sum_of_nonempty hne fun i _ => Int.sub_one_lt_floor _

/-- The smallest leg `ℓ(ξ, ι; ι - 1)` strictly decreases as `ι` grows; so a
minimum leg size `Q ℓ(ξ, ι; ι - 1) ≥ m` caps `ι`. -/
theorem lastWeight_strictAnti (ξ : ℝ) (h0 : 0 < ξ) (h1 : ξ < 1) (ι : ℕ) (hι : 1 ≤ ι) :
    geomWeight ξ (ι + 1) ι < geomWeight ξ ι (ι - 1) := by
  obtain ⟨k, rfl⟩ : ∃ k, ι = k + 1 := ⟨ι - 1, by omega⟩
  simp only [geomWeight, Nat.add_sub_cancel]
  have ha : 0 < ξ ^ k := pow_pos h0 k
  have hb : ξ ^ (k + 1) < 1 := pow_lt_one₀ h0.le h1 (by omega)
  have hc : ξ ^ (k + 1 + 1) < 1 := pow_lt_one₀ h0.le h1 (by omega)
  rw [div_lt_div_iff₀ (by linarith) (by linarith)]
  have e1 : ξ ^ (k + 1) = ξ ^ k * ξ := pow_succ _ _
  have e2 : ξ ^ (k + 1 + 1) = ξ ^ k * ξ * ξ := by rw [pow_succ, e1]
  rw [e2, e1]
  have h1' : 0 < 1 - ξ := by linarith
  nlinarith [mul_pos ha (mul_pos h1' h1')]

end IotaGates

end
