/- copyright ACL @ MIdFF 2024 -/

import Mathlib.RingTheory.Ideal.QuotientOperations
import Mathlib.Algebra.Module.Submodule.RestrictScalars
import Mathlib.RingTheory.Ideal.Maps
import Mathlib.RingTheory.TensorProduct.Basic
import Mathlib.LinearAlgebra.TensorProduct.RightExactness

/-! # Augmentation ideals

This is tentative

probably the subalgebra / section should be data
rather than Prop valued existence statements

 -/

variable (R : Type*) [CommRing R]
    {A : Type*} [CommRing A] [Algebra R A] (J : Ideal A)

section restrictScalars

variable
    (A : Type*) [CommSemiring A]
    {R : Type*} [Ring R] [Algebra A R]
    {M : Type*} [AddCommGroup M] [Module A M] [Module R M] [IsScalarTower A R M]
    (M₁ M₂ : Submodule R M)

theorem Submodule.sup_restrictScalars :
   (M₁ ⊔ M₂).restrictScalars A = M₁.restrictScalars A ⊔ (M₂.restrictScalars A) := by
  apply Submodule.toAddSubmonoid_injective
  simp only [Submodule.toAddSubmonoid_restrictScalars, Submodule.sup_toAddSubmonoid]

theorem Submodule.codisjoint_restrictScalars_iff :
    Codisjoint (M₁.restrictScalars A) (M₂.restrictScalars A) ↔
      Codisjoint M₁ M₂ := by
  simp only [codisjoint_iff, ← Submodule.sup_restrictScalars, Submodule.restrictScalars_eq_top_iff]

theorem Submodule.disjoint_restrictScalars_iff :
    Disjoint (M₁.restrictScalars A) (M₂.restrictScalars A) ↔
      Disjoint M₁ M₂ := by
  simp only [Submodule.disjoint_def, Submodule.restrictScalars_mem]

theorem Submodule.isCompl_restrictScalars_iff  :
    IsCompl (M₁.restrictScalars A) (M₂.restrictScalars A) ↔ IsCompl M₁ M₂ := by
  simp only [isCompl_iff, Submodule.disjoint_restrictScalars_iff, Submodule.codisjoint_restrictScalars_iff]

