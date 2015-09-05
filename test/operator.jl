#  Copyright 2015, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
#############################################################################
# JuMP
# An algebraic modelling langauge for Julia
# See http://github.com/JuliaOpt/JuMP.jl
#############################################################################
# test/operator.jl
# Testing operator overloading is correct
#############################################################################
using JuMP, FactCheck
using BaseTestNext

# To ensure the tests work on both Windows and Linux/OSX, we need
# to use the correct comparison operators in the strings
const leq = JuMP.repl[:leq]
const geq = JuMP.repl[:geq]
const  eq = JuMP.repl[:eq]

@testset "operator.jl" begin

@testset "overloads" begin
    m = Model()
    @defVar(m, w)
    @defVar(m, x)
    @defVar(m, y)
    @defVar(m, z)
    aff = 7.1 * x + 2.5
    @test affToStr(aff) == "7.1 x + 2.5"
    aff2 = 1.2 * y + 1.2
    @test affToStr(aff2) == "1.2 y + 1.2"
    q = 2.5 * y * z + aff
    @test quadToStr(q) == "2.5 y*z + 7.1 x + 2.5"
    q2 = 8 * x * z + aff2
    @test quadToStr(q2) == "8 x*z + 1.2 y + 1.2"
    q3 = 2 * x * x + 1 * y * y + z + 3
    @test quadToStr(q3) == "2 x² + y² + z + 3"

    nrm = norm([w,1-w])
    @test exprToStr(nrm) == "√(w² + (-w + 1)²)"
    socexpr = 1.5*nrm - 2 - w
    @test exprToStr(socexpr) == "1.5 √(w² + (-w + 1)²) - w - 2"

    @test isequal(3w + 2y, 3w +2y)
    @test !isequal(3w + 2y + 1, 3w + 2y)

    # Different objects that must all interact:
    # 1. Number
    # 2. Variable
    # 3. AffExpr
    # 4. QuadExpr

    # 1. Number tests
    @testset "Number--???" begin
    # 1-1 Number--Number - nope!
    # 1-2 Number--Variable
    @test affToStr(4.13 + w) == "w + 4.13"
    @test affToStr(3.16 - w) == "-w + 3.16"
    @test affToStr(5.23 * w) == "5.23 w"
    @test_throws ErrorException 2.94 / w
    @test conToStr(2.1 ≤ w) == "w $geq 2.1"
    @test conToStr(2.1 == w) == "w $eq 2.1"
    @test conToStr(2.1 ≥ w) == "w $leq 2.1"
    @test conToStr(@LinearConstraint(2.1 ≤ w)) == "-w $leq -2.1"
    @test conToStr(@LinearConstraint(2.1 == w)) == "-w $eq -2.1"
    @test conToStr(@LinearConstraint(2.1 ≥ w)) == "-w $geq -2.1"
    # 1-3 Number--Norm
    @test exprToStr(4.13 + nrm) == "√(w² + (-w + 1)²) + 4.13"
    @test exprToStr(3.16 - nrm) == "-1.0 √(w² + (-w + 1)²) + 3.16"
    @test exprToStr(5.23 * nrm) == "5.23 √(w² + (-w + 1)²)"
    @test_throws MethodError 2.94 / nrm
    @test_throws ErrorException @SOCConstraint(2.1 ≤ nrm)
    @test_throws ErrorException @SOCConstraint(2.1 == nrm)
    @test conToStr(@SOCConstraint(2.1 ≥ nrm)) == "√(w² + (-w + 1)²) $leq 2.1"
    # 1-4 Number--AffExpr
    @test affToStr(1.5 + aff) == "7.1 x + 4"
    @test affToStr(1.5 - aff) == "-7.1 x - 1"
    @test affToStr(2 * aff) == "14.2 x + 5"
    @test_throws ErrorException 2 / aff
    @test conToStr(1 ≤ aff) == "7.1 x $geq -1.5"
    @test conToStr(1 == aff) == "7.1 x $eq -1.5"
    @test conToStr(1 ≥ aff) == "7.1 x $leq -1.5"
    @test conToStr(@LinearConstraint(1 ≤ aff)) == "-7.1 x $leq 1.5"
    @test conToStr(@LinearConstraint(1 == aff)) == "-7.1 x $eq 1.5"
    @test conToStr(@LinearConstraint(1 ≥ aff)) == "-7.1 x $geq 1.5"
    # 1-5 Number--QuadExpr
    @test quadToStr(1.5 + q) == "2.5 y*z + 7.1 x + 4"
    @test quadToStr(1.5 - q) == "-2.5 y*z - 7.1 x - 1"
    @test quadToStr(2 * q) == "5 y*z + 14.2 x + 5"
    @test_throws ErrorException 2 / q
    @test conToStr(1 ≤ q) == "2.5 y*z + 7.1 x + 1.5 $geq 0"
    @test conToStr(1 == q) == "2.5 y*z + 7.1 x + 1.5 $eq 0"
    @test conToStr(1 ≥ q) == "2.5 y*z + 7.1 x + 1.5 $leq 0"
    @test conToStr(@QuadConstraint(1 ≤ q)) == "-2.5 y*z - 7.1 x - 1.5 $leq 0"
    @test conToStr(@QuadConstraint(1 == q)) == "-2.5 y*z - 7.1 x - 1.5 $eq 0"
    @test conToStr(@QuadConstraint(1 ≥ q)) == "-2.5 y*z - 7.1 x - 1.5 $geq 0"
    # 1-6 Number--SOCExpr
    @test exprToStr(1.5 + socexpr) == "1.5 √(w² + (-w + 1)²) - w - 0.5"
    @test exprToStr(1.5 - socexpr) == "-1.5 √(w² + (-w + 1)²) + w + 3.5"
    @test exprToStr(1.5 * socexpr) == "2.25 √(w² + (-w + 1)²) - 1.5 w - 3"
    @test_throws MethodError 1.5 / socexpr
    @test_throws ErrorException @SOCConstraint(2.1 ≤ socexpr)
    @test_throws ErrorException @SOCConstraint(2.1 == socexpr)
    @test conToStr(@SOCConstraint(2.1 ≥ socexpr)) == "1.5 √(w² + (-w + 1)²) $leq w + 4.1"
    end

    # 2. Variable tests
    @testset "Variable--???" begin
    # 2-0 Variable unary
    @test isequal(+x, x)
    @test affToStr(-x) == "-x"
    # 2-1 Variable--Number
    @test affToStr(w + 4.13) == "w + 4.13"
    @test affToStr(w - 4.13) == "w - 4.13"
    @test affToStr(w * 4.13) == "4.13 w"
    @test affToStr(w / 2.00) == "0.5 w"
    @test conToStr(w ≤ 1) == "w $leq 1"
    @test conToStr(w == 1) == "w $eq 1"
    @test conToStr(w ≥ 1) == "w $geq 1"
    @test conToStr(x*y ≤ 1) == "x*y - 1 $leq 0"
    @test conToStr(x*y == 1) == "x*y - 1 $eq 0"
    @test conToStr(x*y ≥ 1) == "x*y - 1 $geq 0"
    @test conToStr(@LinearConstraint(w ≤ 1)) == "w $leq 1"
    @test conToStr(@LinearConstraint(w == 1)) == "w $eq 1"
    @test conToStr(@LinearConstraint(w ≥ 1)) == "w $geq 1"
    @test conToStr(@QuadConstraint(x*y ≤ 1)) == "x*y - 1 $leq 0"
    @test conToStr(@QuadConstraint(x*y == 1)) == "x*y - 1 $eq 0"
    @test conToStr(@QuadConstraint(x*y ≥ 1)) == "x*y - 1 $geq 0"
    # 2-2 Variable--Variable
    @test affToStr(w + x) == "w + x"
    @test affToStr(w - x) == "w - x"
    @test quadToStr(w * x) == "w*x"
    @test affToStr(x - x) == "0"
    @test_throws ErrorException w / x
    @test conToStr(w ≤ x) == "w - x $leq 0"
    @test conToStr(w == x) == "w - x $eq 0"
    @test conToStr(w ≥ x) == "w - x $geq 0"
    @test conToStr(y*z ≤ x) == "y*z - x $leq 0"
    @test conToStr(y*z == x) == "y*z - x $eq 0"
    @test conToStr(y*z ≥ x) == "y*z - x $geq 0"
    @test conToStr(x ≤ x) == "0 $leq 0"
    @test conToStr(x == x) == "0 $eq 0"
    @test conToStr(x ≥ x) == "0 $geq 0"
    @test conToStr(@LinearConstraint(w ≤ x)) == "w - x $leq 0"
    @test conToStr(@LinearConstraint(w == x)) == "w - x $eq 0"
    @test conToStr(@LinearConstraint(w ≥ x)) == "w - x $geq 0"
    @test conToStr(@QuadConstraint(y*z ≤ x)) == "y*z - x $leq 0"
    @test conToStr(@QuadConstraint(y*z == x)) == "y*z - x $eq 0"
    @test conToStr(@QuadConstraint(y*z ≥ x)) == "y*z - x $geq 0"
    @test conToStr(@LinearConstraint(x ≤ x)) == "0 $leq 0"
    @test conToStr(@LinearConstraint(x == x)) == "0 $eq 0"
    @test conToStr(@LinearConstraint(x ≥ x)) == "0 $geq 0"
    # 2-3 Variable--Norm
    @test exprToStr(w + nrm) == "√(w² + (-w + 1)²) + w"
    @test exprToStr(w - nrm) == "-1.0 √(w² + (-w + 1)²) + w"
    @test_throws MethodError w * nrm
    @test_throws MethodError w / nrm
    @test_throws ErrorException @SOCConstraint(w ≤ nrm)
    @test_throws ErrorException @SOCConstraint(w == nrm)
    @test conToStr(@SOCConstraint(w ≥ nrm)) == "√(w² + (-w + 1)²) $leq w"
    # 2-4 Variable--AffExpr
    @test affToStr(z + aff) == "7.1 x + z + 2.5"
    @test affToStr(z - aff) == "-7.1 x + z - 2.5"
    @test quadToStr(z * aff) == "7.1 x*z + 2.5 z"
    @test_throws ErrorException z / aff
    @test conToStr(z ≤ aff) == "-7.1 x + z $leq 2.5"
    @test conToStr(z == aff) == "-7.1 x + z $eq 2.5"
    @test conToStr(z ≥ aff) == "-7.1 x + z $geq 2.5"
    @test conToStr(7.1 * x - aff ≤ 0) == "0 $leq 2.5"
    @test conToStr(7.1 * x - aff == 0) == "0 $eq 2.5"
    @test conToStr(7.1 * x - aff ≥ 0) == "0 $geq 2.5"
    @test conToStr(@LinearConstraint(z ≤ aff)) == "z - 7.1 x $leq 2.5"
    @test conToStr(@LinearConstraint(z == aff)) == "z - 7.1 x $eq 2.5"
    @test conToStr(@LinearConstraint(z ≥ aff)) == "z - 7.1 x $geq 2.5"
    @test conToStr(@LinearConstraint(7.1 * x - aff ≤ 0)) == "0 $leq 2.5"
    @test conToStr(@LinearConstraint(7.1 * x - aff == 0)) == "0 $eq 2.5"
    @test conToStr(@LinearConstraint(7.1 * x - aff ≥ 0)) == "0 $geq 2.5"
    # 2-5 Variable--QuadExpr
    @test quadToStr(w + q) == "2.5 y*z + 7.1 x + w + 2.5"
    @test quadToStr(w - q) == "-2.5 y*z - 7.1 x + w - 2.5"
    @test_throws ErrorException w*q
    @test_throws ErrorException w/q
    @test conToStr(w ≤ q) == "-2.5 y*z - 7.1 x + w - 2.5 $leq 0"
    @test conToStr(w == q) == "-2.5 y*z - 7.1 x + w - 2.5 $eq 0"
    @test conToStr(w ≥ q) == "-2.5 y*z - 7.1 x + w - 2.5 $geq 0"
    @test conToStr(@QuadConstraint(w ≤ q)) == "-2.5 y*z + w - 7.1 x - 2.5 $leq 0"
    @test conToStr(@QuadConstraint(w == q)) == "-2.5 y*z + w - 7.1 x - 2.5 $eq 0"
    @test conToStr(@QuadConstraint(w ≥ q)) == "-2.5 y*z + w - 7.1 x - 2.5 $geq 0"
    # 2-6 Variable--SOCExpr
    @test exprToStr(y + socexpr) == "1.5 √(w² + (-w + 1)²) - w + y - 2"
    @test exprToStr(y - socexpr) == "-1.5 √(w² + (-w + 1)²) + w + y + 2"
    @test_throws MethodError y * socexpr
    @test_throws MethodError y / socexpr
    @test_throws ErrorException @SOCConstraint(y ≤ socexpr)
    @test_throws ErrorException @SOCConstraint(y == socexpr)
    @test conToStr(@SOCConstraint(y ≥ socexpr)) == "1.5 √(w² + (-w + 1)²) $leq y + w + 2"
    end

    # 3. Norm tests
    @testset "Norm--???" begin
    # 3-0 Norm unary
    @test exprToStr(+nrm) == "√(w² + (-w + 1)²)"
    @test exprToStr(-nrm) == "-1.0 √(w² + (-w + 1)²)"
    # 3-1 Norm--Number
    @test exprToStr(nrm + 1.5) == "√(w² + (-w + 1)²) + 1.5"
    @test exprToStr(nrm - 1.5) == "√(w² + (-w + 1)²) - 1.5"
    @test exprToStr(nrm * 1.5) == "1.5 √(w² + (-w + 1)²)"
    @test exprToStr(nrm / 1.5) == "0.6666666666666666 √(w² + (-w + 1)²)"
    @test conToStr(@SOCConstraint(nrm ≤ 1.5)) == "√(w² + (-w + 1)²) $leq 1.5"
    @test_throws ErrorException @SOCConstraint(nrm == 1.5)
    @test_throws ErrorException @SOCConstraint(nrm ≥ 1.5)
    # 3-2 Norm--Variable
    @test exprToStr(nrm + w) == "√(w² + (-w + 1)²) + w"
    @test exprToStr(nrm - w) == "√(w² + (-w + 1)²) - w"
    @test_throws MethodError nrm * w
    @test_throws MethodError nrm / w
    @test conToStr(@SOCConstraint(nrm ≤ w)) == "√(w² + (-w + 1)²) $leq w"
    @test_throws MethodError conToStr(nrm == w)
    @test_throws MethodError conToStr(nrm ≥ w)
    # 3-3 Norm--Norm
    @test_throws MethodError nrm + nrm
    @test_throws MethodError nrm - nrm
    @test_throws MethodError nrm * nrm
    @test_throws MethodError nrm / nrm
    @test_throws MethodError @SOCConstraint(nrm ≤ nrm)
    @test_throws MethodError @SOCConstraint(nrm == nrm)
    @test_throws MethodError @SOCConstraint(nrm ≥ nrm)
    # 3-4 Norm--AffExpr
    @test exprToStr(nrm + aff) == "√(w² + (-w + 1)²) + 7.1 x + 2.5"
    @test exprToStr(nrm - aff) == "√(w² + (-w + 1)²) - 7.1 x - 2.5"
    @test_throws MethodError nrm * aff
    @test_throws MethodError nrm / aff
    @test conToStr(@SOCConstraint(nrm ≤ aff)) == "√(w² + (-w + 1)²) $leq 7.1 x + 2.5"
    @test_throws ErrorException @SOCConstraint(nrm == aff)
    @test_throws ErrorException @SOCConstraint(nrm ≥ aff)
    # 3-5 Norm--QuadExpr
    @test_throws MethodError nrm + q
    @test_throws MethodError nrm - q
    @test_throws MethodError nrm * q
    @test_throws MethodError nrm / q
    @test_throws MethodError @SOCConstraint(nrm ≤ q)
    @test_throws MethodError @SOCConstraint(nrm == q)
    @test_throws MethodError @SOCConstraint(nrm ≥ q)
    # 3-6 Norm--SOCExpr
    @test_throws MethodError nrm + socexpr
    @test_throws MethodError nrm - socexpr
    @test_throws MethodError nrm * socexpr
    @test_throws MethodError nrm / socexpr
    @test_throws MethodError @SOCConstraint(nrm ≤ socexpr)
    @test_throws MethodError @SOCConstraint(nrm == socexpr)
    @test_throws MethodError @SOCConstraint(nrm ≥ socexpr)
    end

    # 4. AffExpr tests
    @testset "AffExpr--???" begin
    # 4-0 AffExpr unary
    @test affToStr(+aff) == "7.1 x + 2.5"
    @test affToStr(-aff) == "-7.1 x - 2.5"
    # 4-1 AffExpr--Number
    @test affToStr(aff + 1.5) == "7.1 x + 4"
    @test affToStr(aff - 1.5) == "7.1 x + 1"
    @test affToStr(aff * 2) == "14.2 x + 5"
    @test affToStr(aff / 2) == "3.55 x + 1.25"
    @test conToStr(aff ≤ 1) == "7.1 x $leq -1.5"
    @test conToStr(aff == 1) == "7.1 x $eq -1.5"
    @test conToStr(aff ≥ 1) == "7.1 x $geq -1.5"
    @test conToStr(@LinearConstraint(aff ≤ 1)) == "7.1 x $leq -1.5"
    @test conToStr(@LinearConstraint(aff == 1)) == "7.1 x $eq -1.5"
    @test conToStr(@LinearConstraint(aff ≥ 1)) == "7.1 x $geq -1.5"
    # 4-2 AffExpr--Variable
    @test affToStr(aff + z) == "7.1 x + z + 2.5"
    @test affToStr(aff - z) == "7.1 x - z + 2.5"
    @test quadToStr(aff * z) == "7.1 x*z + 2.5 z"
    @test_throws ErrorException aff/z
    @test conToStr(aff ≤ z) == "7.1 x - z $leq -2.5"
    @test conToStr(aff == z) == "7.1 x - z $eq -2.5"
    @test conToStr(aff ≥ z) == "7.1 x - z $geq -2.5"
    @test conToStr(aff - 7.1 * x ≤ 0) == "0 $leq -2.5"
    @test conToStr(aff - 7.1 * x == 0) == "0 $eq -2.5"
    @test conToStr(aff - 7.1 * x ≥ 0) == "0 $geq -2.5"
    @test conToStr(@LinearConstraint(aff ≤ z)) == "7.1 x - z $leq -2.5"
    @test conToStr(@LinearConstraint(aff == z)) == "7.1 x - z $eq -2.5"
    @test conToStr(@LinearConstraint(aff ≥ z)) == "7.1 x - z $geq -2.5"
    @test conToStr(@LinearConstraint(aff - 7.1 * x ≤ 0)) == "0 $leq -2.5"
    @test conToStr(@LinearConstraint(aff - 7.1 * x == 0)) == "0 $eq -2.5"
    @test conToStr(@LinearConstraint(aff - 7.1 * x ≥ 0)) == "0 $geq -2.5"
    # 4-3 AffExpr--Norm
    @test exprToStr(aff + nrm) == "√(w² + (-w + 1)²) + 7.1 x + 2.5"
    @test exprToStr(aff - nrm) == "-1.0 √(w² + (-w + 1)²) + 7.1 x + 2.5"
    @test_throws MethodError aff * nrm
    @test_throws MethodError aff / nrm
    @test_throws ErrorException @SOCConstraint(aff ≤ nrm)
    @test_throws ErrorException @SOCConstraint(aff == nrm)
    @test conToStr(@SOCConstraint(aff ≥ nrm)) == "√(w² + (-w + 1)²) $leq 7.1 x + 2.5"
    # 4-4 AffExpr--AffExpr
    @test affToStr(aff + aff2) == "7.1 x + 1.2 y + 3.7"
    @test affToStr(aff - aff2) == "7.1 x - 1.2 y + 1.3"
    @test quadToStr(aff * aff2) == "8.52 x*y + 3 y + 8.52 x + 3"
    @test quadToStr((x+x)*(x+3)) == quadToStr((x+3)*(x+x))  # Issue #288
    @test_throws ErrorException aff/aff2
    @test conToStr(aff ≤ aff2) == "7.1 x - 1.2 y $leq -1.3"
    @test conToStr(aff == aff2) == "7.1 x - 1.2 y $eq -1.3"
    @test conToStr(aff ≥ aff2) == "7.1 x - 1.2 y $geq -1.3"
    @test conToStr(aff-aff ≤ 0) == "0 $leq 0"
    @test conToStr(aff-aff == 0) == "0 $eq 0"
    @test conToStr(aff-aff ≥ 0) == "0 $geq 0"
    @test conToStr(@LinearConstraint(aff ≤ aff2)) == "7.1 x - 1.2 y $leq -1.3"
    @test conToStr(@LinearConstraint(aff == aff2)) == "7.1 x - 1.2 y $eq -1.3"
    @test conToStr(@LinearConstraint(aff ≥ aff2)) == "7.1 x - 1.2 y $geq -1.3"
    @test conToStr(@LinearConstraint(aff-aff ≤ 0)) == "0 $leq 0"
    @test conToStr(@LinearConstraint(aff-aff == 0)) == "0 $eq 0"
    @test conToStr(@LinearConstraint(aff-aff ≥ 0)) == "0 $geq 0"
    # 4-5 AffExpr--QuadExpr
    @test quadToStr(aff2 + q) == "2.5 y*z + 1.2 y + 7.1 x + 3.7"
    @test quadToStr(aff2 - q) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3"
    @test_throws ErrorException aff2 * q
    @test_throws ErrorException aff2 / q
    @test conToStr(aff2 ≤ q) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $leq 0"
    @test conToStr(aff2 == q) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $eq 0"
    @test conToStr(aff2 ≥ q) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $geq 0"
    @test conToStr(@QuadConstraint(aff2 ≤ q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $leq 0"
    @test conToStr(@QuadConstraint(aff2 == q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $eq 0"
    @test conToStr(@QuadConstraint(aff2 ≥ q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $geq 0"
    # 4-6 AffExpr--SOCExpr
    @test exprToStr(aff + socexpr) == "1.5 √(w² + (-w + 1)²) + 7.1 x - w + 0.5"
    @test exprToStr(aff - socexpr) == "-1.5 √(w² + (-w + 1)²) + 7.1 x + w + 4.5"
    @test_throws MethodError aff * socexpr
    @test_throws MethodError aff / socexpr
    @test_throws ErrorException @SOCConstraint(aff ≤ socexpr)
    @test_throws ErrorException @SOCConstraint(aff == socexpr)
    @test conToStr(@SOCConstraint(aff ≥ socexpr)) == "1.5 √(w² + (-w + 1)²) $leq 7.1 x + w + 4.5"
    end

    # 5. QuadExpr
    @testset "QuadExpr--???" begin
    # 5-0 QuadExpr unary
    @test quadToStr(+q) == "2.5 y*z + 7.1 x + 2.5"
    @test quadToStr(-q) == "-2.5 y*z - 7.1 x - 2.5"
    # 5-1 QuadExpr--Number
    @test quadToStr(q + 1.5) == "2.5 y*z + 7.1 x + 4"
    @test quadToStr(q - 1.5) == "2.5 y*z + 7.1 x + 1"
    @test quadToStr(q * 2) == "5 y*z + 14.2 x + 5"
    @test quadToStr(q / 2) == "1.25 y*z + 3.55 x + 1.25"
    @test conToStr(q ≥ 1) == "2.5 y*z + 7.1 x + 1.5 $geq 0"
    @test conToStr(q == 1) == "2.5 y*z + 7.1 x + 1.5 $eq 0"
    @test conToStr(q ≤ 1) == "2.5 y*z + 7.1 x + 1.5 $leq 0"
    @test conToStr(@QuadConstraint(aff2 ≤ q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $leq 0"
    @test conToStr(@QuadConstraint(aff2 == q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $eq 0"
    @test conToStr(@QuadConstraint(aff2 ≥ q)) == "-2.5 y*z + 1.2 y - 7.1 x - 1.3 $geq 0"
    # 5-2 QuadExpr--Variable
    @test quadToStr(q + w) == "2.5 y*z + 7.1 x + w + 2.5"
    @test quadToStr(q - w) == "2.5 y*z + 7.1 x - w + 2.5"
    @test_throws ErrorException q*w
    @test_throws ErrorException q/w
    @test conToStr(q ≤ w) == "2.5 y*z + 7.1 x - w + 2.5 $leq 0"
    @test conToStr(q == w) == "2.5 y*z + 7.1 x - w + 2.5 $eq 0"
    @test conToStr(q ≥ w) == "2.5 y*z + 7.1 x - w + 2.5 $geq 0"
    @test conToStr(@QuadConstraint(q ≤ w)) == "2.5 y*z + 7.1 x - w + 2.5 $leq 0"
    @test conToStr(@QuadConstraint(q == w)) == "2.5 y*z + 7.1 x - w + 2.5 $eq 0"
    @test conToStr(@QuadConstraint(q ≥ w)) == "2.5 y*z + 7.1 x - w + 2.5 $geq 0"
    # 5-3 QuadExpr--Norm
    @test_throws MethodError q + nrm
    @test_throws MethodError q - nrm
    @test_throws MethodError q * nrm
    @test_throws MethodError q / nrm
    @test_throws MethodError @SOCConstraint(q ≤ nrm)
    @test_throws MethodError @SOCConstraint(q == nrm)
    @test_throws MethodError @SOCConstraint(q ≥ nrm)
    # 5-4 QuadExpr--AffExpr
    @test quadToStr(q + aff2) == "2.5 y*z + 7.1 x + 1.2 y + 3.7"
    @test quadToStr(q - aff2) == "2.5 y*z + 7.1 x - 1.2 y + 1.3"
    @test_throws ErrorException  q * aff2
    @test_throws ErrorException  q / aff2
    @test conToStr(q ≤ aff2) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $leq 0"
    @test conToStr(q == aff2) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $eq 0"
    @test conToStr(q ≥ aff2) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $geq 0"
    @test conToStr(@QuadConstraint(q ≤ aff2)) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $leq 0"
    @test conToStr(@QuadConstraint(q == aff2)) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $eq 0"
    @test conToStr(@QuadConstraint(q ≥ aff2)) == "2.5 y*z + 7.1 x - 1.2 y + 1.3 $geq 0"
    # 5-5 QuadExpr--QuadExpr
    @test quadToStr(q + q2) == "8 x*z + 2.5 y*z + 7.1 x + 1.2 y + 3.7"
    @test quadToStr(q - q2) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3"
    @test_throws ErrorException  q * q2
    @test_throws ErrorException  q / q2
    @test conToStr(q ≤ q2) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $leq 0"
    @test conToStr(q == q2) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $eq 0"
    @test conToStr(q ≥ q2) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $geq 0"
    @test conToStr(@QuadConstraint(q ≤ q2)) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $leq 0"
    @test conToStr(@QuadConstraint(q == q2)) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $eq 0"
    @test conToStr(@QuadConstraint(q ≥ q2)) == "-8 x*z + 2.5 y*z + 7.1 x - 1.2 y + 1.3 $geq 0"
    # 4-6 QuadExpr--SOCExpr
    @test_throws MethodError q + socexpr
    @test_throws MethodError q - socexpr
    @test_throws MethodError q * socexpr
    @test_throws MethodError q / socexpr
    @test_throws MethodError @SOCConstraint(q ≤ socexpr)
    @test_throws MethodError @SOCConstraint(q == socexpr)
    @test_throws MethodError @SOCConstraint(q ≥ socexpr)
    end

    # 6. SOCExpr tests
    @testset "SOCExpr--???" begin
    # 6-0 SOCExpr unary
    @test exprToStr(+socexpr) == "1.5 √(w² + (-w + 1)²) - w - 2"
    @test exprToStr(-socexpr) == "-1.5 √(w² + (-w + 1)²) + w + 2"
    # 6-1 SOCExpr--Number
    @test exprToStr(socexpr + 1.5) == "1.5 √(w² + (-w + 1)²) - w - 0.5"
    @test exprToStr(socexpr - 1.5) == "1.5 √(w² + (-w + 1)²) - w - 3.5"
    @test exprToStr(socexpr * 1.5) == "2.25 √(w² + (-w + 1)²) - 1.5 w - 3"
    @test exprToStr(socexpr / 1.5) == "√(w² + (-w + 1)²) - 0.6666666666666666 w - 1.3333333333333333"
    @test conToStr(@SOCConstraint(socexpr ≤ 1.5)) == "1.5 √(w² + (-w + 1)²) $leq w + 3.5"
    @test_throws ErrorException @SOCConstraint(socexpr == 1.5)
    @test_throws ErrorException @SOCConstraint(socexpr ≥ 1.5)
    # 6-2 SOCExpr--Variable
    @test exprToStr(socexpr + y) == "1.5 √(w² + (-w + 1)²) - w + y - 2"
    @test exprToStr(socexpr - y) == "1.5 √(w² + (-w + 1)²) - w - y - 2"
    @test_throws MethodError socexpr * y
    @test_throws MethodError socexpr / y
    @test conToStr(@SOCConstraint(socexpr ≤ y)) == "1.5 √(w² + (-w + 1)²) $leq w + y + 2"
    @test_throws MethodError conToStr(socexpr == y)
    @test_throws MethodError conToStr(socexpr ≥ y)
    # 6-3 SOCExpr--Norm
    @test_throws MethodError socexpr + nrm
    @test_throws MethodError socexpr - nrm
    @test_throws MethodError socexpr * nrm
    @test_throws MethodError socexpr / nrm
    @test_throws MethodError @SOCConstraint(socexpr ≤ nrm)
    @test_throws MethodError @SOCConstraint(socexpr == nrm)
    @test_throws MethodError @SOCConstraint(socexpr ≥ nrm)
    # 6-4 SOCExpr--AffExpr
    @test exprToStr(socexpr + aff) == "1.5 √(w² + (-w + 1)²) - w + 7.1 x + 0.5"
    @test exprToStr(socexpr - aff) == "1.5 √(w² + (-w + 1)²) - w - 7.1 x - 4.5"
    @test_throws MethodError socexpr * aff
    @test_throws MethodError socexpr / aff
    @test conToStr(@SOCConstraint(socexpr ≤ aff)) == "1.5 √(w² + (-w + 1)²) $leq w + 7.1 x + 4.5"
    @test_throws ErrorException @SOCConstraint(socexpr == aff)
    @test_throws ErrorException @SOCConstraint(socexpr ≥ aff)
    # 6-5 SOCExpr--QuadExpr
    @test_throws MethodError socexpr + q
    @test_throws MethodError socexpr - q
    @test_throws MethodError socexpr * q
    @test_throws MethodError socexpr / q
    @test_throws MethodError @SOCConstraint(socexpr ≤ q)
    @test_throws MethodError @SOCConstraint(socexpr == q)
    @test_throws MethodError @SOCConstraint(socexpr ≥ q)
    # 6-6 SOCExpr--SOCExpr
    @test_throws MethodError socexpr + socexpr
    @test_throws MethodError socexpr - socexpr
    @test_throws MethodError socexpr * socexpr
    @test_throws MethodError socexpr / socexpr
    @test_throws MethodError @SOCConstraint(socexpr ≤ socexpr)
    @test_throws MethodError @SOCConstraint(socexpr == socexpr)
    @test_throws MethodError @SOCConstraint(socexpr ≥ socexpr)
    end
end

@testset "Higher-level operators" begin
    @testset "sum" begin
        sum_m = Model()
        @defVar(sum_m, 0 ≤ matrix[1:3,1:3] ≤ 1, start = 1)
        # sum(j::JuMPArray{Variable})
        @test affToStr(sum(matrix)) == "matrix[1,1] + matrix[2,1] + matrix[3,1] + matrix[1,2] + matrix[2,2] + matrix[3,2] + matrix[1,3] + matrix[2,3] + matrix[3,3]"
        # sum(j::JuMPArray{Variable}) in a macro
        @setObjective(sum_m, Max, sum(matrix))
        @test quadToStr(sum_m.obj) == "matrix[1,1] + matrix[2,1] + matrix[3,1] + matrix[1,2] + matrix[2,2] + matrix[3,2] + matrix[1,3] + matrix[2,3] + matrix[3,3]"

        # sum{T<:Real}(j::JuMPArray{T})
        @test isapprox(sum(getValue(matrix)), 9, atol=1e-6)
        # sum(j::Array{Variable})
        @test affToStr(sum(matrix[1:3,1:3])) == affToStr(sum(matrix))
        # sum(affs::Array{AffExpr})
        @test affToStr(sum([2*matrix[i,j] for i in 1:3, j in 1:3])) == "2 matrix[1,1] + 2 matrix[2,1] + 2 matrix[3,1] + 2 matrix[1,2] + 2 matrix[2,2] + 2 matrix[3,2] + 2 matrix[1,3] + 2 matrix[2,3] + 2 matrix[3,3]"

        S = [1,3]
        @defVar(sum_m, x[S], start=1)
        # sum(j::JuMPDict{Variable})
        @test length(affToStr(sum(x))) == 11 # order depends on hashing
        @test contains(affToStr(sum(x)),"x[1]")
        @test contains(affToStr(sum(x)),"x[3]")
        # sum{T<:Real}(j::JuMPDict{T})
        @test sum(getValue(x)) == 2
    end
end

end
error()

context("dot") do
    dot_m = Model()
    @defVar(dot_m, 0 ≤ x[1:3] ≤ 1)
    c = vcat(1:3)
    @fact affToStr(dot(c,x)) --> "x[1] + 2 x[2] + 3 x[3]"
    @fact affToStr(dot(x,c)) --> "x[1] + 2 x[2] + 3 x[3]"

    A = [1 3 ; 2 4]
    @defVar(dot_m, 1 ≤ y[1:2,1:2] ≤ 1)
    @fact affToStr(vecdot(A,y)) --> "y[1,1] + 2 y[2,1] + 3 y[1,2] + 4 y[2,2]"
    @fact affToStr(vecdot(y,A)) --> "y[1,1] + 2 y[2,1] + 3 y[1,2] + 4 y[2,2]"

    B = ones(2,2,2)
    @defVar(dot_m, 0 ≤ z[1:2,1:2,1:2] ≤ 1)
    @fact affToStr(vecdot(B,z)) --> "z[1,1,1] + z[2,1,1] + z[1,2,1] + z[2,2,1] + z[1,1,2] + z[2,1,2] + z[1,2,2] + z[2,2,2]"
    @fact affToStr(vecdot(z,B)) --> "z[1,1,1] + z[2,1,1] + z[1,2,1] + z[2,2,1] + z[1,1,2] + z[2,1,2] + z[1,2,2] + z[2,2,2]"

    @setObjective(dot_m, Max, dot(x, ones(3)) - vecdot(y, ones(2,2)) )
    #solve(dot_m)
    for i in 1:3
        setValue(x[i], 1)
    end
    for i in 1:2, j in 1:2
        setValue(y[i,j], 1)
    end
    @fact dot(c, getValue(x)) --> roughly( 6, 1e-6)
    @fact vecdot(A, getValue(y)) --> roughly(10, 1e-6)
end
end

module TestHelper # weird scoping behavior with FactCheck...
    using JuMP
    _lt(x,y) = (x.col < y.col)
    function sort_expr!(x::AffExpr)
        idx = sortperm(x.vars, lt=_lt)
        x.vars = x.vars[idx]
        x.coeffs = x.coeffs[idx]
        return x
    end

    vec_eq(x,y) = vec_eq([x;], [y;])

    function vec_eq(x::Array, y::Array)
        size(x) == size(y) || return false
        for i in 1:length(x)
            v, w = convert(AffExpr,x[i]), convert(AffExpr,y[i])
            sort_expr!(v)
            sort_expr!(w)
            affToStr(v) == affToStr(w) || return false
        end
        return true
    end

    function vec_eq(x::Array{QuadExpr}, y::Array{QuadExpr})
        size(x) == size(y) || return false
        for i in 1:length(x)
            quadToStr(x[i]) == quadToStr(y[i]) || return false
        end
        return true
    end
end

facts("Vectorized operations") do

context("Transpose") do
    m = Model()
    @defVar(m, x[1:3])
    @defVar(m, y[1:2,1:3])
    @defVar(m, z[2:5])
    @fact TestHelper.vec_eq(x', [x[1] x[2] x[3]]) --> true
    @fact TestHelper.vec_eq(transpose(x), [x[1] x[2] x[3]]) --> true
    @fact TestHelper.vec_eq(y', [y[1,1] y[2,1]
                      y[1,2] y[2,2]
                      y[1,3] y[2,3]]) --> true
    @fact TestHelper.vec_eq(transpose(y),
                [y[1,1] y[2,1]
                 y[1,2] y[2,2]
                 y[1,3] y[2,3]]) --> true
    @fact_throws z'
    @fact_throws transpose(z)
end

context("Vectorized arithmetic") do
    m = Model()
    @defVar(m, x[1:3])
    A = [2 1 0
         1 2 1
         0 1 2]
    @fact TestHelper.vec_eq(A*x, [2x[1] +  x[2]
                        2x[2] + x[1] + x[3]
                        x[2] + 2x[3]]) --> true
    @fact TestHelper.vec_eq(x'*A, [2x[1]+x[2]; 2x[2]+x[1]+x[3]; x[2]+2x[3]]') --> true
    @fact TestHelper.vec_eq(x'*A*x, [2x[1]*x[1] + 2x[1]*x[2] + 2x[2]*x[2] + 2x[2]*x[3] + 2x[3]*x[3]]) --> true

    y = A*x
    @fact TestHelper.vec_eq(-x, [-x[1], -x[2], -x[3]]) --> true
    @fact TestHelper.vec_eq(-y, [-2x[1] -  x[2]
                       -x[1] - 2x[2] -  x[3]
                               -x[2] - 2x[3]]) --> true
    @fact TestHelper.vec_eq(y + 1, [2x[1] +  x[2]         + 1
                          x[1] + 2x[2] +  x[3] + 1
                                  x[2] + 2x[3] + 1]) --> true
    @fact TestHelper.vec_eq(y - 1, [2x[1] +  x[2]         - 1
                          x[1] + 2x[2] +  x[3] - 1
                                  x[2] + 2x[3] - 1]) --> true
    @fact TestHelper.vec_eq(y + 2ones(3), [2x[1] +  x[2]         + 2
                                 x[1] + 2x[2] +  x[3] + 2
                                         x[2] + 2x[3] + 2]) --> true
    @fact TestHelper.vec_eq(y - 2ones(3), [2x[1] +  x[2]         - 2
                                 x[1] + 2x[2] +  x[3] - 2
                                         x[2] + 2x[3] - 2]) --> true
    @fact TestHelper.vec_eq(2ones(3) + y, [2x[1] +  x[2]         + 2
                                 x[1] + 2x[2] +  x[3] + 2
                                         x[2] + 2x[3] + 2]) --> true
    @fact TestHelper.vec_eq(2ones(3) - y, [-2x[1] -  x[2]         + 2
                                 -x[1] - 2x[2] -  x[3] + 2
                                         -x[2] - 2x[3] + 2]) --> true
    @fact TestHelper.vec_eq(y + x, [3x[1] +  x[2]
                          x[1] + 3x[2] +  x[3]
                                  x[2] + 3x[3]]) --> true
    @fact TestHelper.vec_eq(x + y, [3x[1] +  x[2]
                          x[1] + 3x[2] +  x[3]
                                  x[2] + 3x[3]]) --> true
    @fact TestHelper.vec_eq(2y + 2x, [6x[1] + 2x[2]
                           2x[1] + 6x[2] + 2x[3]
                                   2x[2] + 6x[3]]) --> true
    @fact TestHelper.vec_eq(y - x, [ x[1] + x[2]
                          x[1] + x[2] + x[3]
                                 x[2] + x[3]]) --> true
    @fact TestHelper.vec_eq(x - y, [-x[1] - x[2]
                         -x[1] - x[2] - x[3]
                                -x[2] - x[3]]) --> true
    @fact TestHelper.vec_eq(y + x[:], [3x[1] +  x[2]
                             x[1] + 3x[2] +  x[3]
                                     x[2] + 3x[3]]) --> true
    @fact TestHelper.vec_eq(x[:] + y, [3x[1] +  x[2]
                             x[1] + 3x[2] +  x[3]
                                     x[2] + 3x[3]]) --> true
end

context("Dot-ops") do
    m = Model()
    @defVar(m, x[1:2,1:2])
    A = [1 2;
         3 4]
    @fact TestHelper.vec_eq(A.+x, [1+x[1,1]  2+x[1,2];
                                   3+x[2,1]  4+x[2,2]]) --> true
    @fact TestHelper.vec_eq(x.+A, [1+x[1,1]  2+x[1,2];
                                   3+x[2,1]  4+x[2,2]]) --> true
    @fact TestHelper.vec_eq(A.-x, [1-x[1,1]  2-x[1,2];
                                   3-x[2,1]  4-x[2,2]]) --> true
    @fact TestHelper.vec_eq(x.-A, [-1+x[1,1]  -2+x[1,2];
                                   -3+x[2,1]  -4+x[2,2]]) --> true
    @fact TestHelper.vec_eq(A.*x, [1*x[1,1]  2*x[1,2];
                                   3*x[2,1]  4*x[2,2]]) --> true
    @fact TestHelper.vec_eq(x.*A, [1*x[1,1]  2*x[1,2];
                                   3*x[2,1]  4*x[2,2]]) --> true
    @fact_throws TestHelper.vec_eq(A./x, [1*x[1,1]  2*x[1,2];
                                          3*x[2,1]  4*x[2,2]])
    @fact TestHelper.vec_eq(x./A, [1/1*x[1,1]  1/2*x[1,2];
                                   1/3*x[2,1]  1/4*x[2,2]]) --> true

end

context("Vectorized comparisons") do
    m = Model()
    @defVar(m, x[1:3])
    A = [1 2 3
         0 4 5
         6 0 7]
    @addConstraint(m, x'*A*x .>= 1)
    @fact TestHelper.vec_eq(m.quadconstr[1].terms, [x[1]*x[1] + 2x[1]*x[2] + 4x[2]*x[2] + 9x[1]*x[3] + 5x[2]*x[3] + 7x[3]*x[3] - 1]) --> true
    @fact m.quadconstr[1].sense --> :(>=)

    mat = [ 3x[1] + 12x[3] +  4x[2]
            2x[1] + 12x[2] + 10x[3]
           15x[1] +  5x[2] + 21x[3]]

    @addConstraint(m, (x'A)' + 2A*x .<= 1)
    terms = map(v->v.terms, m.linconstr[1:3])
    lbs   = map(v->v.lb,    m.linconstr[1:3])
    ubs   = map(v->v.ub,    m.linconstr[1:3])
    @fact TestHelper.vec_eq(terms, mat) --> true
    @fact lbs --> fill(-Inf, 3)
    @fact ubs --> fill(   1, 3)

    @addConstraint(m, -1 .<= (x'A)' + 2A*x .<= 1)
    terms = map(v->v.terms, m.linconstr[4:6])
    lbs   = map(v->v.lb,    m.linconstr[4:6])
    ubs   = map(v->v.ub,    m.linconstr[4:6])
    @fact TestHelper.vec_eq(terms, mat) --> true
    @fact lbs --> fill(-1, 3)
    @fact ubs --> fill( 1, 3)

    @addConstraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= 1)
    terms = map(v->v.terms, m.linconstr[7:9])
    lbs   = map(v->v.lb,    m.linconstr[7:9])
    ubs   = map(v->v.ub,    m.linconstr[7:9])
    @fact TestHelper.vec_eq(terms, mat) --> true
    @fact lbs --> -[1:3;]
    @fact ubs --> fill( 1, 3)

    @addConstraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= [3:-1:1;])
    terms = map(v->v.terms, m.linconstr[10:12])
    lbs   = map(v->v.lb,    m.linconstr[10:12])
    ubs   = map(v->v.ub,    m.linconstr[10:12])
    @fact TestHelper.vec_eq(terms, mat) --> true
    @fact lbs --> -[1:3;]
    @fact ubs --> [3:-1:1;]

    @addConstraint(m, -[1:3;] .<= (x'A)' + 2A*x .<= 3)
    terms = map(v->v.terms, m.linconstr[13:15])
    lbs   = map(v->v.lb,    m.linconstr[13:15])
    ubs   = map(v->v.ub,    m.linconstr[13:15])
    @fact TestHelper.vec_eq(terms, mat) --> true
    @fact lbs --> -[1:3;]
    @fact ubs --> fill(3,3)
end

end

facts("[operator] JuMPArray concatenation") do
    m = Model()
    @defVar(m, x[1:3])
    @defVar(m, y[1:3,1:3])
    @defVar(m, z[1:1])
    @defVar(m, w[1:1,1:3])

    @fact TestHelper.vec_eq([x y], [x[1] y[1,1] y[1,2] y[1,3]
                                    x[2] y[2,1] y[2,2] y[2,3]
                                    x[3] y[3,1] y[3,2] y[3,3]]) --> true

    @fact TestHelper.vec_eq([x 2y+1], [x[1] 2y[1,1]+1 2y[1,2]+1 2y[1,3]+1
                                       x[2] 2y[2,1]+1 2y[2,2]+1 2y[2,3]+1
                                       x[3] 2y[3,1]+1 2y[3,2]+1 2y[3,3]+1]) --> true

    @fact TestHelper.vec_eq([1 x'], [1 x[1] x[2] x[3]]) --> true
    @fact TestHelper.vec_eq([2x;x], [2x[1],2x[2],2x[3],x[1],x[2],x[3]]) --> true
    # vcat on JuMPArray
    @fact TestHelper.vec_eq([x;x], [x[1],x[2],x[3],x[1],x[2],x[3]]) --> true
    # hcat on JuMPArray
    @fact TestHelper.vec_eq([x x], [x[1] x[1]
                                    x[2] x[2]
                                    x[3] x[3]]) --> true
    # hvcat on JuMPArray
    tmp1 = [z w; x y]
    tmp2 = [z[1] w[1,1] w[1,2] w[1,3]
            x[1] y[1,1] y[1,2] y[1,3]
            x[2] y[2,1] y[2,2] y[2,3]
            x[3] y[3,1] y[3,2] y[3,3]]
    @fact TestHelper.vec_eq(tmp1, tmp2) --> true
    tmp3 = [1 2x'
            x 2y-x*x']
    tmp4 = [1    2x[1]               2x[2]               2x[3]
            x[1] -x[1]*x[1]+2y[1,1]  -x[1]*x[2]+2y[1,2]  -x[1]*x[3] + 2y[1,3]
            x[2] -x[1]*x[2]+2y[2,1]  -x[2]*x[2]+2y[2,2]  -x[2]*x[3] + 2y[2,3]
            x[3] -x[1]*x[3]+2y[3,1]  -x[2]*x[3]+2y[3,2]  -x[3]*x[3] + 2y[3,3]]
    @fact TestHelper.vec_eq(tmp3, tmp4) --> true
end


# The behavior in this test is no longer well-defined
#let
#    dot_m = Model()
#    @defVar(dot_m, 0 <= v[1:3,1:4] <= 1)
#    @defVar(dot_m, 0 <= w[3:2:7,7:-2:1] <= 1)
#    @fact quadToStr(dot(v,w)) --> "v[1,1]*w[3,7] + v[1,2]*w[3,5] + v[1,3]*w[3,3] + v[1,4]*w[3,1] + v[2,1]*w[5,7] + v[2,2]*w[5,5] + v[2,3]*w[5,3] + v[2,4]*w[5,1] + v[3,1]*w[7,7] + v[3,2]*w[7,5] + v[3,3]*w[7,3] + v[3,4]*w[7,1]"
#
#    @addConstraint(dot_m, sum(v) + sum(w) --> 2)
#    @setObjective(dot_m, :Max, v[2,3] + w[5,3])
#    solve(dot_m)
#    @fact dot(getValue(v),getValue(w)) --> 1.0
#end

# Ditto
#let
#    slice_m = Model()
#    C = [:cat,:dog]
#    @defVar(slice_m, x[-1:1,C])
#    catcoef = [1,2,3]
#    dogcoef = [3,4,5]
#
#    @fact affToStr(dot(catcoef, x[:,:cat])) --> "x[-1,cat] + 2 x[0,cat] + 3 x[1,cat]"
#    @fact affToStr(dot(dogcoef, x[:,:dog])) --> "3 x[-1,dog] + 4 x[0,dog] + 5 x[1,dog]"
#end
