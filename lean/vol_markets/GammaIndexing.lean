module

public import vol_markets.IotaGates

@[expose] public section

set_option autoImplicit false

/-!
# Indexing by the gamma coordinate: `L(Γ)` and `ι(Γ)`

Setting: the convention of `IotaGates.lean`, i.e. the price grid `K_i = 1.0001^(i Δi)`,
the base `ξ* = 1.0001^(-Δi/2)`, and the Uniswap-v3 rung gamma
`Γ = -½ L p^(-3/2)`.

The gamma coordinate of a price is `Γ(q) = q^(-3/2)`.  On the tick `i` it is
`Γ_i = Γ(K_i) = K_i^(-3/2)` (`gammaCoord`).  This map from ticks to values is injective
(`gammaCoord_injective`), so any function of the tick can also be indexed by `Γ`.  The
results below spell out what that re-indexing gives.

* **The coordinate is a power of `ξ*`.**  `Γ_i = (ξ*)^(3i)` (`gammaCoord_eq_pow`).  Its
  inverse is `i = log Γ / (3 log ξ*)` (`tickOfGamma_gammaCoord`), and the root sqrt-price is
  `K_i^(1/2) = Γ_i^(-1/3)` (`sqrtPrice_eq_gammaCoord`).
* **`L(Γ)`.**  Rung `i` of the geometric ladder at `ξ*` has liquidity
  `L̄ ℓ(ξ*, ι; i) = 2 G(ι) Γ_i^(1/3)` (`rungLiquidity_eq_onGamma`).  So the liquidity is a
  power `1/3` of the gamma coordinate, and the dollar gamma of a rung is
  `-½ L(Γ) Γ^(-1/3) = -G(ι)` (`dollarGamma_onGamma`).  Conversely, a ladder with any
  per-rung liquidities has dollar gamma equal to `-g` on every rung iff its liquidity is
  `L(Γ) = 2 g Γ^(1/3)` (`flat_iff_onGamma`).
* **`ι(Γ)`.**  The resolution `ι` is the tick at which the ladder ends, so it is read off
  the gamma coordinate at that end: `ι = log Γ_ι / (3 log ξ*)` with `Γ_ι = (ξ*)^(3ι)`
  (`iota_eq_tickOfGamma`).  In that coordinate the level is
  `G = (L̄/2)(1 - ξ*)/(1 - Γ_ι^(1/3))` (`gammaLevel_onGamma`).  A gamma level `g` fixes the
  end coordinate, `G(ι) = g ↔ Γ_ι = (1 - L̄(1 - ξ*)/(2g))³` (`gammaLevel_eq_iff_endCoord`),
  and a gamma floor `g ≤ G(ι)` is the lower bound `(1 - L̄(1 - ξ*)/(2g))³ ≤ Γ_ι`
  (`gammaFloor_iff_endCoord`).  The case `ι = 1` is `Γ_1 = (ξ*)³` (`endCoord_one`), and the
  one rung sits at `Γ_0 = 1` with liquidity `L̄` (`singleRung_onGamma`).
* **The CFMM1 profile.**  `L_CFMM1(q) = ℓ/(2 q^(3/2)) = ½ ℓ Γ(q)` (`cfmmProfile_eq_gamma`).
  The rung dollar gamma is `-K_i² L_CFMM1(K_i)` with `ℓ` the rung liquidity
  (`rungDollarGamma_eq_cfmm`).  On the ladder at `ξ*` this gives
  `K_i² L_CFMM1(K_i) = G(ι)`, which equals `L̄/2` at `ι = 1` (`cfmm_dollarGamma_ladder`,
  `cfmm_dollarGamma_one`), and `L_CFMM1(K_i) = G(ι) Γ_i^(4/3)` (`cfmmProfile_ladder_onGamma`).
-/

namespace GammaIndexing

open IotaGates

/-! ## The gamma coordinate on the tick grid -/

/-- Gamma coordinate of a price, `Γ(q) = q^(-3/2)`. -/
noncomputable def gammaOfPrice (q : ℝ) : ℝ := q ^ (-(3 / 2 : ℝ))