theorem Subalgebra.toSubmodule_restrictScalars_eq
    {R : Type*} [CommSemiring R] [Algebra A R]
    {S : Type*} [CommSemiring S] [Algebra A S] [Algebra R S] [IsScalarTower A R S]
    (S' : Subalgebra R S) :
    Subalgebra.toSubmodule (Subalgebra.restrictScalars A S') = S'.toSubmodule.restrictScalars A :=
  rfl

end restrictScalars
namespace Ideal

open AlgHom RingHom Submodule Ideal.Quotient

open TensorProduct

/-- An ideal `J` of a commutative `R`-algebra `A` is an augmentation ideal
  if this ideal is a complement to `⊥ : Subalgebra R A` -/
def IsAugmentationₐ (R : Type*) [CommRing R]
    {A : Type*} [CommRing A] [Algebra R A] (J : Ideal A) : Prop :=
  IsCompl (Subalgebra.toSubmodule (⊥ : Subalgebra R A)) (J.restrictScalars R)

#check lTensor_exact
#check LinearMap.ker_comp_of_ker_eq_bot
#check LinearMap.range_comp

theorem _root_.LinearMap.ker_lTensor_of_linearProjOfIsCompl
    {M : Type*} [AddCommGroup M] [Module A M]
    {M₁ M₂ : Submodule A M} (hM : IsCompl M₁ M₂)
    (Q : Type*) [AddCommGroup Q] [Module A Q] :
    LinearMap.ker (LinearMap.lTensor Q (Submodule.linearProjOfIsCompl _ _ hM))
    = LinearMap.range (LinearMap.lTensor Q M₂.subtype) := by
  rw [← LinearMap.exact_iff]
  apply lTensor_exact
  simp only [LinearMap.exact_iff, Submodule.range_subtype, linearProjOfIsCompl_ker]
  simp only [← LinearMap.range_eq_top, Submodule.linearProjOfIsCompl_range]

theorem _root_.LinearMap.ker_baseChange_of_linearProjOfIsCompl
    {M : Type*} [AddCommGroup M] [Module A M]
    {M₁ M₂ : Submodule A M} (hM : IsCompl M₁ M₂)
    (R : Type*) [CommRing R] [Algebra A R] :
    LinearMap.ker (LinearMap.baseChange R (Submodule.linearProjOfIsCompl _ _ hM))
    = LinearMap.range (LinearMap.baseChange R M₂.subtype) := by
  simpa only [←LinearMap.exact_iff] using LinearMap.ker_lTensor_of_linearProjOfIsCompl hM R

theorem _root_.LinearMap.isCompl_lTensor
    {M : Type*} [AddCommGroup M] [Module A M]
    {M₁ M₂ : Submodule A M} (hM : IsCompl M₁ M₂)
    (Q : Type*) [AddCommGroup Q] [Module A Q] :
    IsCompl
      (LinearMap.range (LinearMap.lTensor Q M₁.subtype))
      (LinearMap.range (LinearMap.lTensor Q M₂.subtype)) := by
  have hq :
    M₁.subtype.comp (Submodule.linearProjOfIsCompl _ _ hM)
      + M₂.subtype.comp (Submodule.linearProjOfIsCompl _ _ hM.symm) = LinearMap.id := by
    ext x
    simp only [LinearMap.add_apply, LinearMap.coe_comp, coeSubtype, Function.comp_apply,
      LinearMap.id_coe, id_eq]
    rw [Submodule.linear_proj_add_linearProjOfIsCompl_eq_self]
  apply IsCompl.mk
  · rw [Submodule.disjoint_def]
    intro x h h'
    rw [← LinearMap.id_apply x (R := A), ← LinearMap.lTensor_id, ← hq]
    simp only [LinearMap.lTensor_add, LinearMap.lTensor_comp,
      LinearMap.add_apply, LinearMap.coe_comp, Function.comp_apply]
    rw [← LinearMap.ker_lTensor_of_linearProjOfIsCompl hM Q] at h'
    rw [← LinearMap.ker_lTensor_of_linearProjOfIsCompl hM.symm Q] at h
    rw [LinearMap.mem_ker] at h h'
    simp only [h', _root_.map_zero, h, add_zero]
  · rw [codisjoint_iff]
    rw [eq_top_iff]
    intro x _
    rw [← LinearMap.lTensor_id_apply Q _ x, ← hq]
    simp only [LinearMap.lTensor_add, LinearMap.lTensor_comp,
      LinearMap.add_apply, LinearMap.coe_comp, Function.comp_apply]
    exact Submodule.add_mem _
      (Submodule.mem_sup_left (LinearMap.mem_range_self _ _))
      (Submodule.mem_sup_right (LinearMap.mem_range_self _ _))

theorem _root_.LinearMap.isCompl_baseChange
    {M : Type*} [AddCommGroup M] [Module A M]
    {M₁ M₂ : Submodule A M} (hM : IsCompl M₁ M₂)
    (R : Type*) [CommRing R] [Algebra A R] :
    IsCompl
      (LinearMap.range (LinearMap.baseChange R M₁.subtype))
      (LinearMap.range (LinearMap.baseChange R M₂.subtype)) := by
  rw [← Submodule.isCompl_restrictScalars_iff A]
  exact _root_.LinearMap.isCompl_lTensor hM R

/-- The base change of an algebra with an augmentation ideal -/
theorem _root_.Algebra.TensorProduct.isCompl_baseChange
    {R : Type*} [CommRing R] [Algebra A R]
    {S : Type*} [CommRing S] [Algebra A S]
    {I : Ideal S}
    (hI : IsCompl (Subalgebra.toSubmodule (⊥ : Subalgebra A S)) (I.restrictScalars A)) :
    IsCompl
      (Subalgebra.toSubmodule ((⊥ : Subalgebra R (R ⊗[A] S)).restrictScalars A))
      (Submodule.restrictScalars A (Ideal.map Algebra.TensorProduct.includeRight I)) := by
  have : Submodule.restrictScalars A (Ideal.map Algebra.TensorProduct.includeRight I)
    = Submodule.restrictScalars A
      (Submodule.restrictScalars R
        (Ideal.map Algebra.TensorProduct.includeRight I : Ideal (R ⊗[A] S)) : Submodule R (R ⊗[A] S)) := rfl
  rw [Subalgebra.toSubmodule_restrictScalars_eq, this,
    Submodule.isCompl_restrictScalars_iff]
  convert LinearMap.isCompl_baseChange hI R
  · ext x
    simp only [Subalgebra.mem_toSubmodule, Algebra.mem_bot]
    simp only [Set.mem_range, LinearMap.mem_range]
    constructor
    · rintro ⟨y, rfl⟩
      have : 1 ∈ (1 : Submodule A S) := by
        simp only [Submodule.mem_one]
        use 1
        rw [_root_.map_one]
      use y ⊗ₜ[A] ⟨1, this⟩
      rfl
    · rintro ⟨y, rfl⟩
      induction y using TensorProduct.induction_on with
      | zero =>
        use 0
        simp only [TensorProduct.zero_tmul, LinearMap.map_zero]
        simp
      | tmul r s =>
        rcases s with ⟨s, hs⟩
        simp only [Subalgebra.mem_toSubmodule] at hs
        obtain ⟨a, rfl⟩ := hs
        use a • r
        simp only [Algebra.TensorProduct.algebraMap_apply, Algebra.id.map_eq_id, RingHom.id_apply,
          toRingHom_eq_coe, coe_coe, LinearMap.baseChange_tmul, coeSubtype]
        simp only [TensorProduct.smul_tmul]
        rw [Algebra.ofId_apply, Algebra.algebraMap_eq_smul_one]
      | add x y hx hy =>
        obtain ⟨x', hx⟩ := hx
        obtain ⟨y', hy⟩ := hy
        use x' + y'
        simp only [TensorProduct.add_tmul, hx, hy, map_add]
  · ext x
    simp only [Submodule.restrictScalars_mem, LinearMap.mem_range]
    constructor
    · intro hx
      apply Submodule.span_induction hx (p := fun x ↦ ∃ y, (LinearMap.baseChange R (Submodule.subtype (Submodule.restrictScalars A I))) y = x )
      · rintro x ⟨s, hs, rfl⟩; use 1 ⊗ₜ[A] ⟨s, hs⟩; rfl
      · use 0; simp only [_root_.map_zero]
      · rintro _ _ ⟨x, rfl⟩ ⟨y, rfl⟩; use x + y; simp only [map_add]
      · rintro a _ ⟨x, rfl⟩
        induction x using TensorProduct.induction_on with
        | zero => use 0; simp only [_root_.map_zero, smul_eq_mul, mul_zero]
        | tmul r s =>
          induction a using TensorProduct.induction_on with
          | zero =>
            use 0
            simp only [_root_.map_zero, LinearMap.baseChange_tmul,
              Submodule.coeSubtype, smul_eq_mul, zero_mul]
          | tmul u v =>
            use (u * r) ⊗ₜ[A] (v • s)
            simp only [LinearMap.baseChange_tmul, Submodule.coeSubtype, smul_eq_mul,
              Algebra.TensorProduct.tmul_mul_tmul]
            rw [Submodule.coe_smul, smul_eq_mul]
          | add u v hu hv =>
            obtain ⟨x, hx⟩ := hu
            obtain ⟨y, hy⟩ := hv
            use x + y
            rw [LinearMap.map_add, add_smul, hx, hy]
        | add x y hx hy =>
          obtain ⟨x', hx⟩ := hx
          obtain ⟨y', hy⟩ := hy
          use x' + y'
          simp only [map_add, hx, smul_eq_mul, hy, mul_add]
    · rintro ⟨y, rfl⟩
      induction y using TensorProduct.induction_on with
      | zero => simp only [_root_.map_zero, Submodule.zero_mem]
      | tmul r s =>
        rcases s with ⟨s, hs⟩
        simp only [restrictScalars_mem] at hs
        simp only [LinearMap.baseChange_tmul, coeSubtype]
        rw [← mul_one r, ← smul_eq_mul, ← TensorProduct.smul_tmul']
        rw [← IsScalarTower.algebraMap_smul (R ⊗[A] S) r, smul_eq_mul]
        apply Ideal.mul_mem_left
        exact Ideal.mem_map_of_mem Algebra.TensorProduct.includeRight hs
      | add x y hx hy =>
        simp only [map_add]
        exact Ideal.add_mem _ hx hy

/-- If J is an `R`-algebra augmentation ideal, then S ⊗[R] J
  is a `S`-algebra augmentation ideal -/
theorem IsAugmentationₐ.baseChange
    (hJ : J.IsAugmentationₐ R)
    (S : Type*) [CommRing S] [Algebra R S] [Algebra A S] [IsScalarTower R A S] :
    Ideal.IsAugmentationₐ S (J.map Algebra.TensorProduct.includeRight : Ideal (S ⊗[R] A)) := by
  let f : A ⧸ J →ₐ[R] A := sorry
  have that : RingHom.ker (mkₐ R J) = J := mkₐ_ker R J
  let g : S ⊗[R] A ⧸ (Ideal.map Algebra.TensorProduct.includeRight J : Ideal (S ⊗[R] A)) →ₐ[S] S ⊗[R] (A ⧸ J) := {
    toRingHom := by
      apply Quotient.lift (Ideal.map Algebra.TensorProduct.includeRight J)
        ((Algebra.TensorProduct.map (AlgHom.id R S) (mkₐ R J)))
      intro a ha
      rwa [← that, ← Algebra.TensorProduct.lTensor_ker _ (mkₐ_surjective R J), mem_ker] at ha
    commutes' := fun s ↦ by
      have : algebraMap S ((S ⊗[R] A) ⧸ (map Algebra.TensorProduct.includeRight J : Ideal (S ⊗[R] A))) s = mkₐ S _ (s ⊗ₜ[R] 1) := by
        rw [mkₐ_eq_mk, ← mk_algebraMap, Algebra.TensorProduct.algebraMap_apply,
          Algebra.id.map_eq_self]
      simp [this] }
  -- let g := Ideal.kerLiftAlg (Algebra.TensorProduct.map (AlgHom.id A S) (mkₐ A I))
  -- rw [Algebra.TensorProduct.lTensor_ker _ (mkₐ_surjective A I), that] at g
  -- it seems unusable
  let g' : S ⊗[R] (A ⧸ J) →ₐ[S] S ⊗[R] A := Algebra.TensorProduct.map (AlgHom.id S S) f
  use g'.comp g
  intro x
  rcases mkₐ_surjective A _ x with ⟨x, rfl⟩
  simp only [mkₐ_eq_mk, AlgHom.coe_mk, coe_coe, AlgHom.coe_comp, Function.comp_apply, liftₐ_apply,
    Quotient.lift_mk, g]
  induction x using TensorProduct.induction_on with
  | zero => simp only [_root_.map_zero]
  | tmul s r =>
    simp only [Algebra.TensorProduct.map_tmul, AlgHom.coe_id, id_eq, mkₐ_eq_mk, g'] --  hf r]
    rw [Ideal.Quotient.mk_eq_mk_iff_sub_mem, ← TensorProduct.tmul_sub]
    rw [← mul_one s, ← smul_eq_mul, ← TensorProduct.smul_tmul']
    rw [← algebraMap_smul (S ⊗[R] A), smul_eq_mul]
    apply Ideal.mul_mem_left
    apply Ideal.mem_map_of_mem (Algebra.TensorProduct.includeRight)
    rw [← Ideal.Quotient.mk_eq_mk_iff_sub_mem]
    apply hf
  | add x y hx hy => simp only [map_add, hx, hy]

#exit
-- OLD VERSION
/-- An ideal J of a commutative ring A is an augmentation ideal
if `Ideal.Quotient.mk J` has a right inverse which is a `RingHom` -/
def IsAugmentation : Prop :=
  ∃ g : A ⧸ J →+* A, Function.RightInverse g (Ideal.Quotient.mk J)

/-- An ideal `J` of a commutative `R`-algebra `A` is an augmentation ideal
if `Ideal.Quotient.mkₐ R J` has a right inverse which is an `AlgHom` -/
def IsAugmentationₐ (R : Type*) [CommRing R]
    {A : Type*} [CommRing A] [Algebra R A] (J : Ideal A) : Prop :=
  ∃ g : A ⧸ J →ₐ[R] A, Function.RightInverse g (Ideal.Quotient.mkₐ R J)

theorem isAugmentationₐ_iff :
    J.IsAugmentationₐ R ↔
    ∃ (A₀ : Subalgebra R A), IsCompl (Subalgebra.toSubmodule A₀) (Submodule.restrictScalars R J) := by
  constructor
  · rintro ⟨f, hf⟩
    use f.range
    apply IsCompl.mk
    · rw [Submodule.disjoint_def]
      rintro x ⟨y, rfl⟩
      simp only [toRingHom_eq_coe, coe_coe, restrictScalars_mem]
      intro hy
      rw [← hf y, mkₐ_eq_mk]
      convert AlgHom.map_zero _
      rw [← mem_ker, mk_ker]
      exact hy
    · rw [codisjoint_iff, eq_top_iff]
      intro x _
      have : x = f (mkₐ R J x) + (x - f (mkₐ R J x)) := by ring
      rw [this]
      apply Submodule.add_mem
      · apply Submodule.mem_sup_left
        simp only [Subalgebra.mem_toSubmodule, AlgHom.mem_range, exists_apply_eq_apply]
      · apply Submodule.mem_sup_right
        simp only [Submodule.restrictScalars_mem]
        suffices x - f x ∈ ker (mkₐ R J) by
          convert this
          exact mk_ker.symm
        rw [mem_ker, map_sub, ← mkₐ_eq_mk R, hf, sub_self]
  · rintro ⟨A₀, ⟨hd, hc⟩⟩
    let u : A₀ →ₐ[R] A ⧸ J := (Ideal.Quotient.mkₐ R J).comp (Subalgebra.val A₀)
    suffices hu : Function.Bijective u by
      let u' : A₀ ≃ₐ[R] A ⧸ J := AlgEquiv.ofBijective u hu
      use (Subalgebra.val A₀).comp u'.symm
      rintro x
      rcases hu.surjective x with ⟨y, rfl⟩
      simp only [AlgHom.coe_comp, Subalgebra.coe_val, AlgHom.coe_coe, Function.comp_apply]
      -- Something like AlgEquiv.symm_apply_eq is missing
      suffices u y = u' y by
        rw [this]
        rw [AlgEquiv.leftInverse_symm]
        simp only [AlgEquiv.coe_ofBijective, AlgHom.coe_comp, mkₐ_eq_mk, Subalgebra.coe_val,
          Function.comp_apply, u', u]
      simp only [AlgEquiv.coe_ofBijective, u']
    constructor
    · rw [RingHom.injective_iff_ker_eq_bot, eq_bot_iff]
      intro x
      simp only [RingHom.mem_ker, mem_bot]
      simp only [Submodule.disjoint_def] at hd
      specialize hd x x.property
      simp only [Submodule.restrictScalars_mem, ZeroMemClass.coe_eq_zero] at hd
      intro hx
      apply hd
      simpa only [AlgHom.coe_comp, mkₐ_eq_mk, Subalgebra.coe_val, Function.comp_apply, u, ← RingHom.mem_ker, mk_ker] using hx
    · -- missing RingHomClass argument for RingHom.range_top_iff_surjective
      intro x
      rcases Ideal.Quotient.mk_surjective x with ⟨x, rfl⟩
      simp only [codisjoint_iff, eq_top_iff] at hc
      obtain ⟨x, hx, y, hy, rfl⟩ := Submodule.mem_sup.mp (hc (show x ∈ ⊤ by exact trivial))
      use ⟨x, hx⟩
      rw [map_add]
      convert (add_zero _).symm
      rwa [← RingHom.mem_ker, mk_ker]

/-- If J is an `R`-algebra augmentation ideal, then S ⊗[R] J
  is a `S`-algebra augmentation ideal -/
theorem IsAugmentationₐ.baseChange
    (hJ : J.IsAugmentationₐ R)
    (S : Type*) [CommRing S] [Algebra R S] [Algebra A S] [IsScalarTower R A S] :
    Ideal.IsAugmentationₐ S (J.map Algebra.TensorProduct.includeRight : Ideal (S ⊗[R] A)) := by
  obtain ⟨f, hf⟩ := hJ
  have that : RingHom.ker (mkₐ R J) = J := mkₐ_ker R J
  let g : S ⊗[R] A ⧸ (Ideal.map Algebra.TensorProduct.includeRight J : Ideal (S ⊗[R] A)) →ₐ[S] S ⊗[R] (A ⧸ J) := {
    toRingHom := by
      apply Quotient.lift (Ideal.map Algebra.TensorProduct.includeRight J)
        ((Algebra.TensorProduct.map (AlgHom.id R S) (mkₐ R J)))
      intro a ha
      rwa [← that, ← Algebra.TensorProduct.lTensor_ker _ (mkₐ_surjective R J), mem_ker] at ha
    commutes' := fun s ↦ by
      have : algebraMap S ((S ⊗[R] A) ⧸ (map Algebra.TensorProduct.includeRight J : Ideal (S ⊗[R] A))) s = mkₐ S _ (s ⊗ₜ[R] 1) := by
        rw [mkₐ_eq_mk, ← mk_algebraMap, Algebra.TensorProduct.algebraMap_apply,
          Algebra.id.map_eq_self]
      simp [this] }
  -- let g := Ideal.kerLiftAlg (Algebra.TensorProduct.map (AlgHom.id A S) (mkₐ A I))
  -- rw [Algebra.TensorProduct.lTensor_ker _ (mkₐ_surjective A I), that] at g
  -- it seems unusable
  let g' : S ⊗[R] (A ⧸ J) →ₐ[S] S ⊗[R] A := Algebra.TensorProduct.map (AlgHom.id S S) f
  use g'.comp g
  intro x
  rcases mkₐ_surjective A _ x with ⟨x, rfl⟩
  simp only [mkₐ_eq_mk, AlgHom.coe_mk, coe_coe, AlgHom.coe_comp, Function.comp_apply, liftₐ_apply,
    Quotient.lift_mk, g]
  induction x using TensorProduct.induction_on with
  | zero => simp only [_root_.map_zero]
  | tmul s r =>
    simp only [Algebra.TensorProduct.map_tmul, AlgHom.coe_id, id_eq, mkₐ_eq_mk, g'] --  hf r]
    rw [Ideal.Quotient.mk_eq_mk_iff_sub_mem, ← TensorProduct.tmul_sub]
    rw [← mul_one s, ← smul_eq_mul, ← TensorProduct.smul_tmul']
    rw [← algebraMap_smul (S ⊗[R] A), smul_eq_mul]
    apply Ideal.mul_mem_left
    apply Ideal.mem_map_of_mem (Algebra.TensorProduct.includeRight)
    rw [← Ideal.Quotient.mk_eq_mk_iff_sub_mem]
    apply hf
  | add x y hx hy => simp only [map_add, hx, hy]
