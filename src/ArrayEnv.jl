module ArrayEnv

export ObjectArray

using Geometries

type ObjectArray{T,U}
    count::T
    a::Array{U}
end

function ObjectArray{T<:Integer}(n::T)
    a=Array{Sphere}(n)
    for i in 1:n
        a[i] = Sphere()
    end
    ObjectArray(n,a)
end

Base.start(::ObjectArray) = 1
Base.next(OA::ObjectArray, state) = (OA.a[state], state+1)
Base.done(OA::ObjectArray, state) = state > OA.count
Base.eltype(::Type{ObjectArray}) = ObjectArray.a
Base.length(OA::ObjectArray) = OA.count
Base.size(OA::ObjectArray) = (OA.count,)
Base.endof(OA::ObjectArray) = OA.count

function Base.getindex(OA::ObjectArray, i::Integer)
    1 <= i <= OA.count || throw(BoundsError(OA,i))
    return OA.a[i]
end

function Base.setindex!(OA::ObjectArray, v::Sphere, i::Integer)
    1 <= i <= OA.count || throw(BoundsError(OA,i))
    OA.a[i] = v
end

end