/-- Gamma coordinate of tick `i`, `Γ_i = Γ(K_i) = K_i^(-3/2)`. -/
noncomputable def gammaCoord (Δi : ℝ) (i : ℕ) : ℝ := gammaOfPrice (priceGrid Δi i)

/-- Real-valued inverse of the coordinate: `i = log Γ / (3 log ξ*)`. -/
noncomputable def tickOfGamma (Δi Γ : ℝ) : ℝ := Real.log Γ / (3 * Real.log (xiStar Δi))

/-- Liquidity indexed by the gamma coordinate for the geometric ladder at total liquidity
`L̄`, base `ξ` and resolution `ι`: `L(Γ) = 2 G(ι) Γ^(1/3)`. -/
noncomputable def ladderLiqOnGamma (Lbar ξ : ℝ) (ι : ℕ) (Γ : ℝ) : ℝ :=
  2 * gammaLevel Lbar ξ ι * Γ ^ (1 / 3 : ℝ)

/-- The CFMM1 liquidity profile `L(q) = ℓ / (2 q^(3/2))`. -/
noncomputable def cfmmProfile (ℓ q : ℝ) : ℝ := ℓ / (2 * q ^ (3 / 2 : ℝ))

lemma priceGrid_pos (Δi : ℝ) (i : ℕ) : 0 < priceGrid Δi i :=
  Real.rpow_pos_of_pos (by norm_num) _

lemma gammaCoord_pos (Δi : ℝ) (i : ℕ) : 0 < gammaCoord Δi i :=
  Real.rpow_pos_of_pos (priceGrid_pos Δi i) _

/-- `Γ_i = (ξ*)^(3i)`. -/
theorem gammaCoord_eq_pow (Δi : ℝ) (i : ℕ) : gammaCoord Δi i = xiStar Δi ^ (3 * i) := by
  unfold gammaCoord gammaOfPrice priceGrid xiStar
  rw [← Real.rpow_natCast, ← Real.rpow_mul (by norm_num), ← Real.rpow_mul (by norm_num)]
  push_cast
  ring_nf

/-- `Γ_i^(1/3) = (ξ*)^i`. -/
lemma gammaCoord_rpow_third (Δi : ℝ) (i : ℕ) :
    gammaCoord Δi i ^ (1 / 3 : ℝ) = xiStar Δi ^ i := by
  rw [gammaCoord_eq_pow, ← Real.rpow_natCast, ← Real.rpow_natCast,
    ← Real.rpow_mul (xiStar_pos Δi).le]
  push_cast
  ring_nf

/-- The root sqrt-price in the gamma coordinate: `K_i^(1/2) = Γ_i^(-1/3)`. -/
theorem sqrtPrice_eq_gammaCoord (Δi : ℝ) (i : ℕ) :
    priceGrid Δi i ^ (1 / 2 : ℝ) = gammaCoord Δi i ^ (-(1 / 3) : ℝ) := by
  unfold gammaCoord gammaOfPrice
  rw [← Real.rpow_mul (priceGrid_pos Δi i).le]
  norm_num

/-- Inverting the coordinate recovers the tick (for `Δi ≠ 0`). -/
theorem tickOfGamma_gammaCoord (Δi : ℝ) (hΔ : Δi ≠ 0) (i : ℕ) :
    tickOfGamma Δi (gammaCoord Δi i) = i := by
  have hl : Real.log (xiStar Δi) ≠ 0 := by
    unfold xiStar
    rw [Real.log_rpow (by norm_num)]
    have : Real.log (1.0001 : ℝ) ≠ 0 := (Real.log_pos (by norm_num)).ne'
    intro h; rcases mul_eq_zero.1 h with h | h
    · exact hΔ (by linarith)
    · exact this h
  unfold tickOfGamma
  rw [gammaCoord_eq_pow, Real.log_pow]
  push_cast
  field_simp

/-- The coordinate is injective on ticks, so functions of the tick can be indexed by `Γ`. -/
theorem gammaCoord_injective (Δi : ℝ) (hΔ : Δi ≠ 0) : Function.Injective (gammaCoord Δi) := by
  intro i j h
  have := congrArg (tickOfGamma Δi) h
  rw [tickOfGamma_gammaCoord Δi hΔ, tickOfGamma_gammaCoord Δi hΔ] at this
  exact_mod_cast this

