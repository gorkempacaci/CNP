Copyright 2022 Görkem Paçacı

= CNP Meta-interpreter =

This is an implementation of the CNP (Combilog with Names and Projection) Meta-interpreter written in Prolog, with a small math library attached. 

> Paçacı, G., McKeever, S., & Hamfelt, A. (2017, June). Compositional Relational Programming with Name Projection and Compositional Synthesis. In International Andrei Ershov Memorial Conference on Perspectives of System Informatics (pp. 306-321). Springer, Cham.

> Paçacı, G., Johnson, D., McKeever, S., & Hamfelt, A. (2019, June). Why did you do that?. In International Conference on Computational Science (pp. 334-345). Springer, Cham.

=== Release Notes ===

In this 2022 version the recursion operators (`fold`s) have only one operand, meaning they're in line with the familiar implementations from functional programming. The default value assumed for the second operand is assumed to be `id`. For example, the new `fold(cons)` is equivalent to the previous `fold(cons,id)`. 

== Summary of CNP ==

CNP offers elementary predicates and operators to compose relational programs in a compositional style. 


== Composing and running CNP programs ==

Work in progress

== Extending the interpreter ==

There are two wayts to extend the interpreter: (1) defining library predicates to introduce something that is available in Prolog into CNP, or (2) defining a new CNP predicate or a CNP operator by giving a body in CNP.

To define a library predicate, you add another clause for the cnp:lib, as can be seen in the 'cnp_math.pl' file:
```
cnp:lib(lt,   [a,b],    [_{a:A, b:B}] >> (A<B)).
```
cnp:lib has three arguments, first gives a name for the predicate, second gives the argument names, and the third gives an anonymous predicate to execute. Library predicates are used to implement 
And then you can use this predicate as a CNP program:
```
?- cnp(lt, _{a:3, b:4}).
true .
```

To define a CNP operator, you add a clause for the `cnp:def`. CNP has a `map` already, but lets say you want to implement a `map` in terms of `fold`, you can do:
```
% map implemented in terms of fold
cnp:def(map_f(P),
  proj(and(const(b0, []),
           fold(proj(and(proj(P, [a>a, b>b1]),
                         proj(cons, [a>b1, b>b, ab>ab])),
                     [a>a, b>b, ab>ab]))),
       [as>as, b>bs])).
```
and the CNP interpreter will execute the body for you:
```
?- cnp(map_f(flip), _{as:[1,-2,3], bs:Bs}).
Bs = [-1, 2, -3].
```
Such higher-order predicates can have multiple arguments and will be executed by the CNP meta-interpreter. 
