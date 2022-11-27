% CNP Meta-interpreter / Math library
% Copyright 2022 Görkem Paçacı
% This file is part of CNP Meta-interpreter.
% CNP Meta-interpreter is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
% CNP Meta-interpreter is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
% You should have received a copy of the GNU Lesser General Public License along with CNP Meta-interpreter. If not, see <https://www.gnu.org/licenses/>.


:- module(math, []).
:- multifile cnp:lib/3.

cnp:lib(+,    [a,b,ab], math:plus). % using anonymous predicates
cnp:lib(-,    [a,b,ab], math:minus).
cnp:lib(*,    [a,b,ab], math:times).
cnp:lib(/,    [a,b,ab], math:div).
cnp:lib(eq,   [a,b],    [_{a:A, b:B}] >> (A =:= B)).
cnp:lib(lt,   [a,b],    [_{a:A, b:B}] >> (A<B)).
cnp:lib(lte,  [a,b],    [_{a:A, b:B}] >> (A =< B)).
cnp:lib(flip, [a,b],    math:flip). % optional syntax using predicate name
cnp:lib(neg,  [a],      [_{a:A}] >> (A<0)).
cnp:lib(pos,  [a],      [_{a:A}] >> (A>0)).
cnp:lib(zero, [a],      [_{a:A}] >> (A=0)).
cnp:lib(nil,  [a],      [_{a:A}] >> (A=[])).

flip(_{a:A, b:B}) :-  (ground(B), A is B * -1) ; 
                      (ground(A), B is A * -1).

plus(_{a:A, b:B, ab:AB}) :- (ground(A), ground(B), AB is A+B);
                            (ground(A), ground(AB), B is AB-A);
                            (ground(B), ground(AB), A is AB-B).
minus(_{a:A, b:B, ab:AB}) :- (ground(A), ground(B), AB is A-B);
                             (ground(A), ground(AB), B is A-AB);
                             (ground(B), ground(AB), A is B+AB).
times(_{a:A, b:B, ab:AB}) :- (ground(A), ground(B), AB is A*B);
                             (ground(A), ground(AB), B is AB/A);
                             (ground(B), ground(AB), A is AB/B).
div(_{a:A, b:B, ab:AB}) :- (ground(A), ground(B), AB is A/B);
                           (ground(A), ground(AB), B is A/AB);
                           (ground(B), ground(AB), A is B*AB).