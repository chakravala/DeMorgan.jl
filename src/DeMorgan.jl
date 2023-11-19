module DeMorgan

#   This file is part of DeMorgan.jl
#   It is licensed under the AGPL license
#   DeMorgan Copyright (C) 2023 Michael Reed
#       _           _                         _
#      | |         | |                       | |
#   ___| |__   __ _| | ___ __ __ ___   ____ _| | __ _
#  / __| '_ \ / _` | |/ / '__/ _` \ \ / / _` | |/ _` |
# | (__| | | | (_| |   <| | | (_| |\ V / (_| | | (_| |
#  \___|_| |_|\__,_|_|\_\_|  \__,_| \_/ \__,_|_|\__,_|
#
#   https://github.com/chakravala
#   https://crucialflow.com
#  ______         ___ ___
# |   _  \ .-----|   Y   .-----.----.-----.---.-.-----.
# |.  |   \|  -__|.      |  _  |   _|  _  |  _  |     |
# |.  |    |_____|. \_/  |_____|__| |___  |___._|__|__|
# |:  1    /     |:  |   |          |_____|
# |::.. . /      |::.|:. |
# `------'       `--- ---'

using AbstractLattices, StaticVectors, Requires

import Base: OneTo, !, &, |
import AbstractLattices: wedge,vee, ∧, ∨

export TruthValues, Tautology, TruthTable, @truthtable
export ⟂, ⊥, ⊤, ¬, ∧, ∨, -->, <--, <-->, →, ←, ↔

struct TruthValues{N} <: Integer
    p::UInt
end

TruthValues{0}() = TruthValues{0}(zero(UInt))
TruthValues() = TruthValues{0}()
TruthValues(p::Vararg{Bool,N}) where N = TruthValues{N}((|)((p .<< (Tuple(OneTo(N)).-1))...))

const ⟂, ⊥ = TruthValues(), TruthValues()
(::TruthValues{0})(::Vararg{TruthValues}) = ⊥
Base.show(io::IO,::TruthValues{0}) = print(io,'⊥')

struct Tautology end
const ⊤ = Tautology()
(::Tautology)(::Vararg{TruthValues}) = ⊤
Base.show(io::IO,::Tautology) = print(io,'⊤')

wedge(p::TruthValues{N},q::TruthValues{N}) where N = TruthValues{N}(p.p&q.p)
vee(p::TruthValues{N},q::TruthValues{N}) where N = TruthValues{N}(p.p|q.p)
Base.:&(p::TruthValues{N},q::TruthValues{N}) where N = p∧q
Base.:|(p::TruthValues{N},q::TruthValues{N}) where N = p∨q
-->(p::TruthValues{N},q::TruthValues{N}) where N = ¬(p)∨q
<--(p::TruthValues{N},q::TruthValues{N}) where N = p∨¬(q)
<-->(p::TruthValues{N},q::TruthValues{N}) where N = (p-->q)∧(q-->p)
!(p::TruthValues{N}) where N = TruthValues{N}(p.p⊻(UInt(1)<<(1<<N)-UInt(1)))
!(::TruthValues{0}) = ⊤
!(::Tautology) = ⊥
const ¬, →, ←, ↔ = !, -->, <--, <-->

struct TruthTable{N,M}
    p::Values{M,UInt}
    n::Values{M,Tuple{Vararg{String}}}
    i::Int
    j::Int
end

TruthTable{N}(p::UInt,s::String)  where N = TruthTable{N,1}(Values(p),Values(((s,),)),1,1)
TruthTable{N,0}() where N = TruthTable{N,0}(Values{0,UInt}(),Values{0,Tuple{Vararg{String}}}(),0,0)

Base.string(p::TruthTable) = p.n[p.i][p.j]
parstring(p) = parstring(string(p))
function parstring(s::String)
    if length(s) == 1 || !isnothing(match(r"^¬\(((?>[^\(\)]+)|(?R))*\)$",s))
        return s
    else
        return "($s)"
    end
end

function select(n,N)
    j = 1<<(n-1)
    sum([UInt(1)<<(((i-1)%j)+(2*j*((i-1)÷j))) for i ∈ OneTo(1<<(N-1))])
