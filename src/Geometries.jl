module Geometries

export Sphere, obj_intersect, calc_intersection

using JuliaShader

type Sphere{T}
    center::Array{T}
    radius::T
    radius2::T

    material::Shader{T}
end

Sphere() = Sphere(Array{Float64}(3), convert(Float64,0.0), convert(Float64,0.0), Shader())

function obj_intersect(s::Sphere, ray_orig, ray_dir)
    l = [0.0, 0.0, 0.0]
    for i in 1:3
        l[i] = s.center[i] - ray_orig[i]
    end

    tca = dot(l, ray_dir)
    if tca < 0
        return (false, 0.0)
    end

    d2 = dot(l, l) - (tca * tca)
    if d2 > s.radius2
        return (false, 0.0)
    end

    thc = sqrt(s.radius2 - d2)
    t0 = tca - thc
    t1 = tca + thc
    if t0 < 0
        return (true, t1)
    end
    return (true, t0)
end

function calc_intersection(s::Sphere, ray_orig, ray_dir, t0)
    acc  = 0.0
    phit = [0.0, 0.0, 0.0]
    #thit = [0.0, 0.0, 0.0]
    nhit = [0.0, 0.0, 0.0]
    center = s.center
    for i in 1:3
      phit[i] = ray_orig[i]+ray_dir[i]*t0
      nhit[i] = phit[i] - center[i]
      acc = acc + nhit[i]*nhit[i]
    end
 
    acc = sqrt(acc)
    for i in 1:3
      nhit[i] = nhit[i]/acc
    end
    return (phit, nhit)
end

end
