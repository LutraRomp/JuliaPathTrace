module Geomitries

export Sphere

using JuliaShader

type Sphere{T}
    center::Array{T}
    radius::T
    radius2::T

    Material::Shader{T}
end

end
