module ArrayAccel

export AccelArray, GenerateStructure

using ArrayEnv

type AccelArray{T}
    count::T
    a::Array{T}
    oa::ObjectArray
end

Base.start(::AccelArray) = 1
Base.next(AA::AccelArray, state) = (AA.oa[AA.a[state]], state+1)
Base.done(AA::AccelArray, state) = state > AA.count
Base.eltype(::Type{AccelArray}) = AccelArray.a
Base.length(AA::AccelArray) = AA.count
Base.size(AA::AccelArray) = (AA.count,)
Base.endof(AA::AccelArray) = AA.count

function Base.getindex(AA::AccelArray, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    return AA.oa[AA.a[i]]
end

function Base.setindex!(AA::AccelArray, v::Integer, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    AA.a[i] = v
end


function GenerateStructure(OA::ObjectArray)::AccelArray
    n = length(OA)
    a = Array(typeof(n), n)
    for i in 1:n
        a[i] = i
    end
    AccelArray(n, a, OA)
end

end
