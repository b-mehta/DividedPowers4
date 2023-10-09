/- Copyright 2022 ACL & MIdFF
! This file was ported from Lean 3 source module divided_powers.dp_algebra.init
-/
import Mathbin.Algebra.RingQuot
import Mathbin.Algebra.Algebra.Operations
import Mathbin.Data.Rel
import Oneshot.DividedPowers.Basic
import Oneshot.DividedPowers.DPAlgebra.Misc

-- import algebra.free_algebra
-- import algebra.triv_sq_zero_ext
-- import algebra.triv_sq_zero_ext
-- import linear_algebra.multilinear.basic
-- import linear_algebra.multilinear.basic
-- import ring_theory.graded_algebra.basic
-- import ring_theory.graded_algebra.basic
-- import ring_theory.tensor_product
-- import ring_theory.tensor_product
-- import data.mv_polynomial.supported
-- import data.mv_polynomial.supported
-- import divided_powers.sub_pd_ideal
-- import divided_powers.sub_pd_ideal
-- import divided_powers.rat_algebra
-- import divided_powers.rat_algebra
-- import divided_powers.ideal_add
-- import divided_powers.ideal_add
-- import ..weighted_homogeneous -- Modified version of PR #17855
-- import ..weighted_homogeneous -- Modified version of PR #17855
-- import ..graded_ring_quot -- Quotients of graded rings
-- import ..graded_ring_quot -- Quotients of graded rings
-- import ..graded_module_quot
-- import ..graded_module_quot
noncomputable section

open Finset MvPolynomial Ideal.Quotient

-- triv_sq_zero_ext
open Ideal

-- direct_sum
open RingQuot

/-! 
The divided power algebra of a module -/


section

variable (R M : Type _) [CommRing R] [AddCommGroup M] [Module R M]

namespace DividedPowerAlgebra

--open finset mv_polynomial ideal.quotient triv_sq_zero_ext ideal direct_sum ring_quot
-- We should probably change this name...
/-- The type coding the basic relations that will give rise to the divided power algebra. 
  The class of X (n, a) will be equal to dpow n a, with a ∈ M. --/
inductive Rel :
    MvPolynomial (ℕ × M) R →
      MvPolynomial (ℕ × M) R →
        Prop--rel (mv_polynomial (ℕ × M) R) (mv_polynomial (ℕ × M) R) Q : Why not use rel?
-- force `ι` to be linear and creates the divided powers

  | zero {a : M} : Rel (X (0, a)) 1
  | smul {r : R} {n : ℕ} {a : M} : Rel (X (n, r • a)) (r ^ n • X (n, a))
  | mul {m n : ℕ} {a : M} : Rel (X (m, a) * X (n, a)) (Nat.choose (m + n) m • X (m + n, a))
  |
  add {n : ℕ} {a b : M} :
    Rel (X (n, a + b)) (Finset.sum (range (n + 1)) fun k => X (k, a) * X (n - k, b))
#align divided_power_algebra.rel DividedPowerAlgebra.Rel

/-- The ideal of mv_polynomial (ℕ × M) R generated by rel -/
def relI : Ideal (MvPolynomial (ℕ × M) R) :=
  ofRel (Rel R M)
#align divided_power_algebra.relI DividedPowerAlgebra.relI

end DividedPowerAlgebra

/- ./././Mathport/Syntax/Translate/Command.lean:43:9: unsupported derive handler algebra[algebra] R -/
/-- The divided power algebra of a module M is the quotient of the polynomial ring
by the ring relation defined by divided_power_algebra.rel -/
@[protected]
def DividedPowerAlgebra : Type _ :=
  MvPolynomial (ℕ × M) R ⧸ DividedPowerAlgebra.relI R M
deriving Inhabited, CommRing,
  «./././Mathport/Syntax/Translate/Command.lean:43:9: unsupported derive handler algebra[algebra] R»
#align divided_power_algebra DividedPowerAlgebra

namespace DividedPowerAlgebra

/- Note that also we don't know yet that `divided_power_algebra R M` has divided powers, 
  it has a kind of universal property for morphisms to a ring with divided_powers -/
