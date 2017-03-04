module Geometries

export Sphere, obj_intersect, calc_intersection

using JuliaShader

type Sphere{T}
    center::Array{T}
    radius::T
    radius2::T

    material::Shader{T}
end

Sphere() = Sphere(Array(Float64, 3), convert(Float64,0.0), convert(Float64,0.0), Shader())

function obj_intersect(s::Sphere, ray_orig, ray_dir)
    l = s.center - ray_orig
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
        t0 = t1
    end
    return (true, t0)
end

function calc_intersection(s::Sphere, ray_orig, ray_dir, t0)
    phit=ray_orig+ray_dir*t0
    nhit=normalize(phit - s.center)
    return (phit, nhit)
end

end
