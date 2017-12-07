module GridAccel

export AccelGrid, GridAccel_CellIter, GenerateStructure
export box_exit

using ArrayEnv
# a=Array{Array{Int32,1}}, 2, 2)
# a[1,1] = Array{Int32},0)
# push!(a[1,1],<an integer>)


type AccelGrid{T}
    count::T
    a::Array{Array{T,1},3}
    oa::ObjectArray

    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64
    zmin::Float64
    zmax::Float64
    dx::Float64
    dy::Float64
    dz::Float64

    nx::T
    ny::T
    nz::T
end

type AccelGrid_CellIter{T}
    acc_grd::AccelGrid
    origin_ray::Array{T,3}
    cur_position::Array{T,3}
    cur_itter::T
    cur_max::T
end

function Base.start(::AccelGrid_CellIter)
end

function Base.next(AG::AccelGrid_CellIter, state)
    cur_cell = AG.acc_grd.a[AG.cur_position[1], AG.cur_position[2], AG.cur_position[3]]
    if AG.cur_itter < cur_cell.length()
        AG.cur_itter = AG.cur_itter+1
    else
        
    end
end

function Base.done(AG::AccelGrid_CellIter, state)
    cur_cell = AG.acc_grd.a[AG.cur_position[1], AG.cur_position[2], AG.cur_position[3]]
    if AG.cur_itter > cur_cell.length()
        # check if exiting the grid
    end
    return false
end

#function Base.eltype(::Type{AccelGrid_CellIter}) = AccelGrid_CellIter.acc_grd
#function Base.length(AG::AccelGrid_CellIter) = AG.count
#function Base.size(AG::AccelGrid_CellIter)
#    return (AG.acc_grd.nx,
#            AG.acc_grd.ny,
#            AG.acc_grd.nz)
#end

#function Base.endof(AG::AccelGrid_CellIter) = AG.count

function Base.getindex(AA::AccelGrid, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    return AA.oa[AA.a[i]]
end

function Base.setindex!(AA::AccelGrid, v::Integer, i::Integer)
    1 <= i <= AA.count || throw(BoundsError(AA,i))
    AA.a[i] = v
end

#bool intersection(box b, ray r) {
#    double tx1 = (b.min.x - r.x0.x)*r.n_inv.x;
#    double tx2 = (b.max.x - r.x0.x)*r.n_inv.x;
# 
#    double tmin = min(tx1, tx2);
#    double tmax = max(tx1, tx2);
# 
#    double ty1 = (b.min.y - r.x0.y)*r.n_inv.y;
#    double ty2 = (b.max.y - r.x0.y)*r.n_inv.y;
# 
#    tmin = max(tmin, min(ty1, ty2));
#    tmax = min(tmax, max(ty1, ty2));
# 
#    return tmax >= tmin;
#}
function box_exit(x1, x2, y1, y2, z1, z2, ray_orig, ray_dir)
    local dx::Float64
    local dy::Float64
    local dz::Float64
    local sx::Int32
    local sy::Int32
    local sz::Int32

    if ray_dir[1] < 0.0
        dx = -(ray_orig[1] - x1) / ray_dir[1]
        sx = -1 
    elseif ray_dir[1] > 0.0
        dx = (x2 - ray_orig[1]) / ray_dir[1]
        sx = 1
    else
        dx = Inf
        sx = 0
    end

    if ray_dir[2] < 0.0
        dy = -(ray_orig[2] - y1) / ray_dir[2]
        sy = -2
    elseif ray_dir[2] > 0.0
        dy = (y2 - ray_orig[2]) / ray_dir[2]
        sy = 2
    else
        dy = Inf
        sy = 0
    end

    if ray_dir[3] < 0.0
        dz = -(ray_orig[3] - z1) / ray_dir[3]
        sz = -3
    elseif ray_dir[3] > 0.0
        dz = (z2 - ray_orig[3]) / ray_dir[3]
        sz = 3
    else
        dz = Inf
        sz = 0
    end

    if dy < dx
        if dz < dy
            return sz
        else
            return sy
        end
    else
        if dz < dx
            return sz
        else
            return sx
        end
    end

    return 5
end


function GenerateStructure(OA::ObjectArray, nx, ny, nz)
    local count = convert(Int64,length(OA))
    local xmin::Float64, xmax::Float64
    local ymin::Float64, ymax::Float64
    local zmin::Float64, zmax::Float64
    local dx::Float64, dy::Float64, dz::Float64
    local x::Float64, y::Float64, z::Float64

    xmin,ymin,zmin = OA[1].center - OA[1].radius
    xmax,ymax,zmax = OA[1].center + OA[1].radius
    for o in OA
        xmin = min((o.center[1] - o.radius) - 0.1, xmin)
        ymin = min((o.center[2] - o.radius) - 0.1, ymin)
        zmin = min((o.center[3] - o.radius) - 0.1, zmin)
        xmax = max((o.center[1] + o.radius) + 0.1, xmax)
        ymax = max((o.center[2] + o.radius) + 0.1, ymax)
        zmax = max((o.center[3] + o.radius) + 0.1, zmax)

    end

    dx,dy,dz = ([xmax,ymax,zmax] - [xmin,ymin,zmin]) ./ [nx, ny, nz]
    
    a = Array{Array{Int64,1}}(nx, ny, nz)
    for i in 1:nx
        for j in 1:ny
            for k in 1:nz
                a[i,j,k] = Array{Int32}(0)
            end
        end
    end

    for s in 1:count
        o = OA[s]

        xmn,ymn,zmn = (o.center - o.radius - [xmin, ymin, zmin]) ./ [dx, dy, dz]
        xmx,ymx,zmx = (o.center + o.radius - [xmin, ymin, zmin]) ./ [dx, dy, dz]
        xmn = floor(Int32, xmn) + 1
        ymn = floor(Int32, ymn) + 1
        zmn = floor(Int32, zmn) + 1
        xmx = floor(Int32, xmx) + 1
        ymx = floor(Int32, ymx) + 1
        zmx = floor(Int32, zmx) + 1

        for i in xmn:xmx
            for j in ymn:ymx
                for k in zmn:zmx
                    push!(a[i,j,k], s)
                end
            end
        end
        
    end
    AccelGrid(count, a, OA, xmin, xmax, ymin, ymax, zmin, zmax, dx, dy, dz, nx, ny, nz)
end

end