end
select(N) = select.(Tuple(OneTo(N)),N)
extend(n,N) = (n...,Tuple(fill("",N))...)

macro truthtable(names...)
    N = length(names)
    p = TruthTable{N}.(select.(reverse(Tuple(OneTo(N))),N),string.(names))
    Expr(:block,Expr.(:(=),esc.(names),p)...,nothing)
end

Base.:&(p::TruthTable{N},q::TruthTable{N}) where N = p∧q
Base.:|(p::TruthTable{N},q::TruthTable{N}) where N = p∨q
function !(p::TruthTable{N,M}) where {N,M}
    np = !TruthValues{N}(p.p[p.i])
    combine(p,np,("¬($(p.n[p.i][end]))",))
end

tautology(n) = UInt(1)<<(1<<n)-UInt(1)
istautology(n::UInt,N::Int) = n==tautology(N)

combine(p::TruthTable{N},r,n) where N = combine(p,TruthTable{N,0}(),r,n)
function combine(p::TruthTable{N,P},q::TruthTable{N,Q},r,n) where {N,P,Q}
    rp = Vector(p.p)
    rn = Vector(p.n)
    out = (0,0)
    sN = select(N)
    for i ∈ OneTo(Q+1)
        qp = i>Q ? r.p : q.p[i]
        qn = i>Q ? n : q.n[i]
        if qp ∈ p.p
            k = findfirst(x->x==qp,p.p)
            for j ∈ OneTo(length(qn))
                if qn[j] ∈ p.n[k]
                    if i>Q
                        out = (k,findfirst(x->x==qn[j],p.n[k]))
                    end
                else
                    rn[k] = (rn[k]...,qn[j])
                    if i>Q
                        out = (k,length(rn[k]))
                    end
                end
            end
        else
            qnn = iszero(qp) ? ("⊥",qn...) : istautology(qp,N) ? ("⊤",qn...) : qn
            if qp ∈ sN
                l = findfirst(x->x∉sN,rp)
                isnothing(l) && (l=length(rp)+1)
                insert!(rp,l,qp)
                insert!(rn,l,qnn)
                if i>Q
                    out = (l,1)
                end
            else
                push!(rp,qp)
                push!(rn,qnn)
                if i>Q
                    out = (length(rp),1)
                end
            end
        end
    end
    TruthTable{N,length(rp)}(Values(rp...),Values((rn...,)),out[1],out[2])
end

for (op,sym) ∈ ((:wedge,'∧'),(:vee,'∨'),(:-->,'→'),(:<--,'←'),(:<-->,'↔'))
    @eval begin
        $op(p::TruthValues{0},q::TruthValues{N}) where N = $op(TruthValues{N}(p.p),q)
        $op(p::TruthValues{N},q::TruthValues{0}) where N = $op(p,TruthValues{N}(q.p))
        $op(p::Tautology,q::TruthValues{N}) where N = $op(TruthValues{N}(tautology(N)),q)
        $op(p::TruthValues{N},q::Tautology) where N = $op(p,TruthValues{N}(tautology(N)))
        function $op(p::TruthTable{N,P},q::TruthTable{N,Q}) where {N,P,Q}
            r = $op(TruthValues{N}(p.p[p.i]),TruthValues{N}(q.p[q.i]))
            m = combine(p,q,r,("$(parstring(p))$($sym)$(parstring(q))",))
        end
    end
end

function __init__()
    @require PrettyTables="08abe8d2-0d0c-5749-adfa-8a2ac140af0d" begin
        function PrettyTables.pretty_table(p::TruthTable{N,M}) where {N,M}
            ls = length.(p.n)
            max = maximum(ls)
            data = hcat(digits.(p.p,base=2,pad=2^N)...)
            header = Tuple([Vector(getindex.(extend.(p.n,max.-ls),i)) for i ∈ OneTo(max)])
            PrettyTables.pretty_table(data,header=header)
        end
        Base.show(io::IO,p::TruthTable{N,M}) where {N,M} = PrettyTables.pretty_table(p)
    end
end

end # module DeMorgan