open MvPolynomial

/-- If `R` is a `k`-algebra, then `divided_power_algebra R M` inherits a `k`-algebra structure. -/
instance algebra' (k : Type _) [CommRing k] [Algebra k R] : Algebra k (DividedPowerAlgebra R M) :=
  Ideal.Quotient.algebra k
#align divided_power_algebra.algebra' DividedPowerAlgebra.algebra'

instance (k : Type _) [CommRing k] [Algebra k R] : IsScalarTower k R (DividedPowerAlgebra R M) :=
  Quotient.isScalarTower k R (relI R M)

variable {R M}

theorem sub_mem_rel_of_rel {a b : MvPolynomial (ℕ × M) R} (h : Rel R M a b) : a - b ∈ relI R M :=
  Submodule.subset_span ⟨a, b, h, by rw [sub_add_cancel]⟩
#align divided_power_algebra.sub_mem_rel_of_rel DividedPowerAlgebra.sub_mem_rel_of_rel

variable (R)

/-- `dp R n m` is the equivalence class of `X (⟨n, m⟩)` in `divided_power_algebra R M`. -/
def dp (n : ℕ) (m : M) : DividedPowerAlgebra R M :=
  mkₐ R (relI R M) (X ⟨n, m⟩)
#align divided_power_algebra.dp DividedPowerAlgebra.dp

--lemma dp_def (n : ℕ) (m : M) : dp R n m = mkₐ R (relI R M) (X (⟨n, m⟩)) := rfl  --rename?
theorem dp_eq_mkₐ (n : ℕ) (m : M) : dp R n m = mkₐ R (relI R M) (X ⟨n, m⟩) :=
  rfl
#align divided_power_algebra.dp_eq_mkₐ DividedPowerAlgebra.dp_eq_mkₐ

theorem dp_eq_mk (n : ℕ) (m : M) : dp R n m = mk (relI R M) (X (⟨n, m⟩ : ℕ × M)) := by
  rw [dp, mkₐ_eq_mk]
#align divided_power_algebra.dp_eq_mk DividedPowerAlgebra.dp_eq_mk

theorem dp_zero (m : M) : dp R 0 m = 1 :=
  by
  rw [dp, mkₐ_eq_mk, ← map_one (Ideal.Quotient.mk (relI R M)), Ideal.Quotient.eq]
  exact Submodule.subset_span ⟨X (0, m), 1, rel.zero, by rw [sub_add_cancel]⟩
#align divided_power_algebra.dp_zero DividedPowerAlgebra.dp_zero

theorem dp_smul (r : R) (n : ℕ) (m : M) : dp R n (r • m) = r ^ n • dp R n m :=
  by
  rw [dp, dp, ← map_smul, mkₐ_eq_mk R, Ideal.Quotient.eq]
  exact sub_mem_rel_of_rel rel.smul
#align divided_power_algebra.dp_smul DividedPowerAlgebra.dp_smul

theorem dp_null (n : ℕ) : dp R n (0 : M) = ite (n = 0) 1 0 :=
  by
  cases' Nat.eq_zero_or_pos n with hn hn
  · rw [if_pos hn]; rw [hn]; rw [dp_zero]
  · rw [if_neg (ne_of_gt hn)]; rw [← zero_smul R (0 : M)]
    rw [dp_smul]; rw [zero_pow hn]; rw [zero_smul]
#align divided_power_algebra.dp_null DividedPowerAlgebra.dp_null

theorem dp_mul (n p : ℕ) (m : M) : dp R n m * dp R p m = (n + p).choose n • dp R (n + p) m :=
  by
  simp only [dp, mkₐ_eq_mk, ← _root_.map_mul, ← map_nsmul, Ideal.Quotient.eq]
  exact sub_mem_rel_of_rel rel.mul
#align divided_power_algebra.dp_mul DividedPowerAlgebra.dp_mul

theorem dp_add (n : ℕ) (x y : M) :
    dp R n (x + y) = (range (n + 1)).Sum fun k => dp R k x * dp R (n - k) y :=
  by
  simp only [dp, mkₐ_eq_mk, ← _root_.map_mul, ← map_sum, Ideal.Quotient.eq]
  exact sub_mem_rel_of_rel rel.add
