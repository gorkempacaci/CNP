Copyright 2022 Görkem Paçacı

Contact: gorkem.pacaci@im.uu.se, gorkempacaci@gmail.com

# CNP Meta-interpreter

This is an implementation of the CNP (Combilog with Names and Projection) Meta-interpreter written in Prolog, with a small math library attached. For a formal description see:

> Paçacı, G., McKeever, S., & Hamfelt, A. (2017, June). Compositional Relational Programming with Name Projection and Compositional Synthesis. In International Andrei Ershov Memorial Conference on Perspectives of System Informatics (pp. 306-321). Springer, Cham.

> Paçacı, G., Johnson, D., McKeever, S., & Hamfelt, A. (2019, June). Why did you do that?. In International Conference on Computational Science (pp. 334-345). Springer, Cham.

## Release Notes

In this 2022 version the recursion operators (`fold`s) have only one operand, meaning they're in line with the familiar implementations from functional programming. The default value assumed for the second operand is assumed to be `id`. For example, the new `foldr(cons)` is equivalent to the previous `foldr(cons,id)`. 

## What is CNP?

CNP is a meta-language implemented in Prolog to offer Functional-Programming-like higher order operators in horn clause programs (like Prolog). CNP does this through variable-free syntax, and as a result its syntax is quite verbose, yet better than its predecessor Combilog, and much better than any comparable alternatives like Quines PFL or SKI calculus. The verbosity is a result of having to express binding of many input/output arguments in a single composition without consulting to variables.

The main use for CNP is program synthesis. Because there is no variables, CNP programs can be inductively synthesized by a few examples by exploiting the reverse semantics of the operators (See Pacaci et.al. 2017).

