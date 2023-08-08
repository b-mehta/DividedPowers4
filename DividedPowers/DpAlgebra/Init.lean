/- Copyright 2022 ACL & MIdFF
! This file was ported from Lean 3 source module divided_powers.dp_algebra.init
-/

import DividedPowers.Basic
import DividedPowers.DpAlgebra.Misc

import Mathlib.Algebra.RingQuot
import Mathlib.Algebra.Algebra.Operations
import Mathlib.Data.Rel
import Mathlib.RingTheory.Ideal.Quotient

noncomputable section

open Finset MvPolynomial Ideal.Quotient

-- triv_sq_zero_ext
open Ideal

-- direct_sum
open RingQuot

/-! 
The divided power algebra of a module -/


section

variable (R M : Type _) [CommSemiring R] [AddCommMonoid M] [Module R M]

namespace DividedPowerAlgebra

/- For technical reasons, when passing to quotients,
  it seems that one has to add to `Rel` the property that
  it is reflexive… -/
  
-- We should probably change this name...
/-- The type coding the basic relations that will give rise to the divided power algebra. 
  The class of X (n, a) will be equal to dpow n a, with a ∈ M. --/
inductive Rel : (MvPolynomial (ℕ × M) R) → (MvPolynomial (ℕ × M) R) → Prop 
/-- rfl 0 -/
  | rfl_zero : Rel 0 0
/-- dpow_zero -/ 
  | zero {a : M} : Rel (X (0, a)) 1
/-- dpow_smul -/
  | smul {r : R} {n : ℕ} {a : M} : Rel (X (n, r • a)) (r ^ n • X (n, a))
/-- dpow_mul -/
  | mul {m n : ℕ} {a : M} : Rel (X (m, a) * X (n, a)) (Nat.choose (m + n) m • X (m + n, a))
/- dpow_add-/
  | add {n : ℕ} {a b : M} :
    Rel (X (n, a + b)) (Finset.sum (range (n + 1)) fun k => X (k, a) * X (n - k, b))
#align divided_power_algebra.rel DividedPowerAlgebra.Rel

/-- The ideal of mv_polynomial (ℕ × M) R generated by rel -/
def RelI : Ideal (MvPolynomial (ℕ × M) R) := ofRel (DividedPowerAlgebra.Rel R M)
set_option linter.uppercaseLean3 false
#align divided_power_algebra.relI DividedPowerAlgebra.RelI
set_option linter.uppercaseLean3 true

end DividedPowerAlgebra

-- ATTEMPT TO DIRECTLY USE THE RELATION 

/-- The divided power algebra of a module M is defined as the ring quotient 
  of the polynomial ring in the set variables `ℕ × M`
  by the ring relation defined by the relation `DividedPowerAlgebra.Rel` 
  Note that also we don't know yet that `divided_power_algebra R M` 
  has divided powers, 
  it has a weak universal property for morphisms to rings with divided_powers. -/
def DividedPowerAlgebra : Type _ :=
  RingQuot (DividedPowerAlgebra.Rel R M)
#align divided_power_algebra DividedPowerAlgebra

  -- It can also be defined as (MvPolynomial (ℕ × M) R) ⧸ (DividedPowerAlgebra.relI R M)

namespace DividedPowerAlgebra

/-- The divided power algebra is a commutative semiring -/
instance : CommSemiring (DividedPowerAlgebra R M) := RingQuot.instCommSemiring _

/-- The divided power algebra is a commutative ring -/
instance (R M : Type _) [CommRing R] [AddCommMonoid M] [Module R M] : 
  CommRing (DividedPowerAlgebra R M) :=  
  RingQuot.instCommRingRingQuotToSemiringToCommSemiring _

instance : Zero (DividedPowerAlgebra R M) := AddMonoid.toZero

instance : One (DividedPowerAlgebra R M) := Monoid.toOne

instance : Inhabited (DividedPowerAlgebra R M) := 
  RingQuot.instInhabitedRingQuot _

