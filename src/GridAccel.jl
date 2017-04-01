module GridAccel

export GridAccel, GenerateStructure

using ArrayEnv
# a=Array(Array{Int32,1}, 2, 2)
# a[1,1] = Array(Int32, 0)
# push!(a[1,1],<an integer>)


type AccelGrid{T}
    count::T
    a::Array{Array{T,1},3}
    oa::ObjectArray

    xmin::Float64, xmax::Float64
    ymin::Float64, ymax::Float64
    zmin::Float64, zmax::Float64
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


function GenerateStructure(OA::ObjectArray, nx, ny, nz)
    local count = length(OA)
    local xmin::Float64, xmax::Float64
    local ymin::Float64, ymax::Float64
    local zmin::Float64, zmax::Float64
    local x::Float64, y::Float64, z::Float64

    xmin,ymin,zmin = OA[1].center - OA[1].radius
    xmax,ymax,zmax = OA[1].center + OA[1].radius
    for o in OA
        xmin,ymin,zmin = min(o.center - o.radius, [xmin, ymin, zmin])
        xmax,ymax,zmax = max(o.center + o.radius, [xmax, ymax, zmax])
    end
    
    a = Array(Array{Int32,1}, nx, ny, nz)
    for i in 1:nx
        for j in 1:ny
            for k in 1:nz
                a[i,j,k] = Array(Int32, 0)
            end
        end
    end

    for o in 1:count
        xmn,ymn,zmn = o.center - o.radius
        xmx,ymx,zmx = o.center + o.radius
        # TODO: Add selected sphere to accel structure
    end
    AccelGrid(n, a, OA)
end

end
