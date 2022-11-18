% CNP Meta-interpreter
% Copyright 2022 Görkem Paçacı
% This file is part of CNP Meta-interpreter.
% CNP Meta-interpreter is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
% CNP Meta-interpreter is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
% You should have received a copy of the GNU Lesser General Public License along with CNP Meta-interpreter. If not, see <https://www.gnu.org/licenses/>.

:- module(cnp, [cnp/2, def/2, lib/3, names/2,
                op(740, xfx, ^), op(741, xfx, \/),
                op(750, xfy, ^.), op(760, xfy, @)]).

% def(_Name, _Body). allowing user-defined predicates 
:- multifile def/2.

% lib(_Name, _ArgNames, _Args). allowing library predicates to be defined in a separate file
:- multifile lib/3.

% == Elementary predicates ==

% identity. Example: id is true for the tuple _{a:2, b:2}, or given _{a:3, b:B}, assigns B to 3.
cnp(id, _{a:A, b:B}) :-
  !,
  A=B.

% (list) construction. Example: cons is true for the tuple _{a:3, b:[4,5], ab:[3,4,5]}.
cnp(cons, _{a:X, b:T, ab:XT}) :-
  !,
  XT=[X|T].

% produces a constant predicate with one name N and one constant T
cnp(const(N,T), Args) :-
  !,
  Args=_{}.put(N,T).

% == Logic operators ==

% and(P, Q). P and Q must have at least one name in common.
cnp(and(P, Q), Args) :- 
  joint_args_unify(P, PArgs, Q, QArgs, Args),
  !,
  cnp(P, PArgs),
  cnp(Q, QArgs).
cnp(P ^ Q, Args) :- cnp(and(P, Q), Args).

% and-compose P and Q, projecting disjoint arguments. 
% andc(P, Q) where P:{a,b} and Q:{b,c} gives andc(P,Q):{a,c}.
cnp(andc(P, Q), Args) :-
  !,
  joint_args_unify(P, PArgs, Q, QArgs, AllArgs),
  get_disjoint_names(P, Q, Names),
  names_to_args(Names, DisjointArgs),
  DisjointArgs:<AllArgs,
  cnp(P, PArgs),
  cnp(Q, QArgs),
  DisjointArgs=Args.
% infix for papply
cnp(P ^. Q, Args) :-
  !,
  cnp(andc(P, Q), Args).

% or(P, Q). P and Q must have at least one name in common.
cnp(or(P, Q), Args) :- 
  joint_args_unify(P, PArgs, Q, QArgs, Args),
  !,
  (cnp(P, PArgs) ; cnp(Q, QArgs)).
cnp(P \/ Q, Args) :-
  !,
  cnp(or(P, Q), Args).

% == Projection ==

% proj(id, [a->x, b->y]) is true for _{x:2, y:2}.
cnp(proj(S, Projs), Args) :-
  names(S, SNames),
  names(proj(_, Projs), ProjNames),
  names_to_args(SNames, SArgs),
  names_to_args(ProjNames, ProjArgs),
  !,
  Args=ProjArgs,
  dicts_unify_through_projs(SArgs, Projs, ProjArgs),
  cnp(S, SArgs).
% infix for proj
cnp(S @ Projs, Args) :-
  cnp(proj(S, Projs), Args),
  !.

% == List recursion operators ==

% fold(P) : {b0, as, b} while names(P, [a, b, ab])
cnp(fold(_), _{b0:B0, as:[], b:B0}).
cnp(fold(P), _{b0:B0, as:[A|As], b:B}) :-
  cnp(fold(P), _{b0:B0, as:As, b:Bi}),
  cnp(P, _{a:A, b:Bi, ab:B}),
  !.

% foldleft(P) : {b0, as, b} while names(P, [a, b, ab])
cnp(foldleft(_), _{b0:B0, as:[], b:B0}) :- !.
cnp(foldleft(P), _{b0:B0, as:[A|As], b:B}) :-
  cnp(P, _{a:A, b:B0, ab:Bi}),
  cnp(foldleft(P), _{b0:Bi, as:As, b:B}),
  !.

% map(P) : {as, bs} while names(P, [a, b])
% map(P), names(P) must be [a, b]
cnp(map(_), _{as:[], bs:[]}).
cnp(map(P), _{as:[A|As], bs:[B|Bs]}) :-
  cnp(map(P), _{as:As, bs:Bs}),
  cnp(P, _{a:A, b:B}),
  !.

% filter(P) : {as, bs} while names(P, [a])
cnp(filter(_), _{as:[], bs:[]}) :- !.
cnp(filter(P), _{as:[A|As], bs:Bs}) :-
  (cnp(P, _{a:A})) -> (cnp(filter(P), _{as:As, bs:Bsi}), Bs=[A|Bsi]) ; cnp(filter(P), _{as:As, bs:Bs}),
  !.

% == Conditionals ==

