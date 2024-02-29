
import DividedPowers.ForMathlib.Topology.LinearTopology
import DividedPowers.ForMathlib.MvPowerSeries.Topology

--import Mathlib.Control.Ulift

open Set SetLike

variable (σ : Type*)

namespace MvPowerSeries

section Ideals

variable (α : Type*) [CommRing α]

set_option linter.uppercaseLean3 false

-- We need the same for Polynomial, MvPolynomial…
-- Suggestion : define a Ideal.IsBasis topology on α defined by a
-- family of “monomials” : (MonoidHom M α) where M is a monoid
-- and apply that to (monomial _ 1)
-- or even : a family of principal ideals
-- or even : a family in α
-- or :
def basis' : (σ →₀ ℕ) → Ideal (MvPowerSeries σ α) := fun d =>
  Ideal.span {MvPowerSeries.monomial α d 1}

/-- The underlying family for the `Ideal.IsBasis` in a multivariate power series ring. -/
def basis : (σ →₀ ℕ) → Ideal (MvPowerSeries σ α) := fun d =>
  { carrier   := {f | ∀ e ≤ d, coeff α e f = 0} -- monomial e 1 ∣ f
    zero_mem' := fun e _ => by rw [coeff_zero]
    add_mem'  := fun hf hg e he => by
      rw [map_add, hf e he, hg e he, add_zero]
    smul_mem' := fun f g hg e he => by
      classical
      rw [smul_eq_mul, coeff_mul]
      apply Finset.sum_eq_zero
      rintro uv huv
      convert MulZeroClass.mul_zero (coeff α uv.fst f)
      exact hg  _ (le_trans (le_iff_exists_add'.mpr
        ⟨uv.fst, (Finset.mem_antidiagonal.mp huv).symm⟩) he) }
#align mv_power_series.J MvPowerSeries.basis

/-- A power series `f` belongs to the ideal `basis σ α d` if and only if `coeff α e f = 0` for all
  `e ≤ d`.  -/
theorem mem_basis (f : MvPowerSeries σ α) (d : σ →₀ ℕ) :
    f ∈ basis σ α d ↔ ∀ e ≤ d, coeff α e f = 0 := by
  simp only [basis, Submodule.mem_mk, AddSubmonoid.mem_mk, Set.mem_setOf_eq]
  rfl
#align mv_power_series.mem_J MvPowerSeries.mem_basis

/-- If `e ≤ d`, then we have the inclusion of ideals `basis σ α d ≤ basis σ α e`. -/
theorem basis_le {e d : σ →₀ ℕ} (hed : e ≤ d) : basis σ α d ≤ basis σ α e :=
  fun _ => forall_imp (fun _ h ha => h (le_trans ha hed))
#align mv_power_series.J_le MvPowerSeries.basis_le