#align divided_power_algebra.dp_add DividedPowerAlgebra.dp_add

theorem dp_sum {ι : Type _} [DecidableEq ι] (x : ι → M) (s : Finset ι) (q : ℕ) :
    dp R q (s.Sum x) =
      (Finset.sym s q).Sum fun k => s.Prod fun i => dp R (Multiset.count i k) (x i) :=
  by
  apply DividedPowers.dpow_sum_aux'
  · intro x; rw [dp_zero]
  · intro n x y; rw [dp_add]
  · intro n hn; rw [dp_null R n, if_neg hn]
#align divided_power_algebra.dp_sum DividedPowerAlgebra.dp_sum

theorem dp_sum_smul {ι : Type _} [DecidableEq ι] (a : ι → R) (n : ι → ℕ) (x : ι → M) (s : Finset ι)
    (q : ℕ) :
    dp R q (s.Sum fun i => a i • x i) =
      (Finset.sym s q).Sum fun k =>
        (s.Prod fun i => a i ^ Multiset.count i k) •
          s.Prod fun i => dp R (Multiset.count i k) (x i) :=
  by simp_rw [dp_sum, dp_smul, Algebra.smul_def, map_prod, ← Finset.prod_mul_distrib]
#align divided_power_algebra.dp_sum_smul DividedPowerAlgebra.dp_sum_smul

theorem unique_on_dp {A : Type _} [CommRing A] [Algebra R A] {f g : DividedPowerAlgebra R M →ₐ[R] A}
    (h : ∀ n m, f (dp R n m) = g (dp R n m)) : f = g :=
  by
  rw [FunLike.ext'_iff]
  apply Function.Surjective.injective_comp_right (quotient.mkₐ_surjective R (relI R M))
  simp only [← AlgHom.coe_comp, ← FunLike.ext'_iff]
  exact alg_hom_ext fun ⟨n, m⟩ => h n m
#align divided_power_algebra.unique_on_dp DividedPowerAlgebra.unique_on_dp

section Functoriality

variable (R M)

section lift

variable {A : Type _} [CommRing A] [Algebra R A]

-- General purpose lifting lemma
theorem lift_rel_le_ker (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).Sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩) :
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

/-- General purpose universal property of `divided_power_algebra R M` -/
def liftAux (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).Sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩) :
    DividedPowerAlgebra R M →ₐ[R] A :=
  liftₐ (relI R M) (eval₂AlgHom R f) (lift_rel_le_ker R M f hf_zero hf_smul hf_mul hf_add)
#align divided_power_algebra.lift_aux DividedPowerAlgebra.liftAux

theorem liftAux_eq (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).Sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩)
    (p : MvPolynomial (ℕ × M) R) :
    liftAux R M f hf_zero hf_smul hf_mul hf_add (mkₐ R (relI R M) p) = eval₂ (algebraMap R A) f p :=
  by simp only [lift_aux, mkₐ_eq_mk, liftₐ_apply, lift_mk, AlgHom.coe_toRingHom, coe_eval₂_alg_hom]
#align divided_power_algebra.lift_aux_eq DividedPowerAlgebra.liftAux_eq

theorem liftAux_eq_x (f : ℕ × M → A) (hf_zero : ∀ m, f (0, m) = 1)
    (hf_smul : ∀ (n : ℕ) (r : R) (m : M), f ⟨n, r • m⟩ = r ^ n • f ⟨n, m⟩)
    (hf_mul : ∀ n p m, f ⟨n, m⟩ * f ⟨p, m⟩ = (n + p).choose n • f ⟨n + p, m⟩)
    (hf_add : ∀ n u v, f ⟨n, u + v⟩ = (range (n + 1)).Sum fun x : ℕ => f ⟨x, u⟩ * f ⟨n - x, v⟩)
    (n : ℕ) (m : M) :
    liftAux R M f hf_zero hf_smul hf_mul hf_add (mkₐ R (relI R M) (X (n, m))) = f ⟨n, m⟩ := by
  rw [lift_aux_eq, eval₂_X]