% if C succeeds, T, otherwise F. names of T and F must be equal, and C should be a subset of those.
% if(Condition, TrueClause, FalseClause)
cnp(if(C,T,F), Args) :-
  !,
  names(T, TNames),
  names(F, FNames),
  names(C, CNames),
  names_to_args(CNames, ArgsC),
  names_to_args(TNames, Args),
  ArgsC:<Args,
  ((lists_equal_as_sets(TNames,FNames)) -> true ; throw_message_with_term('if T and F do not match:', if(C,T,F))),
  ((cnp(C, ArgsC)) -> cnp(T, Args) ; cnp(F, Args)).

% == Extensions ==

% library predicates
cnp(P, Args) :- 
  cnp:lib(P, _, Predicate),
  !,
  call(Predicate, Args).

% user-defined predicates
cnp(P, Args) :- 
  cnp:def(P, Body),
  !,
  cnp(Body, Args).

% Data or Fact input

% cnp(data(Names, Data), Args).
cnp(data(Names, Data), Args) :-
  !,
  member(D, Data),
  names_and_terms_to_args(Names, D, Args).

% no native, library or user-defined predicate is matched.
cnp(P, Args) :-
  throw_message_with_term('CNP does not recognize program:', P:Args).

% HELPERS

% throws with the term as the message
throw_message_with_term(Message, Term) :-
  term_string(Term, TermStr),
  string_concat(Message, TermStr, NewStr),
  throw(NewStr).

% names for a given CNP expression.
% names(P, [a, b, c, ...])
names(id, [a, b]) :- !.
names(cons, [a, b, ab]) :- !.
names(const(N,_), [N]) :- !.
names(L, Names) :-
  cnp:lib(L, Names, _), !.
names(U, Names) :-
  cnp:def(U, Body), 
  names(Body, Names), !.
names(and(P, Q), Names) :-
  names(P, PNames),
  names(Q, QNames),
  union(PNames, QNames, Names),
  !.
names(P ^ Q, Names) :- names(and(P, Q), Names), !.
names(or(P, Q), Names) :-
  names(P, PNames),
  names(Q, QNames),
  union(PNames, QNames, Names),
  !.
names(P \/ Q, Names) :- names(or(P, Q), Names), !.
names(proj(_, []), []) :- !.
names(proj(_, [_->N|Rest]), [N|RestNames]) :-
  names(proj(_, Rest), RestNames), !.
names(_ @ Projs, Names) :- names(proj(_, Projs), Names), !.
names(fold(_), [b0, as, b]) :- !.
names(foldleft(_), [b0, as, b]) :- !.
names(map(_), [as, bs]) :- !.
names(filter(_), [as, bs]) :- !.
names(if(C,T,_), Ns) :-
  names(C, Cs),
  names(T, Ns),
  union(Cs, Ns, Ns),
  !.
names(andc(P, Q), Names) :-
  get_disjoint_names(P, Q, Names),
  !.
names(P ^. Q, Names) :-
  names(andc(P, Q), Names),
  !.
names(data(Names, _), Names) :- !.
names(T, _) :- throw_message_with_term('Cannot find names for:', T).

% makes an args (dict) for the given names
names_to_args([], _{}).
names_to_args([N|Names], Args) :-
  names_to_args(Names, ArgsI),
  Args=ArgsI.put([N=_]).

names_and_terms_to_args([], [], _{}).
names_and_terms_to_args([N|Names], [T|Terms], Args) :-
  names_and_terms_to_args(Names, Terms, ArgsI),
  Args=ArgsI.put([N=T]).


% unifies logical operator args P and Q using their names(_).
% joint_args_unify(P, PArgs, Q, QArgs, Args)
joint_args_unify(P, PArgs, Q, QArgs, Args) :-
  names(P, PNames),
  names(Q, QNames),
  intersection(PNames, QNames, [_|_]), %nonempty
  union(PNames, QNames, Names),
  names_to_args(Names, AllArgs),
  names_to_args(PNames, PArgs),
  names_to_args(QNames, QArgs),
  PArgs:<AllArgs,
  QArgs:<AllArgs,
  Args=AllArgs.

% unifies proj(P)s and Ps arguments through a projection list
% dicts_unify_through_projs(DictOld, ProjOldToNew, DictNew).
dicts_unify_through_projs(_, [], _).
dicts_unify_through_projs(DictO, [O->N|Rest], DictN) :- % projections [old->new,...]
  get_dict(O, DictO, Vo),
  get_dict(N, DictN, Vn),
  Vo=Vn,
  dicts_unify_through_projs(DictO, Rest, DictN).

% get names that are not common to P and Q.
get_disjoint_names(P, Q, Names) :-
  names(P, PNames),
  names(Q, QNames),
  union(PNames, QNames, UNames),
  intersection(PNames, QNames, INTNames),
  subtract(UNames, INTNames, Names).

% two lists are equal as sets
lists_equal_as_sets(As, Bs) :-
  union(As, Bs, Un),
  length(As, L1),
  length(Bs, L2),
  length(Un, LU),
  L1=LU, L2=LU.