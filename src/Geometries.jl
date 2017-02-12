module Geometries

export Sphere

using JuliaShader

type Sphere{T}
    center::Array{T}
    radius::T
    radius2::T

    Material::Shader{T}
end

Sphere() = Sphere(Array(Float64, 3), convert(Float64,0.0), convert(Float64,0.0), Shader())

end
