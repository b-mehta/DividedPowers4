import DividedPowers.DPAlgebra.Init
import DividedPowers.DPAlgebra.Graded.GradeZero
import DividedPowers.RatAlgebra
import DividedPowers.SubDPIdeal
import DividedPowers.IdealAdd
import DividedPowers.DPAlgebra.RobyLemma9
import DividedPowers.DPAlgebra.PolynomialMap
import DividedPowers.ForMathlib.RingTheory.Ideal
import Mathlib.RingTheory.MvPolynomial.Basic
import Mathlib.LinearAlgebra.TensorProduct.RightExactness

/-! # Construction of divided powers of tensor products of divided power algebras

The two main constructions of this file are the following:

* Let `R`, `A`, `B` be commutative rings, with `Algebra R A` and `Algebra R B`.
Assume that `A` and `B` have divided power structures.
We construct the unique divided power structure on `A ⊗[R] B` so that
the canonical morphisms `A →ₐ[R] A ⊗[R] B` and `B →ₐ[R] A ⊗[R] B`
are dp-morphisms.

* Let `R` be a commutative ring, `M` an `R`-module.
We construct the unique divided power structure on `DividedPowerAlgebra R M`
for which `dpow n (DividedPower.linearEquivDegreeOne m) = dp n m` for any `m : M`,
where `linearEquivDegreeOne` is the `LinearEquiv`  from `M`
to the degree 1 part of `DividedPowerAlgebra R M`

## Reference

* [Roby1965]

## Construction

The construction is highly non trivial and relies on a complicated process.
The uniqueness is clear, what is difficult is to prove the relevant
functional equations.
The result is banal if `R` is a ℚ-algebra and the idea is to lift `M`
to a free module over a torsion-free algebra.
Then the functional equations would hold by embedding everything into
the tensorization by ℚ.
Lifting `R` is banal (take a polynomial ring with ℤ-coefficients),
but `M` does not lift in general,
so one first has to lift `M` to a free module.
The process requires to know several facts regarding the divided power algebra:
- its construction commutes with base change (`DividedPowerAlgebra.dpScalarEquiv`).
- The graded parts of the divided power algebra of a free module are free.

Incidentally, there is no other proof in the litterature than the
paper [Roby1965]. This formalization would be the second one.

-/
noncomputable section

universe u v v₁ v₂ w

section

variable (R : Type u) [CommRing R] [DecidableEq R]
  (M : Type v) [AddCommGroup M] [DecidableEq M] [Module R M]

variable (x : M) (n : ℕ)


open Finset MvPolynomial Ideal.Quotient

-- triv_sq_zero_ext
open Ideal

-- direct_sum
open RingQuot

namespace DividedPowerAlgebra

open DividedPowerAlgebra

