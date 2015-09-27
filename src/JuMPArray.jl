#  Copyright 2015, Iain Dunning, Joey Huchette, Miles Lubin, and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This code is unused for now. See issue #192

immutable JuMPArray{T,N} <: JuMPContainer
    innerArray::Array{T,N}
    indexsets::NTuple{N}
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

function _rev_lookup(lookup, rng::UnitRange{Int}, I)
    first(rng) <= I <= last(rng) || throw(BoundsError())
    I - (start(rng) - 1)
end
function _rev_lookup(lookup, rng::StepRange{Int}, I)
    first(rng) <= I <= last(rng) || throw(BoundsError())
    d, r = divrem(I - start(rng), step(rng))
    r == 0 || throw(BoundsError())
    d + 1
end

_rev_lookup(lookup, v, I) = lookup[I]::Int

Base.getindex{T}(d::JuMPArray{T,1}, I) =
    d.innerArray[_rev_lookup(d.lookup[1], d.indexsets[1], I[1])]

Base.setindex!{T}(d::JuMPArray{T,1}, v::T, I) =
    d.innerArray[_rev_lookup(d.lookup[1], d.indexsets[1], I[1])] = v

function Base.getindex{T,N}(d::JuMPArray{T,N}, I::NTuple{N})
    idx = zeros(Int, N)
    for i in 1:N
        idx[i] = _rev_lookup(d.lookup[i], d.indexsets[i], I[i])
    end
    d.innerArray[idx...]
end

function Base.setindex!{T,N}(d::JuMPArray{T,N}, v::T, I::NTuple{N})
    idx = zeros(Int, N)
    for i in 1:N
        idx[i] = _rev_lookup(d.lookup[i], d.indexsets[i], I[i])
    end
    d.innerArray[idx...] = v
end