/-- `basis σ α d ≤ basis σ α e` if and only if `e ≤ d`.-/
theorem basis_le_iff [Nontrivial α] (d e : σ →₀ ℕ) :
    basis σ α d ≤ basis σ α e ↔ e ≤ d := by
  refine' ⟨_, basis_le _ _⟩
  simp only [basis, Submodule.mk_le_mk, AddSubmonoid.mk_le_mk, setOf_subset_setOf]
  intro h
  rw [← inf_eq_right]
  apply le_antisymm
  . exact inf_le_right
  . by_contra h'
    simp only [AddSubsemigroup.mk_le_mk, setOf_subset_setOf] at h
    specialize h (monomial α e 1) _
    . intro e' he'
      apply coeff_monomial_ne
      intro hee'
      rw [hee'] at he'
      apply h'
      exact le_inf_iff.mpr ⟨he', le_rfl⟩
    apply one_ne_zero' α
    convert h e le_rfl
    rw [coeff_monomial_same]
#align mv_power_series.J_le_iff MvPowerSeries.basis_le_iff

/-- The function `basis σ α` is antitone. -/
theorem basis_antitone : Antitone (basis σ α) := fun _ _ h => basis_le σ α h
#align mv_power_series.J_antitone MvPowerSeries.basis_antitone

-- TODO : generalize to [Ring α]
/-- `MvPowerSeries.basis` is an `Ideal.IsBasis`. -/
theorem idealIsBasis : Ideal.IsBasis (basis σ α) :=
  Ideal.IsBasis.ofComm fun d e => by use d ⊔ e; apply Antitone.map_sup_le (basis_antitone σ α)
#align mv_power_series.ideals_basis MvPowerSeries.idealIsBasis

/-- `MvPowerSeries.basis` is a `RingSubgroupsBasis`. -/
theorem toRingSubgroupsBasis : RingSubgroupsBasis fun d => (basis σ α d).toAddSubgroup :=
  (idealIsBasis σ α).toRingSubgroupsBasis
#align mv_power_series.to_ring_subgroups_basis MvPowerSeries.toRingSubgroupsBasis

end Ideals

section DiscreteTopology

set_option linter.uppercaseLean3 false

variable (α : Type*) [CommRing α] [TopologicalSpace α]

/-- If the coefficient ring `α` is endowed with the discrete topology, then for every `d : σ →₀ ℕ`,
  `↑(basis σ α d) ∈ nhds (0 : MvPowerSeries σ α)`. -/
theorem basis_mem_nhds_zero [DiscreteTopology α] (d : σ →₀ ℕ) :
    ↑(basis σ α d) ∈ nhds (0 : MvPowerSeries σ α) := by
  classical
  rw [nhds_pi, Filter.mem_pi]
  use Finset.Iic d, Finset.finite_toSet _, (fun e => if e ≤ d then {0} else univ)
  constructor
  · intro e
    split_ifs with h
    . simp only [nhds_discrete, Filter.mem_pure, mem_singleton_iff]
      rfl
    . simp only [Filter.univ_mem]
  · intro f
    simp only [Finset.coe_Iic, mem_pi, mem_Iic, mem_ite_univ_right, mem_singleton_iff, mem_coe]
    exact forall_imp (fun e h he => h he he)
#align mv_power_series.J_mem_nhds_zero MvPowerSeries.basis_mem_nhds_zero


/-- If the coefficient ring `α` is endowed with the discrete topology, then the pointwise
  topology on `MvPowerSeries σ α)` agrees with the topology generated by `MvPowerSeries.basis`. -/
theorem topology_eq_ideals_basis_topology [DiscreteTopology α] :
    MvPowerSeries.topologicalSpace σ α = (idealIsBasis σ α).topology := by
  let τ := MvPowerSeries.topologicalSpace σ α
  let τ' := (toRingSubgroupsBasis σ α).topology
  rw [TopologicalSpace.eq_iff_nhds_eq]
  suffices ∀ s, s ∈ @nhds _ τ 0 ↔ s ∈ @nhds _ τ' 0 by
    let tg := @TopologicalRing.to_topologicalAddGroup _ _ τ ( topologicalRing σ α)
    intro s a _
    rw [← add_zero a, @mem_nhds_add_iff _ _ τ tg, mem_nhds_add_iff]
    apply this
  intro s
  rw [(RingSubgroupsBasis.hasBasis_nhds (toRingSubgroupsBasis σ α) 0).mem_iff]
  simp only [sub_zero, Submodule.mem_toAddSubgroup, exists_true_left, true_and]
  refine' ⟨_, fun ⟨d, hd⟩ => (@nhds _ τ 0).sets_of_superset (basis_mem_nhds_zero σ α d) hd⟩
  rw [nhds_pi, Filter.mem_pi]
  rintro ⟨D, hD, t, ht, ht'⟩
  use Finset.sup hD.toFinset id
  apply subset_trans _ ht'
  intro f hf e he
  rw [← coeff_eq_apply f e, hf e]
  exact mem_of_mem_nhds (ht e)
  . have he' : e ∈ (Finite.toFinset hD) := by
      simp only [id.def, Finite.mem_toFinset]
      exact he
    apply Finset.le_sup he'
#align mv_power_series.topology_eq_ideals_basis_topolgy MvPowerSeries.topology_eq_ideals_basis_topology

#check range

lemma isLinearTopology [DiscreteTopology α] :
    LinearTopology (MvPowerSeries σ α) := {
      Ideal.IsBasis.toIdealBasis (idealIsBasis _ _)    with
      isTopology := by rw [Ideal.IsBasis.ofIdealBasis_topology_eq,
        topology_eq_ideals_basis_topology σ α] }

lemma toSubmodulesBasis [DiscreteTopology α] : SubmodulesBasis (basis σ α) :=
  SubmodulesBasis.mk
    (λ d e => ⟨d + e, by
        rw [le_inf_iff]
        constructor
        · exact basis_antitone _ _ (le_self_add)
        · exact basis_antitone _ _ (le_add_self)⟩)
    (λ f d => by {
      rw [Filter.eventually_iff_exists_mem]
      use ↑(basis σ α d)
      apply And.intro (basis_mem_nhds_zero σ α d)
      intros g hg
      rw [smul_eq_mul, mul_comm]
      exact Ideal.mul_mem_left _ f (SetLike.mem_coe.mp hg)})

-- Proof ported from Lean 3
lemma has_submodules_basis_topology' [DiscreteTopology α] :
    MvPowerSeries.topologicalSpace σ α = (toSubmodulesBasis σ α).topology := by
  let τ := MvPowerSeries.topologicalSpace σ α
  let τ' := (toSubmodulesBasis σ α).topology
  rw [TopologicalSpace.eq_iff_nhds_eq]
  suffices ∀ s, s ∈ @nhds _ τ 0 ↔ s ∈ @nhds _ τ' 0 by
  -- mv nhds from 0 to a
    intros s a _ha -- _ha is never used
    rw [← add_zero a]
    letI tr := (topologicalRing σ α)
    rw [@mem_nhds_add_iff _ _ τ, mem_nhds_add_iff]
    exact this _
  -- neighborhoods of 0
  intro s
  rw [(RingSubgroupsBasis.hasBasis_nhds (toRingSubgroupsBasis σ α) 0).mem_iff]
  simp only [sub_zero, Submodule.mem_toAddSubgroup, exists_true_left]
  constructor
  { rw [nhds_pi, Filter.mem_pi]
    rintro ⟨D, hD, t, ht, ht'⟩
    use Finset.sup hD.toFinset id
    simp only [true_and]
    apply subset_trans _ ht'
    intros f hf
    rw [Set.mem_pi]
    intros e he
    change f ∈ basis σ α _ at hf
    rw [← coeff_eq_apply f e, hf e]
    exact mem_of_mem_nhds (ht e)
    rw [← id.def e]
    apply Finset.le_sup
    simp only [Set.Finite.mem_toFinset]
    exact he }
  { rintro ⟨d, _, hd⟩
    exact (@nhds _ τ 0).sets_of_superset  (basis_mem_nhds_zero σ α d) hd }

-- Alternative proof
lemma has_submodules_basis_topology [DiscreteTopology α] :
    MvPowerSeries.topologicalSpace σ α = (toSubmodulesBasis σ α).topology := by
  let τ := MvPowerSeries.topologicalSpace σ α
  let τ' := (toSubmodulesBasis σ α).topology
  rw [TopologicalSpace.eq_iff_nhds_eq_nhds]
  suffices ∀ s, s ∈ @nhds _ τ 0 ↔ s ∈ @nhds _ τ' 0 by
  -- mv nhds from 0 to a
    ext a s
    rw [← add_zero a]
    letI tr := (topologicalRing σ α)
    rw [@mem_nhds_add_iff _ _ τ, mem_nhds_add_iff]
    exact this _
  -- neighborhoods of 0
  intro s
  rw [(RingSubgroupsBasis.hasBasis_nhds (toRingSubgroupsBasis σ α) 0).mem_iff]
  simp only [sub_zero, Submodule.mem_toAddSubgroup, true_and]
  constructor
  · rw [nhds_pi, Filter.mem_pi]
    rintro ⟨D, hD, t, ht, ht'⟩
    use Finset.sup hD.toFinset id
    apply subset_trans _ ht'
    intros f hf e he
    --change f ∈ basis σ α _ at hf
    rw [← coeff_eq_apply f e, hf e]
    · exact mem_of_mem_nhds (ht e)
    · rw [← id.def e]
      exact Finset.le_sup ((Set.Finite.mem_toFinset _).mpr he)
  · rintro ⟨d, hd⟩
    exact (@nhds _ τ 0).sets_of_superset  (basis_mem_nhds_zero σ α d) hd


/- -- TODO : problèmes d'univers

lemma to_has_linear_topology [discrete_topology α] :
  has_linear_topology (mv_power_series σ α) :=
begin
  unfold has_linear_topology,
  sorry,
  refine ⟨σ →₀ ℕ, _,  _, _, _⟩,
  -- basis σ α, ideals_basis σ α,  topology_eq_ideals_basis_topolgy σ α ⟩,
  simp only [nonempty_of_inhabited],
  let h:= ulift.map (basis σ α),
  refine function.comp _ h,

end -/
/-

lemma to_submodules_basis [discrete_topology α] : submodules_basis (basis σ α) := submodules_basis.mk
  (λ d e, by {
    use d + e, rw le_inf_iff,
    split,
    apply basis_antitone, rw le_iff_exists_add, exact ⟨e, rfl⟩,
    apply basis_antitone, rw le_iff_exists_add', exact ⟨d, rfl⟩, })
  (λ f d, by { rw filter.eventually_iff_exists_mem,
    use ↑(basis σ α d), apply and.intro (basis_mem_nhds_zero σ α d),
    intros g hg,
    rw [smul_eq_mul, mul_comm],
    refine ideal.mul_mem_left _ f _,
    simpa only [set_like.mem_coe] using hg, } )

lemma has_submodules_basis_topology [discrete_topology α] : mv_power_series.topological_space σ α = (to_submodules_basis σ α).topology :=
begin
  let τ := mv_power_series.topological_space σ α,
  let τ' := (to_submodules_basis σ α).topology,
  suffices : τ = τ', exact this,
  rw topological_space_eq_iff_nhds_eq,
  suffices : ∀ s, s ∈ @nhds _ τ 0 ↔ s ∈ @nhds _ τ' 0,
  -- mv nhds from 0 to a
  { intros a s ha,
    rw ← add_zero a,
    haveI := (topological_ring σ α), rw mem_nhds_add_iff,
    rw mem_nhds_add_iff,
    apply this, },
  -- neighborhoods of 0
  intro s,
  rw (ring_subgroups_basis.has_basis_nhds (to_ring_subgroups_basis σ α) 0).mem_iff,
  simp only [sub_zero, submodule.mem_to_add_subgroup, exists_true_left],
  split,
  { rw nhds_pi, rw filter.mem_pi,
    rintro ⟨D, hD, t, ht, ht'⟩,
    use finset.sup hD.to_finset id,
    apply subset_trans _ ht',
    intros f hf,
    rw set.mem_pi, intros e he,
    change f ∈ basis σ α _ at hf,
    rw ← coeff_eq_apply f e, rw hf e,
    exact mem_of_mem_nhds (ht e),
    convert finset.le_sup _,
    simp only [id.def],
    simp only [set.finite.mem_to_finset], exact he, },
  { rintro ⟨d, hd⟩,
    exact (nhds 0).sets_of_superset (basis_mem_nhds_zero σ α d) hd,}
end
 -/

end DiscreteTopology

end MvPowerSeries