/-! ## `L(Γ)`: liquidity indexed by the gamma coordinate -/

/-- **Rung liquidity on the gamma coordinate.**  At `ξ*`, rung `i` holds
`L̄ ℓ(ξ*, ι; i) = 2 G(ι) Γ_i^(1/3)`. -/
theorem rungLiquidity_eq_onGamma (Lbar Δi : ℝ) (ι i : ℕ) :
    Lbar * geomWeight (xiStar Δi) ι i
      = ladderLiqOnGamma Lbar (xiStar Δi) ι (gammaCoord Δi i) := by
  unfold ladderLiqOnGamma gammaLevel geomWeight
  rw [gammaCoord_rpow_third]
  ring

/-- **Dollar gamma on the gamma coordinate.**  For any base `ξ`, the dollar gamma of rung
`i` is `-½ L Γ_i^(-1/3)`, with `L` the rung liquidity. -/
theorem rungDollarGamma_onGamma (Lbar ξ Δi : ℝ) (ι i : ℕ) :
    rungDollarGamma Lbar ξ Δi ι i
      = -(1 / 2) * (Lbar * geomWeight ξ ι i) * gammaCoord Δi i ^ (-(1 / 3) : ℝ) := by
  rw [rungDollarGamma, sqrtPrice_eq_gammaCoord]

/-- At `ξ*`, `-½ L(Γ) Γ^(-1/3) = -G(ι)` for every rung. -/
theorem dollarGamma_onGamma (Lbar Δi : ℝ) (ι i : ℕ) :
    -(1 / 2) * ladderLiqOnGamma Lbar (xiStar Δi) ι (gammaCoord Δi i)
        * gammaCoord Δi i ^ (-(1 / 3) : ℝ)
      = -gammaLevel Lbar (xiStar Δi) ι := by
  rw [← rungLiquidity_eq_onGamma, ← rungDollarGamma_onGamma, rungDollarGamma_flat]

/-- **Characterization of flat dollar gamma.**  For any per-rung liquidities `ℓ`, every
rung of a ladder of `ι` rungs has dollar gamma `-½ ℓ_i K_i^(1/2) = -g` iff
`ℓ_i = 2 g Γ_i^(1/3)` on every rung. -/
theorem flat_iff_onGamma (ℓ : ℕ → ℝ) (g Δi : ℝ) (ι : ℕ) :
    (∀ i < ι, -(1 / 2) * ℓ i * priceGrid Δi i ^ (1 / 2 : ℝ) = -g) ↔
      (∀ i < ι, ℓ i = 2 * g * gammaCoord Δi i ^ (1 / 3 : ℝ)) := by
  have key : ∀ i : ℕ, priceGrid Δi i ^ (1 / 2 : ℝ) * gammaCoord Δi i ^ (1 / 3 : ℝ) = 1 := by
    intro i
    rw [sqrtPrice_eq_gammaCoord, ← Real.rpow_add (gammaCoord_pos Δi i)]
    norm_num
  have hp : ∀ i : ℕ, 0 < priceGrid Δi i ^ (1 / 2 : ℝ) :=
    fun i => Real.rpow_pos_of_pos (priceGrid_pos Δi i) _
  refine forall₂_congr fun i _ => ?_
  constructor
  · intro h
    have h2 : ℓ i * priceGrid Δi i ^ (1 / 2 : ℝ) = 2 * g := by linarith
    calc ℓ i = ℓ i * (priceGrid Δi i ^ (1 / 2 : ℝ) * gammaCoord Δi i ^ (1 / 3 : ℝ)) := by
          rw [key, mul_one]
      _ = 2 * g * gammaCoord Δi i ^ (1 / 3 : ℝ) := by rw [← mul_assoc, h2]
  · intro h
    rw [h]
    linear_combination (-g) * key i

/-! ## `ι(Γ)`: the resolution read on the gamma coordinate -/