/-- If `R` is a `k`-algebra, then `divided_power_algebra R M` inherits a `k`-algebra structure. -/
instance algebra (k : Type _) [CommSemiring k] [Algebra k R] : 
  Algebra k (DividedPowerAlgebra R M) := 
  RingQuot.instAlgebraRingQuotInstSemiring _
-- #align divided_power_algebra.algebra' 

instance (k : Type _) [CommSemiring k] [Algebra k R] : 
  IsScalarTower k R (DividedPowerAlgebra R M) where
  smul_assoc := by 
    rintro a r ⟨⟨x⟩⟩
    rw [smul_quot, smul_quot, smul_quot, smul_assoc]

open MvPolynomial

variable {R M}

theorem _root_.Ideal.sub_mem_ofRel_of_rel {R : Type _} [Ring R] 
  (r : R → R → Prop) {a b : R} (hr : r a b) : 
  a - b ∈ Ideal.ofRel r := 
  Submodule.subset_span ⟨a, b, hr, by rw [sub_add_cancel]⟩

/- -- generalized
theorem sub_mem_rel_of_rel {R M : Type _} [CommRing R] [AddCommMonoid M] [Module R M] 
    {a b : MvPolynomial (ℕ × M) R} (h : Rel R M a b) : 
  a - b ∈ RelI R M :=
  Submodule.subset_span ⟨a, b, h, by rw [sub_add_cancel]⟩
#align divided_power_algebra.sub_mem_rel_of_rel DividedPowerAlgebra.sub_mem_rel_of_rel
-/

/- -- Useless 
theorem mkRingHom_eq {a b : MvPolynomial (ℕ × M) R} (h : Rel R M a b) :
  mkRingHom (Rel R M) a = mkRingHom (Rel R M) b := RingQuot.mkRingHom_rel h
-/

/-- The canonical AlgHom map from `MvPolynomial (ℕ × M) R ` to `DividedPowerAlgebra R M`-/
def mk : MvPolynomial (ℕ × M) R →ₐ[R] DividedPowerAlgebra R M := 
  mkAlgHom R (Rel R M)

lemma mk_surjective : Function.Surjective (@mk R M _ _ _) := by 
  apply RingQuot.mkAlgHom_surjective

lemma mk_C (a : R) : mk (C a) = algebraMap R (DividedPowerAlgebra R M) a := by
  rw [← MvPolynomial.algebraMap_eq, AlgHom.commutes]
variable (R)

/-- `dp R n m` is the equivalence class of `X (⟨n, m⟩)` in `divided_power_algebra R M`. -/
def dp (n : ℕ) (m : M) : DividedPowerAlgebra R M :=
  mk (X ⟨n, m⟩)
#align divided_power_algebra.dp DividedPowerAlgebra.dp

--lemma dp_def (n : ℕ) (m : M) : dp R n m = mkₐ R (relI R M) (X (⟨n, m⟩)) := rfl  --rename?
theorem dp_def (n : ℕ) (m : M) : 
  dp R n m = mkAlgHom R (Rel R M) (X ⟨n, m⟩) := rfl
#align divided_power_algebra.dp_eq_mkₐ DividedPowerAlgebra.dp_def

theorem dp_eq_mkRingHom (n : ℕ) (m : M) : 
  dp R n m = mkRingHom (Rel R M) (X (⟨n, m⟩)) := by
  rw [dp_def, ← mkAlgHom_coe R]
  rfl
#align divided_power_algebra.dp_eq_mk DividedPowerAlgebra.dp_eq_mkRingHom

theorem dp_zero (m : M) : dp R 0 m = 1 := by
  rw [dp_def, ← map_one (mkAlgHom R (Rel R M))]
  exact RingQuot.mkAlgHom_rel R Rel.zero
#align divided_power_algebra.dp_zero DividedPowerAlgebra.dp_zero

