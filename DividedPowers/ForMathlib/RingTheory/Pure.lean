/-
Copyright (c) 2025 Antoine Chambert-Loir, María Inés de Frutos-Fernández. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antoine Chambert-Loir, María Inés de Frutos-Fernández
-/

import DividedPowers.ForMathlib.RingTheory.TensorProduct.DirectLimit.FG
import Mathlib.LinearAlgebra.TensorProduct.RightExactness
import Mathlib.Logic.Small.Set
import Mathlib.RingTheory.FiniteType
import Mathlib.RingTheory.Ideal.Quotient.Operations
import Mathlib.LinearAlgebra.Projection

/-! # Pure submodules

* `Submodule.IsPure`

A submodule `N` of an `R`-module is *pure* if all maps `S ⊗[R] N → S ⊗[R] M`
deduced by base change from the injection of `N` into `M` are injective,
for all `R`-algebras `S`.
This is expressed by the class `Submodule.IsPure`.

For type theoretic reason, the definition of `Submodule.IsPure` only considers
algebras `S` in the same universe as `R`, but `Submodule.IsPure.baseChange_injective`
establishes the property for all universes.

* `Submodule.IsComplemented.isPure` : a complemented submodule is pure.

-/

universe u v

-- [Mathlib.Algebra.Algebra.Equiv]
theorem AlgEquiv.self_trans_symm_eq_refl
  {R S S' : Type*} [CommSemiring R] [Semiring S] [Semiring S']
  [Algebra R S] [Algebra R S'] (e : S ≃ₐ[R] S') :
  e.trans e.symm = AlgEquiv.refl := by
  ext s
  simp only [AlgEquiv.trans_apply, AlgEquiv.symm_apply_apply, AlgEquiv.coe_refl, id_eq]

-- [Mathlib.Algebra.Algebra.Equiv]
theorem AlgEquiv.symm_trans_self_eq_refl
  {R S S' : Type*} [CommSemiring R] [Semiring S] [Semiring S']
  [Algebra R S] [Algebra R S'] (e : S ≃ₐ[R] S') :
  e.symm.trans e = AlgEquiv.refl := by
  ext s
  simp only [AlgEquiv.trans_apply, AlgEquiv.apply_symm_apply, AlgEquiv.coe_refl, id_eq]


namespace Submodule

open AlgHom LinearMap Function Submodule MvPolynomial

class IsPure {R : Type u} [CommRing R]
    {M : Type v} [AddCommGroup M] [Module R M] (N : Submodule R M) where
  baseChange_injective' (S : Type u) [CommRing S] [Algebra R S] :
    Injective (N.subtype.baseChange S)

variable {R : Type u} [CommRing R] {M : Type*} [AddCommGroup M] [Module R M]

/-- Complemented submodules are pure -/
theorem _root_.Submodule.IsComplemented.isPure {N : Submodule R M} (hN : IsComplemented N) :
    N.IsPure where
  baseChange_injective' S _ _ := by
    obtain ⟨P, hNP⟩ := hN
    have := Submodule.linearProjOfIsCompl_comp_subtype hNP
    apply Function.Injective.of_comp (f := LinearMap.baseChange S (N.linearProjOfIsCompl P hNP))
    rw [← LinearMap.coe_comp, ← LinearMap.baseChange_comp, this]
    simp only [baseChange_id]
    apply Function.injective_id

namespace IsPure

variable (N : Submodule R M) [N.IsPure]

theorem baseChange_injective (S : Type*) [CommRing S] [Algebra R S] :
    Injective (N.subtype.baseChange S) := by
  rw [← ker_eq_bot, eq_bot_iff]
  intro t
  simp only [mem_ker, Submodule.mem_bot]
  intro ht
  obtain ⟨A, hA, u, hu0, hut⟩ := exists_fg_of_baseChange_eq_zero N.subtype t ht
  have : Small.{u} A := by
    sorry -- hA.small
  set A' := Shrink.{u} A with hA'
  let e : A' ≃ₐ[R] A := Shrink.algEquiv A R
  set u' := LinearMap.rTensor N e.symm.toLinearMap u with hu'
  have hN := IsPure.baseChange_injective' A' (N := N)
  rw [← ker_eq_bot, eq_bot_iff] at hN
  have hu : u = LinearMap.rTensor N e.toLinearMap u' := by
    rw [← LinearMap.rTensor_id_apply N A u]
    simp only [u']
    rw [← LinearMap.comp_apply, ← rTensor_comp, ← AlgEquiv.trans_toLinearMap]
    rw [AlgEquiv.symm_trans_self_eq_refl]
    congr
  suffices u' = 0 by
    simp only [← hut, hu, this, _root_.map_zero]
  rw [← Submodule.mem_bot (R := R)]
  apply hN
  rw [mem_ker, hu']
  rw [← AlgEquiv.toAlgHom_toLinearMap, ← rTensor_comp_baseChange_comm_apply,
    AlgEquiv.toAlgHom_toLinearMap, hu0]
  simp only [_root_.map_zero]


