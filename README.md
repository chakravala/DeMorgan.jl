# DeMorgan.jl

*Classical logic truth table magma algebra*

Truth table expressed as an algebraic magma with operations `¬`, `∧`, `∧`, `-->`, `<--`, `<-->`.
Based on classical logic with `TruthValues{N}` and `TruthTable{N,M}`, the `@truthtable` macro assigns named variable propositional projections as generators of the truth.
When `using DeMorgan` together with `PrettyTables`, the output is automatically formatted.

```Julia
julia> using DeMorgan, PrettyTables

julia> @truthtable p

julia> ¬¬(¬¬p∧¬p)
┌─────────┬──────┬──────────────────────┬───────────────────┐
│       p │ ¬(p) │                    ⊥ │                 ⊤ │
│ ¬(¬(p)) │      │       (¬(¬(p)))∧¬(p) │ ¬((¬(¬(p)))∧¬(p)) │
│         │      │ ¬(¬((¬(¬(p)))∧¬(p))) │                   │
├─────────┼──────┼──────────────────────┼───────────────────┤
│       1 │    0 │                    0 │                 1 │
│       0 │    1 │                    0 │                 1 │
└─────────┴──────┴──────────────────────┴───────────────────┘


julia> @truthtable p q r

julia> ((p-->q)∧(q-->r))-->(p-->r)
┌───┬───┬───┬─────┬─────┬─────────────┬─────┬─────────────────────┐
│ p │ q │ r │ p→q │ q→r │ (p→q)∧(q→r) │ p→r │                   ⊤ │
│   │   │   │     │     │             │     │ ((p→q)∧(q→r))→(p→r) │
├───┼───┼───┼─────┼─────┼─────────────┼─────┼─────────────────────┤
│ 1 │ 1 │ 1 │   1 │   1 │           1 │   1 │                   1 │
│ 1 │ 1 │ 0 │   1 │   0 │           0 │   0 │                   1 │
│ 1 │ 0 │ 1 │   0 │   1 │           0 │   1 │                   1 │
│ 1 │ 0 │ 0 │   0 │   1 │           0 │   0 │                   1 │
│ 0 │ 1 │ 1 │   1 │   1 │           1 │   1 │                   1 │
│ 0 │ 1 │ 0 │   1 │   0 │           0 │   1 │                   1 │
│ 0 │ 0 │ 1 │   1 │   1 │           1 │   1 │                   1 │
│ 0 │ 0 │ 0 │   1 │   1 │           1 │   1 │                   1 │
└───┴───┴───┴─────┴─────┴─────────────┴─────┴─────────────────────┘
```
With finitely generated truth basis, equivalence classes of truth expressions are formed and kept track of, including contradiction `⊥` and tautology `⊤` class expressions.
