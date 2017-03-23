module GridAccel

export GridAccel, GenerateStructure

using ArrayEnv

type AccelGrid{T}
    count::T
    a::Array{T}
    oa::ObjectArray
end

Base.start(::AccelGrid) = 1
Base.next(AA::AccelGrid, state) = (AA.oa[AA.a[state]], state+1)
Base.done(AA::AccelGrid, state) = state > AA.count
Base.eltype(::Type{AccelGrid}) = AccelGrid.a
Base.length(AA::AccelGrid) = AA.count
Base.size(AA::AccelGrid) = (AA.count,)
Base.endof(AA::AccelGrid) = AA.count

function Base.getindex(AA::AccelGrid, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    return AA.oa[AA.a[i]]
end

function Base.setindex!(AA::AccelGrid, v::Integer, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    AA.a[i] = v
end


function GenerateStructure(OA::ObjectArray, nx, ny, nz)::AccelGrid
    local n = length(OA)
    local xmin::Float64, xmax::Float64
    local ymin::Float64, ymax::Float64
    local zmin::Float64, zmax::Float64

    # x::Float64[]
    
    a = Array(typeof(n), n)
    for i in 1:n
        a[i] = i
    end
    AccelGrid(n, a, OA)
end

end