theorem dp_smul (r : R) (n : ℕ) (m : M) : 
  dp R n (r • m) = r ^ n • dp R n m := by
  rw [dp_def, dp_def, ← map_smul]
  exact mkAlgHom_rel R Rel.smul
#align divided_power_algebra.dp_smul DividedPowerAlgebra.dp_smul

theorem dp_null (n : ℕ) : 
  dp R n (0 : M) = if n = 0 then 1 else 0 := by
  cases' Nat.eq_zero_or_pos n with hn hn
  · rw [if_pos hn]; rw [hn]; rw [dp_zero]
  · rw [if_neg (ne_of_gt hn)]; rw [← zero_smul R (0 : M)]
    rw [dp_smul]; rw [zero_pow hn]
    simp only [zero_smul, map_zero]
#align divided_power_algebra.dp_null DividedPowerAlgebra.dp_null

theorem dp_mul (n p : ℕ) (m : M) : 
  dp R n m * dp R p m = (n + p).choose n • dp R (n + p) m := by
  simp only [dp_def, ← _root_.map_mul, ← map_nsmul]
  exact mkAlgHom_rel R Rel.mul
#align divided_power_algebra.dp_mul DividedPowerAlgebra.dp_mul

theorem dp_add (n : ℕ) (x y : M) :
  dp R n (x + y) = 
    (range (n + 1)).sum fun k => dp R k x * dp R (n - k) y := by
  simp only [dp_def]
  simp only [← _root_.map_mul, ← AlgHom.map_sum]
  exact mkAlgHom_rel R Rel.add
#align divided_power_algebra.dp_add DividedPowerAlgebra.dp_add

theorem dp_sum {ι : Type _} [DecidableEq ι] (s : Finset ι) (q : ℕ) (x : ι → M) :
  dp R q (s.sum x) =
    (Finset.sym s q).sum 
      fun k => s.prod fun i => dp R (Multiset.count i k) (x i) :=  by
  apply DividedPowers.dpow_sum_aux'
  · intro x; rw [dp_zero]
  · intro n x y; rw [dp_add]
  · intro n hn; rw [dp_null R n, if_neg hn]
#align divided_power_algebra.dp_sum DividedPowerAlgebra.dp_sum

theorem dp_sum_smul {ι : Type _} [DecidableEq ι] (s : Finset ι)
    (q : ℕ) (a : ι → R) (x : ι → M) :
    dp R q (s.sum fun i => a i • x i) =
      (Finset.sym s q).sum fun k =>
        (s.prod fun i => a i ^ Multiset.count i k) •
          s.prod fun i => dp R (Multiset.count i k) (x i) :=
  by simp_rw [dp_sum, dp_smul, Algebra.smul_def, map_prod, ← Finset.prod_mul_distrib]
#align divided_power_algebra.dp_sum_smul DividedPowerAlgebra.dp_sum_smul