/-- The resolution is the tick of the end coordinate `Γ_ι = (ξ*)^(3ι)`. -/
theorem iota_eq_tickOfGamma (Δi : ℝ) (hΔ : Δi ≠ 0) (ι : ℕ) :
    (ι : ℝ) = tickOfGamma Δi (gammaCoord Δi ι) :=
  (tickOfGamma_gammaCoord Δi hΔ ι).symm

/-- The case `ι = 1`: `Γ_1 = (ξ*)³`. -/
theorem endCoord_one (Δi : ℝ) : gammaCoord Δi 1 = xiStar Δi ^ 3 := by
  rw [gammaCoord_eq_pow]

/-- The gamma level written in the end coordinate:
`G(ι) = (L̄/2)(1 - ξ*)/(1 - Γ_ι^(1/3))`. -/
theorem gammaLevel_onGamma (Lbar Δi : ℝ) (ι : ℕ) :
    gammaLevel Lbar (xiStar Δi) ι
      = Lbar / 2 * ((1 - xiStar Δi) / (1 - gammaCoord Δi ι ^ (1 / 3 : ℝ))) := by
  rw [gammaCoord_rpow_third, gammaLevel]

/-- `Γ_ι = (ξ*^ι)³`, the form used to move between the two statements. -/
private lemma gammaCoord_eq_cube (Δi : ℝ) (ι : ℕ) :
    gammaCoord Δi ι = (xiStar Δi ^ ι) ^ 3 := by
  rw [gammaCoord_eq_pow, ← pow_mul, mul_comm]

/-- **A gamma level fixes the end coordinate.**
`G(ι) = g ↔ Γ_ι = (1 - L̄(1 - ξ*)/(2g))³`. -/
theorem gammaLevel_eq_iff_endCoord (Lbar Δi g : ℝ) (hΔ : 0 < Δi) (hg : 0 < g)
    (ι : ℕ) (hι : 1 ≤ ι) :
    gammaLevel Lbar (xiStar Δi) ι = g ↔
      gammaCoord Δi ι = (1 - Lbar * (1 - xiStar Δi) / (2 * g)) ^ 3 := by
  rw [gammaLevel_eq_iff Lbar _ g hg (xiStar_pos Δi) (xiStar_lt_one Δi hΔ) ι hι,
    gammaCoord_eq_cube]
  constructor
  · intro h; rw [h]
  · intro h
    exact (Odd.strictMono_pow (R := ℝ) (by decide : Odd 3)).injective h

/-- **A gamma floor bounds the end coordinate from below.**
`g ≤ G(ι) ↔ (1 - L̄(1 - ξ*)/(2g))³ ≤ Γ_ι`. -/
theorem gammaFloor_iff_endCoord (Lbar Δi g : ℝ) (hΔ : 0 < Δi) (hg : 0 < g)
    (ι : ℕ) (hι : 1 ≤ ι) :
    g ≤ gammaLevel Lbar (xiStar Δi) ι ↔
      (1 - Lbar * (1 - xiStar Δi) / (2 * g)) ^ 3 ≤ gammaCoord Δi ι := by
  rw [gammaLevel_ge_iff Lbar _ g hg (xiStar_pos Δi) (xiStar_lt_one Δi hΔ) ι hι,
    gammaCoord_eq_cube]
  exact (Odd.strictMono_pow (by decide : Odd 3)).le_iff_le.symm

/-- **One rung.**  At `ι = 1` the single rung sits at `Γ_0 = 1` and carries all of `L̄`. -/
theorem singleRung_onGamma (Lbar Δi : ℝ) (hΔ : 0 < Δi) :
    gammaCoord Δi 0 = 1 ∧ ladderLiqOnGamma Lbar (xiStar Δi) 1 (gammaCoord Δi 0) = Lbar := by
  have h1 : xiStar Δi ≠ 1 := (xiStar_lt_one Δi hΔ).ne
  refine ⟨by simp [gammaCoord_eq_pow], ?_⟩
  rw [ladderLiqOnGamma, gammaLevel_one Lbar _ h1, gammaCoord_rpow_third]
  ring