This meta-interpreter is provided so CNP programs synthesized via [Parallel CombInduce](https://github.com/gorkempacaci/CombInduce) or [RICE](https://github.com/UppsalaIM/rice) can be executed independently.

## Example

Examples throughout this document are executed via [SWI Prolog](https://www.swi-prolog.org). To start, load `swipl` and consult the source files:
```
$ swipl
Welcome to SWI-Prolog (threaded, 64 bits, version 8.0.3)

?- consult(['cnp.pl', 'math.pl', 'tests.pl']).
true.

?- run_tests.
% PL-Unit: cnp ...................................... done
% All 38 tests passed
true.
```

For example, in Prolog you can write this example of `ancestor` relation as such:

```
parent(edwardVII, georgeV).
parent(georgeV, georgeVI).
parent(georgeVI, elizabethII).
parent(elizabethII, charlesIII).
ancestor(Ancestor, Descendant) :- parent(Ancestor, Descendant).
ancestor(Ancestor, Descendant) :- parent(Ancestor, I), ancestor(I, Descendant).
```

In CNP, because there are no variables, the composition is achieved through projection:
```
cnp:def(parent, data([parent,       child],
                     [[edwardVII,   georgeV],
                      [georgeV,     georgeVI],
                      [georgeVI,    elizabethII],
                      [elizabethII, charlesIII]]) ).

cnp:def(ancestor, or(proj(parent, [parent->ancestor, child->descendant]),
                     proj(and(proj(parent, [parent->ancestor, child->intermediate]),
                              proj(ancestor, [ancestor->intermediate, descendant->descendant])),
                          [ancestor->ancestor, descendant->descendant])) ).
```

Asking all the ancestry relationship produces:
```
?- cnp(ancestor, A).
A = _7794{ancestor:edwardVII, descendant:georgeV} ;
A = _7794{ancestor:georgeV, descendant:georgeVI} ;
A = _7794{ancestor:georgeVI, descendant:elizabethII} ;
A = _7794{ancestor:elizabethII, descendant:charlesIII} ;
A = _7794{ancestor:edwardVII, descendant:georgeVI} ;
A = _7794{ancestor:edwardVII, descendant:elizabethII} ;
A = _7794{ancestor:edwardVII, descendant:charlesIII} ;
A = _86{ancestor:georgeV, descendant:elizabethII} ;
A = _86{ancestor:georgeV, descendant:charlesIII} ;
A = _86{ancestor:georgeVI, descendant:charlesIII} ;
```

## Composing and running CNP programs

CNP programs are run through the `cnp` predicate (usually named `apply`):
```
cnp(CNPProgram, Args).
```

For example, using the elementary predicate `id : {a, b}`:
```
?- cnp(id, _{a:1, b:B}).
B = 1.
```

The second argument `Args` is used to facilitate input/output with the CNP program through the meta-interpreter (`cnp`). Type of `Args` is a `dict`, which is a structure in the form Tag{name:term, ...}. CNP never binds the Tag, so CNP tuples always look like `_{ ... }`.

Programs of any complexity can be composed and run via putting it in the first argument of the `cnp` predicate:
```
?- cnp(foldl(cons), _{b0:[], as:[1,2,3], b:List}).
List = [3, 2, 1].
```

CNP is built on top of Horn clauses (as in Prolog), so any CNP pure program can be run in reverse, like so:
```
?- cnp(foldl(cons), _{b0:[], as:AS, b:[3,2,1]}).
AS = [1, 2, 3].
```

or it can be used to iterate through other possible values for the arguments:
```
?- cnp(foldl(cons), _{b0:B0, as:AS, b:[3,2,1]}).
B0 = [3, 2, 1],
AS = [] ;
B0 = [2, 1],
AS = [3] ;
B0 = [1],
AS = [2, 3] ;
B0 = [],
AS = [1, 2, 3] ;
```

## Summary of CNP syntax

Here is a brief summary of CNP language. Examples can be found in `tests.pl`. Names of a predicate expression is displayed as `P : {a, b, c}`. There is no order to names as they're given as a set. 

### Elementary predicates
`id : {a, b}` succeeds when values of `a` and `b` are identical. 

`cons : {a, b, ab}` succeeds when value of `ab` is a list where head is value of `a` and tail is `b`.

`const(N, T) : {N}` succeeds when value of N is T. This is used to introduce constants with a name, like `const(nil, [])`.

### Logic operators
`and(P, Q) : N` gives conjunction of `P : N1` and `Q : N2`, similar to an inner join from Relational Algebra. Names `N` is the union of `N1` an `N2`, and intersection of `N1` and `N2` must be non-empty. It can be written infix as (`P ^ Q`).

`or(P, Q)` gives disjunction, where names work like in `and`. Infix: (`P \/ Q`).

`andc(P, Q)` gives relational composition. It's equivalent to `proj(and(P, Q), D)` where `D` projects disjoint arguments of `P` and `Q`. For example, if `P : {a, b}` and `Q : {b, c}`, `andc(P, Q) : {a, c}`. Infix: (`P ^. Q`).

### Recursion operators

`foldr(P) : {b0, as, b}` where `P : {a, b, ab}` gives a right fold, and `foldl(P)` a left fold.

`map(P) : {as, bs}` where `P : {a, b}` gives a map from `as` to `bs`. If `P` is reversible, `map(P)` is reversible too. 

`filter(P) : {as, bs}` where `P : {a}` gives a filter from `as` to `bs`. For example, `filter(neg, _{as:[1,-2,3], bs:Bs})` succeeds for `Bs = [-2]`.

### Conditional operators

`if(C, T, F)` succeeds as `T` if `C` succeeds, otherwise it succeeds as `F`. Names of `T` and `F` should be identical, and names of `C` should be a subset of those.

## Extending the interpreter

There are two ways to extend the interpreter: (1) defining library predicates to introduce something that is available in Prolog into CNP, or (2) defining a new CNP predicate or a CNP operator by giving a body in CNP.

To define a library predicate, you add another clause for the cnp:lib, as can be seen in the 'cnp_math.pl' file:
```
cnp:lib(lt,   [a,b],    [_{a:A, b:B}] >> (A<B)).
```
cnp:lib has three arguments, first gives a name for the predicate, second gives the argument names, and the third gives an anonymous predicate to execute. Then you can use this predicate as a CNP program:
```
?- cnp(lt, _{a:3, b:4}).
true .
```

To define a CNP operator, you add a clause for the `cnp:def`. CNP has a `map` already, but lets say you want to implement a `map` in terms of `foldr`, you can do:
```
% map implemented in terms of foldr
cnp:def(map_f(P),
  proj(and(const(b0, []),
           foldr(proj(and(proj(P, [a>a, b>b1]),
                         proj(cons, [a>b1, b>b, ab>ab])),
                     [a>a, b>b, ab>ab]))),
       [as>as, b>bs])).
```
and the CNP interpreter will execute the body for you:
```
?- cnp(map_f(flip), _{as:[1,-2,3], bs:Bs}).
Bs = [-1, 2, -3].
```