variable {R}
theorem ext_iff {A : Type _} [CommSemiring A] [Algebra R A] 
    {f g : DividedPowerAlgebra R M →ₐ[R] A} :
    (f = g) ↔ (∀ n m, f (dp R n m) = g (dp R n m)) := by
  constructor
  . intro h n m
    rw [h]
  . intro h
    rw [FunLike.ext'_iff]
    apply Function.Surjective.injective_comp_right (mkAlgHom_surjective R (Rel R M))
    simp only [← AlgHom.coe_comp, ← FunLike.ext'_iff]
    exact MvPolynomial.algHom_ext fun ⟨n, m⟩ => h n m

@[ext]
theorem ext {A : Type _} [CommSemiring A] [Algebra R A] 
    {f g : DividedPowerAlgebra R M →ₐ[R] A} 
    (h : ∀ n m, f (dp R n m) = g (dp R n m)) : f = g :=
  DividedPowerAlgebra.ext_iff.mpr h
#align divided_power_algebra.unique_on_dp DividedPowerAlgebra.ext

variable (R)

section UniversalProperty

variable (M)

variable {A : Type _} [CommSemiring A] [Algebra R A]

/- -- General purpose lifting lemma
theorem lift_rel_le_ker (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩) :
    relI R M ≤ RingHom.ker (@eval₂AlgHom R A (ℕ × M) _ _ _ f) :=
  by
  rw [relI, of_rel, Submodule.span_le]
  rintro x ⟨a, b, hx, hab⟩
  rw [eq_sub_iff_add_eq.mpr hab, SetLike.mem_coe, RingHom.mem_ker, map_sub, sub_eq_zero]
  induction' hx with m r n m n p m n u v
  · rw [eval₂_alg_hom_X', map_one, hf_zero]
  · simp only [eval₂_alg_hom_X', AlgHom.map_smul, hf_smul]
  · simp only [_root_.map_mul, eval₂_alg_hom_X', nsmul_eq_mul, map_natCast, hf_mul]
  · simp only [coe_eval₂_alg_hom, eval₂_X, eval₂_sum, eval₂_mul, hf_add]
#align divided_power_algebra.lift_rel_le_ker DividedPowerAlgebra.lift_rel_le_ker
 -/

theorem lift'_imp (f : ℕ × M → A) 
    (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩) 
    (p q : MvPolynomial (ℕ × M) R) (h : (Rel R M) p q) : 
    (eval₂AlgHom R f) p = (eval₂AlgHom R f) q := by
  cases' h with a r n a m n a n a b <;> 
    simp only [eval₂AlgHom_X', map_one, map_zero, map_smul, AlgHom.map_mul, map_nsmul, AlgHom.map_sum]
  . apply hf_zero 
  . apply hf_smul 
  . apply hf_mul
  . apply hf_add

variable {R M}
/-- The weak universal property of `DividedPowerAlgebra R M` -/
def lift' (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩) :
    DividedPowerAlgebra R M →ₐ[R] A := RingQuot.liftAlgHom R 
    {val := eval₂AlgHom R f, property := lift'_imp R M f hf_zero hf_smul hf_mul hf_add }
#align divided_power_algebra.lift_aux DividedPowerAlgebra.lift'

@[simp]
theorem lift'AlgHom_apply (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩)
    (p : MvPolynomial (ℕ × M) R) :
  lift' f hf_zero hf_smul hf_mul hf_add (mk p) = 
    aeval f p := by 
  rw [mk, lift', RingQuot.liftAlgHom_mkAlgHom_apply, coe_eval₂AlgHom]
  rfl
#align divided_power_algebra.lift_aux_eq DividedPowerAlgebra.lift'AlgHom_apply

@[simp]
theorem lift'AlgHom_apply_dp (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩)
    (n : ℕ) (m : M) :
    lift' f hf_zero hf_smul hf_mul hf_add (dp R n m) = f ⟨n, m⟩ := by
  rw [dp_def, ← mk, lift'AlgHom_apply f hf_zero hf_smul hf_mul hf_add, aeval_X]
set_option linter.uppercaseLean3 false
#align divided_power_algebra.lift_aux_eq_X DividedPowerAlgebra.lift'AlgHom_apply_dp
set_option linter.uppercaseLean3 true

variable {I : Ideal A} (hI : DividedPowers I) (φ : M →ₗ[R] A) (hφ : ∀ m, φ m ∈ I)

/-- The weak universal property of a divided power algebra for morphisms to divided power rings -/
def lift : DividedPowerAlgebra R M →ₐ[R] A :=
  lift' (fun nm => hI.dpow nm.1 (φ nm.2)) 
    (fun m => hI.dpow_zero (hφ m))
    (fun n r m => by
      dsimp
      rw [LinearMap.map_smulₛₗ, RingHom.id_apply, ← algebraMap_smul A r (φ m), smul_eq_mul,
        hI.dpow_smul n (hφ m), ← smul_eq_mul, ← map_pow, algebraMap_smul])
    (fun n p m => by 
      rw [hI.dpow_mul n p (hφ m), ← nsmul_eq_mul]) 
    (fun n u v => by
      dsimp
      rw [map_add, hI.dpow_add n (hφ u) (hφ v)])
#align divided_power_algebra.lift DividedPowerAlgebra.lift

variable {φ}

@[simp]
theorem liftAlgHom_apply (p : MvPolynomial (ℕ × M) R) :
    lift hI φ hφ (mk p) =
      aeval (fun nm : ℕ × M => hI.dpow nm.1 (φ nm.2)) p :=
  by rw [lift, lift'AlgHom_apply]
#align divided_power_algebra.lift_eqₐ DividedPowerAlgebra.liftAlgHom_apply

-- theorem lift_apply(p : MvPolynomial (ℕ × M) R) :
--     lift hI φ hφ (mk p) =
--       aeval (fun nm : ℕ × M => hI.dpow nm.1 (φ nm.2)) p :=
--   by rw [liftAlgHom_apply]
-- #align divided_power_algebra.lift_eq DividedPowerAlgebra.lift_eq

@[simp]
theorem liftAlgHom_apply_dp (n : ℕ) (m : M) :
    lift hI φ hφ (dp R n m) = hI.dpow n (φ m) := by 
  rw [lift, lift'AlgHom_apply_dp]
set_option linter.uppercaseLean3 false
#align divided_power_algebra.lift_eqₐ_X DividedPowerAlgebra.liftAlgHom_apply_dp
set_option linter.uppercaseLean3 true

-- theorem lift_eq_x (n : ℕ) (m : M) : 
--   lift R M hI φ hφ (mk (relI R M) (X (n, m))) = hI.dpow n (φ m) :=
--   by rw [← mkₐ_eq_mk R, lift_eqₐ_X]
-- #align divided_power_algebra.lift_eq_X DividedPowerAlgebra.lift_eq_x

-- theorem lift_dp_eq (n : ℕ) (m : M) : lift R M hI φ hφ (dp R n m) = hI.dpow n (φ m) := by
--   rw [dp_eq_mk, lift_eq_X]
-- #align divided_power_algebra.lift_dp_eq DividedPowerAlgebra.lift_dp_eq

end UniversalProperty

section Functoriality

variable (S : Type _) [CommSemiring S] [Algebra R S] 
  {N : Type _} [AddCommMonoid N] [Module R N]
  [Module S N] [IsScalarTower R S N] [Algebra R (DividedPowerAlgebra S N)]
  [IsScalarTower R S (DividedPowerAlgebra S N)] (f : M →ₗ[R] N)

/- 
theorem lift'_rel_le_ker :
    relI R M ≤ RingHom.ker (@eval₂AlgHom R _ (ℕ × M) _ _ _ fun nm => dp S nm.1 (f nm.2)) :=
  by
  apply rel_le_ker (relI R M) rfl
  intro a b hab
  induction' hab with m r n m n p m n u v
  · simp only [coe_eval₂_hom, eval₂_X, eval₂_one]
    rw [dp_zero]
  · conv_rhs => rw [← eval₂_alg_hom_apply, map_smul]
    simp only [eval₂_alg_hom_apply, eval₂_hom_X', LinearMap.map_smul]
    rw [← algebraMap_smul S r, ← algebraMap_smul S (r ^ n), dp_smul, map_pow]
    infer_instance; infer_instance
  · simp only [coe_eval₂_hom, eval₂_mul, eval₂_X, nsmul_eq_mul]
    simp only [eval₂_eq_eval_map, map_natCast, ← nsmul_eq_mul]
    rw [dp_mul]
  · simp only [map_add, coe_eval₂_hom, eval₂_sum, eval₂_mul, eval₂_X]
    rw [dp_add]
#align divided_power_algebra.lift'_rel_le_ker DividedPowerAlgebra.lift'_rel_le_ker
 -/

-- variable (p : MvPolynomial (ℕ × M) R)
-- #check aeval (fun (nm : ℕ × M) => dp S nm.fst (f nm.snd)) p

lemma LinearMap.dp_zero (a : M) : dp S 0 (f a) = 1 := 
  DividedPowerAlgebra.dp_zero S (f a)

lemma LinearMap.dp_smul (r : R) (n : ℕ) (a : M) : 
  dp S n (f (r • a)) = r ^ n • dp S n (f a) := by
  rw [f.map_smul, algebra_compatible_smul S r (f a)]
  rw [DividedPowerAlgebra.dp_smul S ((algebraMap R S) r) n (f a)]
  rw [← map_pow, ← algebra_compatible_smul]
  
lemma LinearMap.dp_mul (m n : ℕ) (a : M) :
  dp S m (f a) * dp S n (f a) = (Nat.choose (m + n) m) • dp S (m + n) (f a) := 
  DividedPowerAlgebra.dp_mul S m n (f a)

lemma LinearMap.dp_add (n : ℕ) (a b : M) :
  dp S n (f (a + b)) =
    (Finset.sum (range (n + 1)) fun k => dp S k (f a) * dp S (n - k) (f b)) := by
  rw [map_add, DividedPowerAlgebra.dp_add]

/-- The functoriality map between divided power algebras associated 
  with a linear map of the underlying modules. 
  Given an `R`-algebra `S`, an `S`-module `N` and `f : M →ₗ[R] N`, 
  this is the map `DividedPowerAlgebra R M →ₐ[R] DividedPowerAlgebra S N` 
  that maps `dp R n m` to `dp S n (f m)`.
-/
def LinearMap.lift : DividedPowerAlgebra R M →ₐ[R] DividedPowerAlgebra S N := by
  apply DividedPowerAlgebra.lift' (fun nm => dp S nm.fst (f nm.snd))
  . intro m ; apply LinearMap.dp_zero
  . intro n r a ; apply LinearMap.dp_smul
  . intro m n a ; apply LinearMap.dp_mul
  . intro n a b ; apply LinearMap.dp_add
#align divided_power_algebra.lift' DividedPowerAlgebra.LinearMap.lift

theorem LinearMap.liftAlgHom_apply (p : MvPolynomial (ℕ × M) R) :
  LinearMap.lift R S f (mk p) =
    aeval (fun nm => dp S nm.fst (f nm.snd)) p := by 
  rw [LinearMap.lift, lift'AlgHom_apply]

theorem LinearMap.liftAlgHom_dp (n : ℕ) (a : M) : 
  LinearMap.lift R S f (dp R n a) = dp S n (f a) := by
  rw [LinearMap.lift, lift'AlgHom_apply_dp]
  
/- 
theorem lift'_eq (p : MvPolynomial (ℕ × M) R) :
    lift' R S f (mk (relI R M) p) =
      eval₂ (algebraMap R (DividedPowerAlgebra S N)) (fun nm : ℕ × M => dp S nm.1 (f nm.2)) p :=
  by simp only [lift', liftₐ_apply, lift_mk, AlgHom.coe_toRingHom, coe_eval₂_alg_hom]
#align divided_power_algebra.lift'_eq DividedPowerAlgebra.lift'_eq

theorem lift'_eqₐ (p : MvPolynomial (ℕ × M) R) :
    lift' R S f (mkₐ R (relI R M) p) =
      eval₂ (algebraMap R (DividedPowerAlgebra S N)) (fun nm : ℕ × M => dp S nm.1 (f nm.2)) p :=
  by rw [mkₐ_eq_mk, lift'_eq]
#align divided_power_algebra.lift'_eqₐ DividedPowerAlgebra.lift'_eqₐ

theorem lift'_dp_eq (n : ℕ) (m : M) : lift' R S f (dp R n m) = dp S n (f m) := by
  rw [dp_eq_mk, lift'_eq, eval₂_X]
#align divided_power_algebra.lift'_dp_eq DividedPowerAlgebra.lift'_dp_eq
 -/

end Functoriality

end DividedPowerAlgebra

end

--#lint