/-! ## The CFMM1 profile `L(q) = ℓ / (2 q^(3/2))` -/

/-- `L_CFMM1(q) = ½ ℓ Γ(q)` for `q > 0`. -/
theorem cfmmProfile_eq_gamma (ℓ q : ℝ) (hq : 0 < q) :
    cfmmProfile ℓ q = ℓ / 2 * gammaOfPrice q := by
  unfold cfmmProfile gammaOfPrice
  rw [Real.rpow_neg hq.le]
  field_simp

/-- **Rung dollar gamma is CFMM1's dollar-gamma density.**  For any base `ξ`,
`rungDollarGamma = -K_i² L_CFMM1(K_i)` with `ℓ` the rung liquidity. -/
theorem rungDollarGamma_eq_cfmm (Lbar ξ Δi : ℝ) (ι i : ℕ) :
    rungDollarGamma Lbar ξ Δi ι i
      = -(priceGrid Δi i ^ 2 * cfmmProfile (Lbar * geomWeight ξ ι i) (priceGrid Δi i)) := by
  have hK := priceGrid_pos Δi i
  have e : priceGrid Δi i ^ (3 / 2 : ℝ) = priceGrid Δi i * priceGrid Δi i ^ (1 / 2 : ℝ) := by
    rw [show (3 / 2 : ℝ) = 1 + 1 / 2 by norm_num, Real.rpow_add hK, Real.rpow_one]
  have hs : 0 < priceGrid Δi i ^ (1 / 2 : ℝ) := Real.rpow_pos_of_pos hK _
  unfold rungDollarGamma cfmmProfile
  have hsq : (priceGrid Δi i ^ (1 / 2 : ℝ)) ^ 2 = priceGrid Δi i := by
    rw [← Real.rpow_natCast, ← Real.rpow_mul hK.le]; norm_num
  rw [e]
  field_simp
  rw [hsq]

/-- On the ladder at `ξ*`: `K_i² L_CFMM1(K_i) = G(ι)` on every rung. -/
theorem cfmm_dollarGamma_ladder (Lbar Δi : ℝ) (ι i : ℕ) :
    priceGrid Δi i ^ 2 * cfmmProfile (Lbar * geomWeight (xiStar Δi) ι i) (priceGrid Δi i)
      = gammaLevel Lbar (xiStar Δi) ι := by
  have := rungDollarGamma_eq_cfmm Lbar (xiStar Δi) Δi ι i
  rw [rungDollarGamma_flat] at this
  linarith

/-- At `ι = 1` that common level is `L̄/2`: the factor `2` of `L(q) = ℓ/(2 q^(3/2))`. -/
theorem cfmm_dollarGamma_one (Lbar Δi : ℝ) (hΔ : 0 < Δi) :
    priceGrid Δi 0 ^ 2 * cfmmProfile (Lbar * geomWeight (xiStar Δi) 1 0) (priceGrid Δi 0)
      = Lbar / 2 := by
  rw [cfmm_dollarGamma_ladder, gammaLevel_one Lbar _ (xiStar_lt_one Δi hΔ).ne]

/-- The CFMM1 density of the ladder on the gamma coordinate:
`L_CFMM1(K_i) = G(ι) Γ_i^(4/3)`. -/
theorem cfmmProfile_ladder_onGamma (Lbar Δi : ℝ) (ι i : ℕ) :
    cfmmProfile (Lbar * geomWeight (xiStar Δi) ι i) (priceGrid Δi i)
      = gammaLevel Lbar (xiStar Δi) ι * gammaCoord Δi i ^ (4 / 3 : ℝ) := by
  have hK := priceGrid_pos Δi i
  have h := cfmm_dollarGamma_ladder Lbar Δi ι i
  have e : gammaCoord Δi i ^ (4 / 3 : ℝ) = (priceGrid Δi i ^ 2)⁻¹ := by
    unfold gammaCoord gammaOfPrice
    rw [← Real.rpow_mul hK.le, ← Real.rpow_natCast, ← Real.rpow_neg hK.le]
    norm_num
  rw [e, ← h]
  field_simp

end GammaIndexing

end
