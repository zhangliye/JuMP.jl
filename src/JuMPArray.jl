#  Copyright 2015, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This code is unused for now. See issue #192

immutable JuMPArray{T,N,NT<:NTuple} <: JuMPContainer{T}
    innerArray::Array{T,N}
    indexsets::NT
    lookup::NTuple{N,Dict}
    meta::Dict{Symbol,Any}
end

function JuMPArray{T,N}(innerArray::Array{T,N}, indexsets::NTuple{N})
    JuMPArray(innerArray, indexsets, ntuple(N) do i
        idxset = indexsets[i]
        ret = Dict{eltype(idxset), Int}()
        if !(eltype(idxset) == Int && (typeof(idxset) == UnitRange || typeof(idxset) == StepRange))
            cnt = 1
            for x in idxset
                ret[x] = cnt
                cnt += 1
            end
        end
        ret
    end, Dict{Symbol,Any}())
end

@generated function Base.getindex{T,N,NT<:NTuple}(d::JuMPArray{T,N,NT}, idx...)
    indexing = Any[]
    for (i,S) in enumerate(NT.parameters)
        if S == UnitRange{Int}
            push!(indexing, quote
                rng = d.indexsets[$i]
                I = idx[$i]
                first(rng) <= I <= last(rng) || throw(BoundsError())
                I - (start(rng) - 1)
            end)
        elseif S == StepRange{Int}
            push!(indexing, quote
                rng = $(d.indexsets[i])
                I = idx[$i]
                first(rng) <= I <= last(rng) || throw(BoundsError())
                d, r = divrem(I - start(rng), step(rng))
                r == 0 || throw(BoundsError())
                d + 1
            end)
        else
            push!(indexing, :(d.lookup[$i][idx[$i]]::Int))
        end
    end
    Expr(:call, :getindex, :(d.innerArray), indexing...)
end

@generated function Base.setindex!{T,N,NT<:NTuple}(d::JuMPArray{T,N,NT}, v::T, idx...)
    indexing = Any[]
    for (i,S) in enumerate(NT.parameters)
        if S == UnitRange{Int}
            push!(indexing, quote
                rng = d.indexsets[$i]
                I = idx[$i]
                first(rng) <= I <= last(rng) || throw(BoundsError())
                I - (start(rng) - 1)
            end)
        elseif S == StepRange{Int}
            push!(indexing, quote
                rng = $(d.indexsets[i])
                I = idx[$i]
                first(rng) <= I <= last(rng) || throw(BoundsError())
                d, r = divrem(I - start(rng), step(rng))
                r == 0 || throw(BoundsError())
                d + 1
            end)
        else
            push!(indexing, :(d.lookup[$i][idx[$i]]::Int))
        end
    end
    Expr(:call, :setindex!, :(d.innerArray), :v, indexing...)
end