/-- Lemma 2 of Roby 65. -/
theorem on_dp_algebra_unique (h h' : DividedPowers (augIdeal R M))
    (h1 : ∀ (n : ℕ) (x : M), h.dpow n (ι R M x) = dp R n x)
    (h1' : ∀ (n : ℕ) (x : M), h'.dpow n (ι R M x) = dp R n x) : h = h' := by
  apply DividedPowers.dp_uniqueness_self h' h (augIdeal_eq_span R M)
  rintro n f ⟨q, hq : 0 < q, m, _, rfl⟩
  nth_rw 1 [← h1' q m]
  rw [← h1 q m, h.dpow_comp n (ne_of_gt hq) (ι_mem_augIdeal R M m),
    h'.dpow_comp n (ne_of_gt hq) (ι_mem_augIdeal R M m), h1 _ m, h1' _ m]
#align divided_power_algebra.on_dp_algebra_unique DividedPowerAlgebra.on_dp_algebra_unique

def Condδ (R : Type u) [CommRing R] [DecidableEq R]
    (M : Type u) [AddCommGroup M] [Module R M] : Prop :=
  ∃ h : DividedPowers (augIdeal R M), ∀ (n : ℕ) (x : M), h.dpow n (ι R M x) = dp R n x
#align divided_power_algebra.cond_δ DividedPowerAlgebra.Condδ

-- Universe constraint : one needs to have M in universe u
set_option linter.uppercaseLean3 false
def CondD (R : Type u) [CommRing R] [DecidableEq R] : Prop :=
  ∀ (M : Type u) [AddCommGroup M], ∀ [Module R M], Condδ R M
#align divided_power_algebra.cond_D DividedPowerAlgebra.CondD

end DividedPowerAlgebra

end

section Roby

-- Formalization of Roby 1965, section 8
open Finset MvPolynomial Ideal.Quotient

-- triv_sq_zero_ext
open Ideal

-- direct_sum
open RingQuot

open DividedPowers

namespace DividedPowerAlgebra

open DividedPowerAlgebra

section TensorProduct

open scoped TensorProduct

variable (A : Type u) (R : Type u) (S : Type u) [CommRing A] [CommRing R] [Algebra A R] [CommRing S] [Algebra A S]
  {I : Ideal R} {J : Ideal S} (hI : DividedPowers I) (hJ : DividedPowers J)

def i1 : R →ₐ[A] R ⊗[A] S :=
  Algebra.TensorProduct.includeLeft
#align divided_power_algebra.i_1 DividedPowerAlgebra.i1

def i2 : S →ₐ[A] R ⊗[A] S :=
  Algebra.TensorProduct.includeRight
#align divided_power_algebra.i_2 DividedPowerAlgebra.i2

variable {R S} (I J)

set_option linter.uppercaseLean3 false
def K : Ideal (R ⊗[A] S) :=
  I.map (i1 A R S) ⊔ J.map (i2 A R S)
#align divided_power_algebra.K DividedPowerAlgebra.K

variable {I J}

-- Lemma 1 : uniqueness of the dp structure on R ⊗ S for I + J
theorem on_tensorProduct_unique (hK hK' : DividedPowers (K A I J))
    (hIK : isDPMorphism hI hK (i1 A R S)) (hIK' : isDPMorphism hI hK' (i1 A R S))
    (hJK : isDPMorphism hJ hK (i2 A R S)) (hJK' : isDPMorphism hJ hK' (i2 A R S)) :
    hK = hK' := by
  apply eq_of_eq_on_ideal
  intro n x hx
  suffices x ∈ dpEqualizer hK hK' by exact ((mem_dpEqualizer_iff _ _).mp this).2 n
  suffices h_ss : K A I J ≤ dpEqualizer hK hK' by
    exact h_ss hx
  dsimp only [K]
  rw [sup_le_iff]
  constructor
  apply le_equalizer_of_dp_morphism hI (i1 A R S).toRingHom le_sup_left hK hK' hIK hIK'
  apply le_equalizer_of_dp_morphism hJ (i2 A R S).toRingHom le_sup_right hK hK' hJK hJK'
#align divided_power_algebra.on_tensor_product_unique DividedPowerAlgebra.on_tensorProduct_unique

/-- Existence of divided powers on the ideal of a tensor product
  of two divided power algebras -/
def Condτ (A : Type u) [CommRing A]
    {R : Type u} [CommRing R] [Algebra A R] {I : Ideal R} (hI : DividedPowers I)
    {S : Type u} [CommRing S] [Algebra A S] {J : Ideal S} (hJ : DividedPowers J) : Prop :=
  ∃ hK : DividedPowers (K A I J),
    isDPMorphism hI hK (i1 A R S) ∧ isDPMorphism hJ hK (i2 A R S)
#align divided_power_algebra.cond_τ DividedPowerAlgebra.Condτ

/-- Existence of divided powers on the ideal of a tensor product
  of any two divided power algebras (universalization of `Condτ`)-/
def CondT (A : Type u) [CommRing A] : Prop :=
  ∀ (R : Type u) [CommRing R], ∀ [Algebra A R], ∀ {I : Ideal R} (hI : DividedPowers I),
  ∀ (S : Type u) [CommRing S], ∀ [Algebra A S], ∀ {J : Ideal S} (hJ : DividedPowers J),
  Condτ A hI hJ
#align divided_power_algebra.cond_T DividedPowerAlgebra.CondT

end TensorProduct

section free

set_option linter.uppercaseLean3 false
/-- Existence of divided powers on the canonical ideal
  of a tensor product of divided power algebras
  which are free as modules -/
def CondTFree (A : Type u) [CommRing A] : Prop :=
  ∀ (R : Type u) [CommRing R], ∀ [Algebra A R], ∀ (_ : Module.Free A R),
    ∀ {I : Ideal R} (hI : DividedPowers I),
  ∀ (S : Type u) [CommRing S], ∀ [Algebra A S], ∀ (_ : Module.Free A S),
    ∀ {J : Ideal S} (hJ : DividedPowers J),
  Condτ A hI hJ
#align divided_power_algebra.cond_T_free DividedPowerAlgebra.CondTFree

/-- Existence, for any algebra with divided powers,
  of an over-algebra with divided powers which is free as a module -/
def CondQ (A : Type u) [CommRing A] : Prop :=
  ∀ (R : Type u) [CommRing R], ∀ [Algebra A R] (I : Ideal R) (hI : DividedPowers I),
  ∃ (T : Type u) (_ : CommRing T), ∃ (_ : Algebra A T),
    ∃ (_ : Module.Free A T) (f : T →ₐ[A] R)
      (J : Ideal T) (hJ : DividedPowers J) (_ : isDPMorphism hJ hI f),
  I = J.map f ∧ Function.Surjective f
#align divided_power_algebra.cond_Q DividedPowerAlgebra.CondQ

end free

section Proofs

variable {R : Type u} [CommRing R]

open DividedPowerAlgebra

open scoped TensorProduct

-- Roby, lemma 3
set_option linter.uppercaseLean3 false
theorem cond_D_uniqueness [DecidableEq R]
    {M : Type v} [AddCommGroup M] [Module R M]
    (h : DividedPowers (augIdeal R M))
    (hh : ∀ (n : ℕ) (x : M), h.dpow n (ι R M x) = dp R n x)
    {S : Type*} [CommRing S] [Algebra R S] {J : Ideal S} (hJ : DividedPowers J)
    (f : M →ₗ[R] S) (hf : ∀ m, f m ∈ J) :
    isDPMorphism h hJ (DividedPowerAlgebra.lift hJ f hf) := by
  classical
  constructor
  · rw [augIdeal_eq_span]
    rw [Ideal.map_span]
    rw [Ideal.span_le]
    intro s
    rintro ⟨a, ⟨n, hn : 0 < n, m, _, rfl⟩, rfl⟩
    simp only [AlgHom.coe_toRingHom, SetLike.mem_coe]
    rw [liftAlgHom_apply_dp]
    apply hJ.dpow_mem (ne_of_gt hn) (hf m)
  · intro n a ha
    --    simp only [alg_hom.coe_to_ring_hom],
    apply symm
    rw [(dp_uniqueness h hJ (lift hJ f hf) (augIdeal_eq_span R M) _ _) n a ha]
    · rintro a ⟨q, hq : 0 < q, m, _, rfl⟩
      simp only [AlgHom.coe_toRingHom, liftAlgHom_apply_dp]
      exact hJ.dpow_mem (ne_of_gt hq) (hf m)
    · rintro n a ⟨q, hq : 0 < q, m, _, rfl⟩
      simp only [AlgHom.coe_toRingHom, liftAlgHom_apply_dp]
      rw [hJ.dpow_comp n (ne_of_gt hq) (hf m),← hh q m,
        h.dpow_comp n (ne_of_gt hq) (ι_mem_augIdeal R M m), _root_.map_mul, map_natCast]
      apply congr_arg₂ _ rfl
      rw [hh]; rw [liftAlgHom_apply_dp]
#align divided_power_algebra.cond_D_uniqueness DividedPowerAlgebra.cond_D_uniqueness

example {A R S : Type*} [CommSemiring A]
  [CommSemiring R] [Algebra A R]
  [Semiring S] [Algebra A S] [Algebra R S]
  [IsScalarTower A R S] :
  R →ₐ[A] S where
    toRingHom := algebraMap R S
    commutes' := fun r ↦ by
      simp [IsScalarTower.algebraMap_eq A R S]


namespace roby4

variable (A : Type u) [CommRing A] [DecidableEq A]

open Classical

/- The goal of this section is to establish [Roby1963, Lemme 4]
`T_free_and_D_to_Q`, that under the above assumptions, `CondQ A` holds.
It involves a lifting construction -/

variable (S : Type u) [CommRing S] [Algebra A S]
  {I : Ideal S} (hI : DividedPowers I)

-- We construct MvPolynomial S A = A[S] →ₐ[A] S
instance : Algebra (MvPolynomial S A) S :=
  RingHom.toAlgebra (MvPolynomial.aeval id).toRingHom

theorem algebraMap_eq :
    algebraMap (MvPolynomial S A) S = (MvPolynomial.aeval id).toRingHom :=
  RingHom.algebraMap_toAlgebra (algebraMap (MvPolynomial S A) S)

instance : IsScalarTower A (MvPolynomial S A) S := {
  smul_assoc := fun a r s => by
    simp only [Algebra.smul_def, algebraMap_eq]
    simp only [AlgHom.toRingHom_eq_coe, AlgHom.coe_toRingHom, _root_.map_mul, AlgHom.commutes]
    rw [← mul_assoc] }

variable {S} (I) in
def f : (I →₀ A) →ₗ[A] S :=
  (Basis.constr (Finsupp.basisSingleOne) A) (fun i ↦ (i : S))

variable {S} (I) in
theorem f_mem_I (p) : f A I p ∈ I := by
  suffices LinearMap.range (f A I) ≤ Submodule.restrictScalars A I by
    apply this
    simp only [LinearMap.mem_range, exists_apply_eq_apply]
  simp only [f, Basis.constr_range, Submodule.span_le]
  rintro _ ⟨i, rfl⟩
  simp only [Submodule.coe_restrictScalars, SetLike.mem_coe, SetLike.coe_mem]

variable  (condTFree : CondTFree A) (condD : CondD A)

variable (hM : DividedPowers (augIdeal A (I →₀ A)))
  (hM_eq : ∀ n x, hM.dpow n ((ι A (I →₀ A)) x) = dp A n x)

instance hdpM_free : Module.Free A (DividedPowerAlgebra A (I →₀ A)) :=
  DividedPowerAlgebra.toModule_free _ _

instance hR_free : Module.Free A (MvPolynomial S A) :=
  Module.Free.of_basis (MvPolynomial.basisMonomials _ _)

def hR := dividedPowersBot (MvPolynomial S A)

variable (I) in
theorem condτ : Condτ A (dividedPowersBot (MvPolynomial S A)) hM := by
  apply condTFree
  infer_instance
  infer_instance

def Φ : DividedPowerAlgebra A (I →₀ A) →ₐ[A] S :=
  DividedPowerAlgebra.lift hI (f A I) (f_mem_I _ _)

def dpΦ : dpMorphism hM hI := by
  apply dpMorphismFromGens hM hI (augIdeal_eq_span _ _) (f := (Φ A S hI).toRingHom)
  · rw [Ideal.map_le_iff_le_comap, augIdeal_eq_span, span_le]
    rintro x ⟨n, hn, b, _, rfl⟩
    simp only [Set.mem_setOf_eq] at hn
    simp only [AlgHom.toRingHom_eq_coe, SetLike.mem_coe, mem_comap, RingHom.coe_coe]
    simp only [Φ, liftAlgHom_apply_dp]
    exact hI.dpow_mem (ne_of_gt hn) (f_mem_I A I b)
  · rintro n x ⟨m, hm, b, _, rfl⟩
    simp only [Set.mem_setOf_eq] at hm
    simp only [Φ, AlgHom.toRingHom_eq_coe, RingHom.coe_coe, liftAlgHom_apply_dp]
    rw [← hM_eq, hM.dpow_comp, hI.dpow_comp]
    simp only [_root_.map_mul, map_natCast]
    apply congr_arg₂ _ rfl
    rw [hM_eq, liftAlgHom_apply_dp]
    exact ne_of_gt hm
    exact f_mem_I A I b
    exact ne_of_gt hm
    apply ι_mem_augIdeal

-- We consider `R ⊗[A] DividedPowerAlgebra A (I →₀ A)`
def Ψ := Algebra.TensorProduct.productMap
  (IsScalarTower.toAlgHom A (MvPolynomial S A) S)
  (Φ A S hI)

theorem Ψ_surjective : Function.Surjective (Ψ A S hI) := by
  rw [← Algebra.range_top_iff_surjective _, eq_top_iff]
  intro s _
  simp only [AlgHom.mem_range]
  use (X s) ⊗ₜ[A] 1
  simp only [Ψ, Algebra.TensorProduct.productMap_apply_tmul, IsScalarTower.coe_toAlgHom',
    algebraMap_eq, AlgHom.toRingHom_eq_coe, RingHom.coe_coe, aeval_X, id_eq, map_one, mul_one]

variable (I) in
theorem K_eq_span : K A (⊥ : Ideal (MvPolynomial S A)) (augIdeal A (↥I →₀ A))
  = span (Set.image2 (fun n a ↦ 1 ⊗ₜ[A] dp A n a) {n | 0 < n} Set.univ) := by
  simp [K, i1, i2]
  rw [augIdeal_eq_span, Ideal.map_span]
  simp only [Algebra.TensorProduct.includeRight_apply, Set.image_image2]

def dpΨ : dpMorphism (condτ A S I condTFree hM).choose hI := by
  apply dpMorphismFromGens (condτ A S I condTFree hM).choose hI
    (f := (Ψ A S hI).toRingHom) (K_eq_span A S I)
  · simp only [AlgHom.toRingHom_eq_coe, K, Ideal.map_bot, i2, ge_iff_le,
      bot_le, sup_of_le_right, map_le_iff_le_comap]
    rw [augIdeal_eq_span, span_le]
    rintro _ ⟨n, hn, b, _, rfl⟩
    simp only [Set.mem_setOf_eq] at hn
    simp only [SetLike.mem_coe, mem_comap, Algebra.TensorProduct.includeRight_apply,
      RingHom.coe_coe]
    simp only [Ψ, Algebra.TensorProduct.productMap_apply_tmul, map_one, one_mul]
    apply (dpΦ A S hI hM hM_eq).ideal_comp
    apply Ideal.mem_map_of_mem
    exact dp_mem_augIdeal A (I →₀ A) hn b
  · rintro n _ ⟨m, hm, b, _, rfl⟩
    simp only [Set.mem_setOf_eq] at hm
    simp only [AlgHom.toRingHom_eq_coe, RingHom.coe_coe]
    erw [← ((condτ A S I condTFree hM).choose_spec.2).map_dpow]
    simp only [Ψ, i2, RingHom.coe_coe, Algebra.TensorProduct.includeRight_apply,
      Algebra.TensorProduct.productMap_apply_tmul, map_one, one_mul]
    erw [(dpΦ A S hI hM hM_eq).dpow_comp]
    · rfl
    all_goals
      apply dp_mem_augIdeal _ _ hm

-- Roby, lemma 4
theorem _root_.DividedPowerAlgebra.T_free_and_D_to_Q : CondQ A := by
  intro S _ _ I hI
  let M := I →₀ A
  let R := MvPolynomial S A
  obtain ⟨hM, hM_eq⟩ := condD M
  haveI hdpM_free : Module.Free A (DividedPowerAlgebra A M) := by
    apply DividedPowerAlgebra.toModule_free
  haveI hR_free : Module.Free A R :=
    Module.Free.of_basis (MvPolynomial.basisMonomials _ _)
  -- We consider `R ⊗[A] DividedPowerAlgebra A M` as a comm ring and an A-algebra
  use R ⊗[A] DividedPowerAlgebra A M, by infer_instance, by infer_instance
  use by infer_instance -- tensor product of free modules is free
  use Ψ A S hI
  use K A ⊥ (augIdeal A M)
  use (condτ A S I condTFree hM).choose
  use (dpΨ A S hI condTFree hM hM_eq).isDPMorphism
  constructor
  · refine le_antisymm ?_ (dpΨ A S hI condTFree hM hM_eq).ideal_comp
    intro i hi
    let m : M := Finsupp.single ⟨i, hi⟩ 1
    have : i = Ψ A S hI (Algebra.TensorProduct.includeRight (ι A M m)) :=  by
      simp [m, Ψ, Φ, f, Basis.constr_apply]
    rw [this]
    apply Ideal.mem_map_of_mem
    apply Ideal.mem_sup_right
    apply Ideal.mem_map_of_mem
    apply ι_mem_augIdeal
  · apply Ψ_surjective
#align divided_power_algebra.T_free_and_D_to_Q DividedPowerAlgebra.T_free_and_D_to_Q

end roby4


example {A : Type*} [CommRing A] (a : A) (n : ℕ) : n • a = n * a := by refine' nsmul_eq_mul n a

/- In Roby, all PD-algebras A considered are of the form A₀ ⊕ A₊,
where A₊ is the PD-ideal. In other words, the PD-ideal is an augmentation ideal.
Moreover, PD-morphisms map A₀ to B₀ and A₊ to B₊,
so that their kernel is a direct sum K₀ ⊕ K₊

Roby's framework is stated in terms of `pre-graded algebras`,
namely graded algebras by the monoid {⊥, ⊤} with carrier set `Fin 2`
(with multiplication, ⊤ = 0 and ⊥ = 1)

Most of the paper works in greater generality, as noted by Berthelot,
but not all the results hold in general.
Berthelot gives an example (1.7) of a tensor product of algebras
with divided power ideals whose natural ideal does not have compatible
divided powers.

[Berthelot, 1.7.1] gives the explicit property that holds for tensor products.
For an `A`-algebra `R` and `I : Ideal R`, one assumes the
existence of `R₀ : Subalgebra A R` such that `R = R₀ ⊕ I` as an `I`-module.
Equivalently, the map `R →ₐ[A] R ⧸ I` has a left inverse.

In lemma 6, we have two surjective algebra morphisms
 f : R →+* R',  g : S →+* S'
and we consider the induced surjective morphism fg : R ⊗ S →+* R' ⊗ S'
R has a PD-ideal I,  R' has a PD-ideal I',
S has a PD-ideal J,  S' has a PD-ideal J'
with assumptions that I' = map f I and J' = map g J,
with quotient PD structures

Lemma 5 has proved that  fg.ker = (f.ker ⊗ 1) ⊔ (1 ⊗ g.ker)

The implicit hypothesis in lemma 6 is that f is homogeneous,
ie, maps R₊ = I to R'₊ = J and R₀ to R'₀, and same for g

In the end, Roby applies his proposition 4 which we
apparently haven't formalized and make use of yet another definition,
namely of a `divised ideal` :
Up to the homogeneous condition, this is exactly that `K ⊓ I` is a sub-pd-ideal.
The proof of proposition goes by using that
`Ideal.span (s ∩ ↑I) = Ideal.span s ⊓ I`
if `s` consists of homogeneous elements.

So we assume the `roby` condition in the statement, in the hope
that will be possible to prove it each time we apply cond_τ_rel
-/

lemma _root_.Ideal.map_toRingHom (A R S : Type*) [CommSemiring A]
    [Semiring R] [Algebra A R] [Semiring S] [Algebra A S] (f : R →ₐ[A] S)
    (I : Ideal R) : Ideal.map f I = Ideal.map f.toRingHom I := rfl

-- Roby, lemma 6
theorem condτ_rel (A : Type u) [CommRing A] {R S R' S' : Type u} [CommRing R] [CommRing S]
    [CommRing R'] [CommRing S'] [Algebra A R] [Algebra A S] [Algebra A R'] [Algebra A S']
    (f : R →ₐ[A] R') (hf : Function.Surjective f) {I : Ideal R} (hI : DividedPowers I)
    {I' : Ideal R'} (hI' : DividedPowers I') (hf' : isDPMorphism hI hI' f) (hI'I : I' = I.map f)
    (g : S →ₐ[A] S') (hg : Function.Surjective g) {J : Ideal S} (hJ : DividedPowers J)
    {J' : Ideal S'} (hJ' : DividedPowers J') (hg' : isDPMorphism hJ hJ' g) (hJ'J : J' = J.map g)
    (roby :
      RingHom.ker (Algebra.TensorProduct.map f g) ⊓ K A I J =
        Ideal.map (Algebra.TensorProduct.includeLeft (S := A)) (RingHom.ker f ⊓ I)
          ⊔ Ideal.map (Algebra.TensorProduct.includeRight) (RingHom.ker g ⊓ J))
    (hRS : Condτ A hI hJ) : Condτ A hI' hJ' := by
  obtain ⟨hK, hK_pd⟩ := hRS
  simp only [Condτ]
  let fg := Algebra.TensorProduct.map f g
  have s_fg : Function.Surjective fg.toRingHom := TensorProduct.map_surjective hf hg
  have hK_map : K A I' J' = (K A I J).map fg := by
    simp only [K, fg, hI'I, hJ'J]
    rw [Ideal.map_sup]
    apply congr_arg₂
    simp only [Ideal.map_toRingHom, Ideal.map_map]
    apply congr_arg₂ _ _ rfl
    ext x
    simp only [i1, RingHom.comp_apply, AlgHom.toRingHom_eq_coe, AlgHom.coe_toRingHom,
      Algebra.TensorProduct.includeLeft_apply, Algebra.TensorProduct.map_tmul, map_one]
    simp only [Ideal.map_toRingHom, Ideal.map_map]
    apply congr_arg₂ _ _ rfl
    ext x
    simp only [i2, AlgHom.toRingHom_eq_coe, RingHom.coe_comp, AlgHom.coe_toRingHom,
      Function.comp_apply, Algebra.TensorProduct.includeRight_apply, Algebra.TensorProduct.map_tmul,
      map_one]
  have hK'_pd : isSubDPIdeal hK (RingHom.ker fg.toRingHom ⊓ K A I J) := by
    change isSubDPIdeal hK (RingHom.ker (Algebra.TensorProduct.map f g) ⊓ K A I J)
    rw [roby]
    apply isSubDPIdeal_sup
    apply isSubDPIdeal_map hI hK hK_pd.1
    exact isSubDPIdeal_ker hI hI' hf'
    apply isSubDPIdeal_map hJ hK hK_pd.2
    exact isSubDPIdeal_ker hJ hJ' hg'
  rw [hK_map]
  let hK' := DividedPowers.Quotient.OfSurjective.dividedPowers hK s_fg hK'_pd
  use hK'
  constructor
  · -- hI'.is_pd_morphism hK' ↑(i_1 A R' S')
    constructor
    · rw [← hK_map]
      rw [Ideal.map_le_iff_le_comap]; intro a' ha'
      rw [Ideal.mem_comap]
      apply Ideal.mem_sup_left; apply Ideal.mem_map_of_mem; exact ha'
    · intro n a' ha'
      simp only [hI'I, Ideal.mem_map_iff_of_surjective f hf] at ha'
      obtain ⟨a, ha, rfl⟩ := ha'
      simp only [i1, AlgHom.coe_toRingHom, Algebra.TensorProduct.includeLeft_apply]
      suffices ∀ x : R, fg.toRingHom (x ⊗ₜ[A] 1) = f x ⊗ₜ[A] 1 by
        rw [← this]
        rw [Quotient.OfSurjective.dpow_apply hK s_fg]
        have that := hf'.2 n a ha
        simp only [AlgHom.coe_toRingHom] at that ; rw [that]
        rw [← this]
        apply congr_arg
        exact hK_pd.1.2 n a ha
        apply Ideal.mem_sup_left
        apply Ideal.mem_map_of_mem _ ha
      · intro x
        simp only [AlgHom.toRingHom_eq_coe, AlgHom.coe_toRingHom,
            Algebra.TensorProduct.map_tmul, map_one]
        simp only [Algebra.TensorProduct.map_tmul, map_one, fg]
  · -- hJ'.is_pd_morphism hK' ↑(i_2 A R' S')
    constructor
    · rw [← hK_map]
      rw [Ideal.map_le_iff_le_comap]; intro a' ha'
      rw [Ideal.mem_comap]
      apply Ideal.mem_sup_right; apply Ideal.mem_map_of_mem; exact ha'
    · intro n a' ha'
      simp only [hJ'J, Ideal.mem_map_iff_of_surjective g hg] at ha'
      obtain ⟨a, ha, rfl⟩ := ha'
      simp only [i2, AlgHom.coe_toRingHom, Algebra.TensorProduct.includeRight_apply]
      suffices ∀ y : S, fg.toRingHom (1 ⊗ₜ[A] y) = 1 ⊗ₜ[A] g y by
        rw [← this]
        rw [Quotient.OfSurjective.dpow_apply hK s_fg]
        have that := hg'.2 n a ha
        simp only [AlgHom.coe_toRingHom] at that ; rw [that]
        rw [← this]
        apply congr_arg
        simp only [← Algebra.TensorProduct.includeRight_apply]
        exact hK_pd.2.2 n a ha
        apply Ideal.mem_sup_right
        apply Ideal.mem_map_of_mem _ ha
      intro x
      simp only [AlgHom.toRingHom_eq_coe, RingHom.coe_coe, Algebra.TensorProduct.map_tmul, map_one,
        fg]
#align divided_power_algebra.cond_τ_rel DividedPowerAlgebra.condτ_rel

-- Roby, lemma 7
theorem condQ_and_condTFree_imply_condT (A : Type*) [CommRing A]
    (hQ : CondQ A) (hT_free : CondTFree A) : CondT A := by
  intro R' _ _ I' hI' S' _ _ J' hJ'
  simp only [CondQ] at hQ
  obtain ⟨R, _, _, hR_free, f, I, hI, hfDP, hfI, hf⟩ := hQ R' I' hI'
  obtain ⟨S, _, _, hS_free, g, J, hJ, hgDP, hgJ, hg⟩ := hQ S' J' hJ'
  apply condτ_rel A f hf hI hI' hfDP hfI g  hg hJ hJ' hgDP hgJ
  · rw [Algebra.TensorProduct.map_ker _ _ hf hg]
    sorry
  · apply hT_free
    exact hR_free
    exact hS_free
#align divided_power_algebra.cond_Q_and_cond_T_free_imply_cond_T
  DividedPowerAlgebra.condQ_and_condTFree_imply_condT

-- Roby, lemma 8
theorem condT_and_condD_imply_cond_D' (A : Type*) [CommRing A] [DecidableEq A]
    (hT : CondT A) (hD : CondD A)
    (R : Type*) [CommRing R]  [DecidableEq R] [Algebra A R] :
    CondD R :=
  sorry
#align divided_power_algebra.cond_T_and_cond_D_imply_cond_D'
  DividedPowerAlgebra.condT_and_condD_imply_cond_D'

-- Roby, lemma 9 is in roby9
-- Roby, lemma 10
theorem condT_implies_cond_T'_free (A : Type*) [CommRing A] (R : Type*) [CommRing R] [Algebra A R]
    (hA : CondT A) : CondTFree R :=
  sorry
#align divided_power_algebra.cond_T_implies_cond_T'_free
  DividedPowerAlgebra.condT_implies_cond_T'_free

-- Roby, lemma 11
theorem condTFree_int : CondTFree ℤ :=
  sorry
#align divided_power_algebra.cond_T_free_int DividedPowerAlgebra.condTFree_int

-- Roby, lemma 12
theorem condD_int : CondD ℤ :=
  sorry
#align divided_power_algebra.cond_D_int DividedPowerAlgebra.condD_int

theorem condQ_int : CondQ ℤ :=
  T_free_and_D_to_Q ℤ condTFree_int condD_int
#align divided_power_algebra.cond_Q_int DividedPowerAlgebra.condQ_int

theorem condT_int : CondT ℤ :=
  condQ_and_condTFree_imply_condT ℤ condQ_int condTFree_int
#align divided_power_algebra.cond_T_int DividedPowerAlgebra.condT_int

theorem condD_holds (A : Type*) [CommRing A] [DecidableEq A] : CondD A :=
  condT_and_condD_imply_cond_D' ℤ condT_int condD_int A
#align divided_power_algebra.cond_D_holds DividedPowerAlgebra.condD_holds

theorem condTFree_holds (A : Type*) [CommRing A] : CondTFree A :=
  condT_implies_cond_T'_free ℤ A condT_int
#align divided_power_algebra.cond_T_free_holds DividedPowerAlgebra.condTFree_holds

theorem condQ_holds (A : Type*) [CommRing A] [DecidableEq A] : CondQ A :=
  T_free_and_D_to_Q A (condTFree_holds A) (condD_holds A)
#align divided_power_algebra.cond_Q_holds DividedPowerAlgebra.condQ_holds

theorem condT_holds (A : Type*) [CommRing A] [DecidableEq A] : CondT A :=
  condQ_and_condTFree_imply_condT A (condQ_holds A) (condTFree_holds A)
#align divided_power_algebra.cond_T_holds DividedPowerAlgebra.condT_holds

end Proofs

-- Old names
theorem roby_δ (A : Type u) [CommRing A] [DecidableEq A] (M : Type u) [AddCommGroup M]
    [Module A M] : DividedPowerAlgebra.Condδ A M :=
  condD_holds A M
#align divided_power_algebra.roby_δ DividedPowerAlgebra.roby_δ

set_option linter.uppercaseLean3 false
theorem roby_D (A : Type*) [CommRing A] [DecidableEq A] : DividedPowerAlgebra.CondD A :=
  condD_holds A
#align divided_power_algebra.roby_D DividedPowerAlgebra.roby_D

theorem roby_τ (A R S : Type u) [CommRing A] [DecidableEq A] [CommRing R] [Algebra A R]
    [CommRing S] [Algebra A S]
    {I : Ideal R} {J : Ideal S} (hI : DividedPowers I) (hJ : DividedPowers J) : Condτ A hI hJ :=
  condT_holds A R hI S hJ
#align divided_power_algebra.roby_τ DividedPowerAlgebra.roby_τ

theorem roby_T (A : Type*) [CommRing A] [DecidableEq A] : CondT A :=
  condT_holds A
#align divided_power_algebra.roby_T DividedPowerAlgebra.roby_T

open DividedPowerAlgebra

-- namespace divided_power_algebra
-- Part of Roby65 Thm 1
def dividedPowers' (A : Type u) [CommRing A] [DecidableEq A] (M : Type u) [AddCommGroup M]
    [Module A M] : DividedPowers (augIdeal A M) :=
  (roby_D A M).choose
#align divided_power_algebra.divided_powers' DividedPowerAlgebra.dividedPowers'

theorem dpow_ι (A : Type u) [CommRing A] [DecidableEq A] (M : Type u) [AddCommGroup M] [Module A M]
    (x : M) (n : ℕ) : dpow (dividedPowers' A M) n (ι A M x) = dp A n x :=
  (roby_D A M).choose_spec n x
#align divided_power_algebra.dpow_ι DividedPowerAlgebra.dpow_ι

theorem dp_comp (A : Type u) [CommRing A] [DecidableEq A] (M : Type u) [AddCommGroup M] [Module A M]
    (x : M) {n : ℕ} (m : ℕ) (hn : n ≠ 0) :
    dpow (dividedPowers' A M) m (dp A n x) = ↑(mchoose m n) * dp A (m * n) x := by
  erw [← (roby_D A M).choose_spec, dpow_comp _ m hn (ι_mem_augIdeal A M x), dpow_ι]
#align divided_power_algebra.dp_comp DividedPowerAlgebra.dp_comp

theorem roby_theorem_2 (R : Type u) [CommRing R]  [DecidableEq R]
    (M : Type u) [AddCommGroup M] [Module R M]
    {A : Type u} [CommRing A] [Algebra R A] {I : Ideal A} (hI : DividedPowers I)
    {φ : M →ₗ[R] A} (hφ : ∀ m, φ m ∈ I) :
    isDPMorphism (dividedPowers' R M) hI (DividedPowerAlgebra.lift hI φ hφ) := by
  apply cond_D_uniqueness
  intro m n
  rw [dpow_ι]
#align divided_power_algebra.roby_theorem_2 DividedPowerAlgebra.roby_theorem_2

-- TODO: fix the last two theorems
theorem lift'_eq_dp_lift (R : Type u) [CommRing R]
    {M : Type v} [AddCommGroup M] [Module R M]
    (S : Type w) [CommRing S] [DecidableEq S] [Algebra R S]
    {N : Type w} [AddCommGroup N] [Module R N] [Module S N] [IsScalarTower R S N] (f : M →ₗ[R] N) :
    ∃ hφ : ∀ m, ((ι S N).restrictScalars R).comp f m ∈ augIdeal S N,
      LinearMap.lift R S f =
        DividedPowerAlgebra.lift (dividedPowers' S N)
          (((ι S N).restrictScalars R).comp f) hφ := by
  have hφ : ∀ m, ((ι S N).restrictScalars R).comp f m ∈ augIdeal S N := by
    intro m
    simp only [LinearMap.coe_comp, LinearMap.coe_restrictScalars,
      Function.comp_apply, ι_mem_augIdeal S N (f m)]
  use hφ
  apply DividedPowerAlgebra.ext
  intro n m
  simp only [liftAlgHom_apply_dp, LinearMap.coe_comp, LinearMap.coe_restrictScalars,
    Function.comp_apply]
  simp only [LinearMap.liftAlgHom_dp]
  simp only [ι, LinearMap.coe_mk, AddHom.coe_mk]
  rw [dp_comp _ _ _ _ Nat.one_ne_zero]
  simp only [mchoose_one', Nat.cast_one, mul_one, one_mul]

theorem roby_prop_8 (R : Type u) [DecidableEq R] [CommRing R]
    {M : Type u} [AddCommGroup M] [Module R M]
    (S : Type u) [DecidableEq S] [CommRing S] [Algebra R S]
    {N : Type u} [AddCommGroup N] [Module R N] [Module S N]
    [IsScalarTower R S N] (f : M →ₗ[R] N) :
    isDPMorphism (dividedPowers' R M) (dividedPowers' S N) (LinearMap.lift R S f) := by
  obtain ⟨hφ, phφ'⟩ := lift'_eq_dp_lift R S f
  convert roby_theorem_2 R M (dividedPowers' S N) hφ
#align divided_power_algebra.roby_prop_8 DividedPowerAlgebra.roby_prop_8

end DividedPowerAlgebra

end Roby
