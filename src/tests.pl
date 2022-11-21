% CNP Meta-interpreter / Tests
% Copyright 2022 Görkem Paçacı
% This file is part of CNP Meta-interpreter.
% CNP Meta-interpreter is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
% CNP Meta-interpreter is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
% You should have received a copy of the GNU Lesser General Public License along with CNP Meta-interpreter. If not, see <https://www.gnu.org/licenses/>.


:- use_module(cnp).
:- use_module(math).


% PREDICATES DEFINED FOR TESTS

% externally defining a map_f in terms of fold
cnp:def(map_f(P),
  proj(and(const(b0, []),
           fold(proj(and(proj(P, [a->a, b->b1]),
                         proj(cons, [a->b1, b->b, ab->ab])),
                     [a->a, b->b, ab->ab]))),
       [as->as, b->bs])).

% samples for ascendant predicate
cnp:def(parent, data([parent,       child],
                     [[edwardVII,   georgeV],
                      [georgeV,     georgeVI],
                      [georgeVI,    elizabethII],
                      [elizabethII, charlesIII]]) ).

cnp:def(ancestor, or(proj(parent, [parent->ancestor, child->descendant]),
                     proj(and(proj(parent, [parent->ancestor, child->intermediate]),
                              proj(ancestor, [ancestor->intermediate, descendant->descendant])),
                          [ancestor->ancestor, descendant->descendant])) ).

cnp:def(ancestor2, or(proj(parent, [parent->ancestor, child->descendant]),
                      papply(proj(parent, [parent->ancestor, child->intermediate]),
                             proj(ancestor, [ancestor->intermediate, descendant->descendant])))).
:- begin_tests(cnp).

test(id_ground) :-                cnp(id, _{a:3, b:3}).
test(id_functional) :-            cnp(id, _{a:X, b:X}).
test(cons_ground) :-              cnp(cons, _{a:1, b:[], ab:[1]}).
test(and_of_ids_ground) :-        cnp(and(id, id), _{a:3, b:3}).
test(and_of_ids_free) :-          cnp(and(id, id), _{a:3, b:_}).
test(and_of_ids_fail) :-       \+ cnp(and(id, id), _{a:3, b:4}).
test(and_of_id_cns_free) :-       cnp(and(id, const(b, 3)), _{a:3, b:_}).
test(or_of_id_cnst_grnd1) :-      cnp(or(id, const(b, 3)), _{a:4, b:3}).
test(or_of_id_cnst_grnd2) :- once(cnp(or(id, const(b, 3)), _{a:4, b:4})).
test(or_of_id_cnst_grnd_fl) :- \+ cnp(or(id, const(b, 3)), _{a:4, b:5}).
test(or_of_cnst_id_grnd1) :- once(cnp(or(const(b, 3), id), _{a:4, b:3})).
test(or_of_cnst_id_grnd2) :-      cnp(or(const(b, 3), id), _{a:4, b:4}).
test(or_of_cnst_id_grnd_fl) :- \+ cnp(or(const(b, 3), id), _{a:4, b:5}).
test(proj_id_free1) :-            cnp(proj(id, [a->x, b->y]), _{x:2, y:Y}), !, Y=2.
test(proj_id_free1_1) :-     once(cnp(proj(id, [a->x, b->y]), _{x:2, y:_})).
test(proj_id_free_infix) :-       cnp(id @ [a->x, b->y], _{x:2, y:_}).
test(proj_lib_infix)      :-      cnp(flip @ [a->x, b->y], _{x:2, y:_}).
test(proj_id_free2) :-       once(cnp(proj(id, [a->x, b->y]), _{x:_, y:x})).
test(proj_id_elim1) :-       once(cnp(proj(id, [a->x]), _{x:_})).
test(proj_id_fail1) :-         \+ cnp(proj(id, [c->x]), _{x:_}).
test(proj_id_fail2) :-         \+ cnp(proj(id, [a->x]), _{x:2, y:_}).
test(proj_and_proj) :-            cnp(proj(and(proj(id, [a->a, b->x]), proj(id, [a->x, b->c])), [a->a, c->b]), _{a:3, b:B}), !, B=3.
test(proj_and_proj) :-       once(cnp(proj(and(proj(id, [a->a, b->x]), proj(id, [a->x, b->c])), [a->a, c->b]), _{a:3, b:_})).
test(fold_cons) :-           once(cnp(fold(cons), _{b0:[], as:[1,2,3], b:[1,2,3]})).
test(fold_plus) :-           once(cnp(fold(+), _{b0:0, as:[1,2,3], b:6})).
test(foldleft_cons) :-       once(cnp(foldleft(cons), _{b0:[], as:[1,2,3], b:[3,2,1]})).
test(map_id) :-                   cnp(map(id), _{as:[1,2,3], bs:[1,2,3]}).
test(map_flip) :-                 cnp(map(flip), _{as:[1,-2,3], bs:[-1,2,-3]}).
test(map_f_id) :-            once(cnp(map_f(id), _{as:[1,2,3], bs:[1,2,3]})).
test(map_f_flip) :-          once(cnp(map_f(flip), _{as:[1,-2,3], bs:[-1,2,-3]})).
test(filter_nil) :-               cnp(filter(const(a, [])), _{as:[1,2,[],4,[]], bs:[[],[]]}).
test(if_1) :-                     cnp(if(const(a, []), id, flip), _{a:[], b:B}), !, B = [].
test(if_2) :-                     cnp(if(const(a, []), id, flip), _{a:1, b:B}), !, B = -1.
test(if_3) :-                     cnp(if(lt, cons, cons @ [a->b, b->a, ab->ab]), _{a:3, b:4, ab:AB}), !, AB = [3|4].
test(if_3) :-                     cnp(if(lt, cons, cons @ [a->b, b->a, ab->ab]), _{a:4, b:3, ab:AB}), !, AB = [3|4].
test(andc) :-                     cnp(andc(const(a,[]), id), _{b:B}), !, B = [].
test(andc_infix) :-               cnp(const(a,[]) ^. id, _{b:B}), !, B = [].
test(ancestor_0) :-          once(cnp(ancestor, _{ancestor:elizabethII, descendant:charlesIII})).
test(ancestor_3) :-          once(cnp(ancestor, _{ancestor:edwardVII, descendant:charlesIII})).
test(ancestor_all) :-       times(cnp(ancestor, _{ancestor:_, descendant:_}), 10).
test(data_all) :-           times(cnp(data([a],[[1],[2],[3]]),_{a:_}), 3).
test(data_or) :-            times(cnp(data([a],[[1],[2],[3]]) \/ nil,_{a:_}), 4).

:- end_tests(cnp).

% HELPERS FOR TESTS

times(P, N) :- 
  aggregate_all(count, P, N).