#align divided_power_algebra.lift_aux_eq_X DividedPowerAlgebra.liftAux_eq_x

variable {I : Ideal A} (hI : DividedPowers I) (φ : M →ₗ[R] A) (hφ : ∀ m, φ m ∈ I)

/-- The “universal” property of divided_power_algebra -/
def lift : DividedPowerAlgebra R M →ₐ[R] A :=
  liftAux R M (fun nm => hI.dpow nm.1 (φ nm.2)) (fun m => hI.dpow_zero (hφ m))
    (fun n r m => by
      rw [LinearMap.map_smulₛₗ, RingHom.id_apply, ← algebraMap_smul A r (φ m), smul_eq_mul,
        hI.dpow_smul n (hφ m), ← smul_eq_mul, ← map_pow, algebraMap_smul])
    (fun n p m => by rw [hI.dpow_mul n p (hφ m), ← nsmul_eq_mul]) fun n u v => by
    rw [map_add, hI.dpow_add n (hφ u) (hφ v)]
#align divided_power_algebra.lift DividedPowerAlgebra.lift

variable {φ}

theorem lift_eqₐ (p : MvPolynomial (ℕ × M) R) :
    lift R M hI φ hφ (mkₐ R (relI R M) p) =
      eval₂ (algebraMap R A) (fun nm : ℕ × M => hI.dpow nm.1 (φ nm.2)) p :=
  by rw [lift, lift_aux_eq]
#align divided_power_algebra.lift_eqₐ DividedPowerAlgebra.lift_eqₐ

theorem lift_eq (p : MvPolynomial (ℕ × M) R) :
    lift R M hI φ hφ (mk (relI R M) p) =
      eval₂ (algebraMap R A) (fun nm : ℕ × M => hI.dpow nm.1 (φ nm.2)) p :=
  by rw [← mkₐ_eq_mk R, lift_eqₐ]
#align divided_power_algebra.lift_eq DividedPowerAlgebra.lift_eq

theorem lift_eqₐ_x (n : ℕ) (m : M) :
    lift R M hI φ hφ (mkₐ R (relI R M) (X (n, m))) = hI.dpow n (φ m) := by rw [lift, lift_aux_eq_X]
#align divided_power_algebra.lift_eqₐ_X DividedPowerAlgebra.lift_eqₐ_x

theorem lift_eq_x (n : ℕ) (m : M) : lift R M hI φ hφ (mk (relI R M) (X (n, m))) = hI.dpow n (φ m) :=
  by rw [← mkₐ_eq_mk R, lift_eqₐ_X]
#align divided_power_algebra.lift_eq_X DividedPowerAlgebra.lift_eq_x

theorem lift_dp_eq (n : ℕ) (m : M) : lift R M hI φ hφ (dp R n m) = hI.dpow n (φ m) := by
  rw [dp_eq_mk, lift_eq_X]
#align divided_power_algebra.lift_dp_eq DividedPowerAlgebra.lift_dp_eq

end lift

section Lift'

variable {M}

variable (S : Type _) [CommRing S] [Algebra R S] {N : Type _} [AddCommGroup N] [Module R N]
  [Module S N] [IsScalarTower R S N] [Algebra R (DividedPowerAlgebra S N)]
  [IsScalarTower R S (DividedPowerAlgebra S N)] (f : M →ₗ[R] N)

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

/-- The functoriality map between divided power algebras associated with a linear map of the
  underlying modules. Given an `R`-algebra `S`, an `S`-module `N` and `f : M →ₗ[R] N`, this is the
  map `divided_power_algebra R M →ₐ[R] divided_power_algebra S N` that maps `X(n,m)` to `X(n, f m)`.
-/
def lift' : DividedPowerAlgebra R M →ₐ[R] DividedPowerAlgebra S N :=
  liftₐ (relI R M) _ (lift'_rel_le_ker R S f)
#align divided_power_algebra.lift' DividedPowerAlgebra.lift'

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

end Lift'

end Functoriality

end DividedPowerAlgebra

end

--#lint
