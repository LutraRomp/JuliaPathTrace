module JuliaShader

export Shader,ShaderRGBA


mix(a,b,mix) = b*mix + a*(1.0-mix)


type ShaderRGBA{T<:AbstractFloat}
    r::T
    g::T
    b::T
    a::T
end

ShaderRGBA{T<:AbstractFloat}(r::T,g::T,b::T) = ShaderRGBA{T}(r,g,b,1.0)
ShaderRGBA{T<:AbstractFloat}(r::T,g::T,b::T,a::T) = ShaderRGBA{T}(r,g,b,a)
ShaderRGBA() = ShaderRGBA(0.0, 0.0, 0.0, 1.0)


type Shader{T<:AbstractFloat}
    diffuse::ShaderRGBA{T}
    glossy::ShaderRGBA{T}
    glossy_mix::T

    emission::ShaderRGBA{T}
    emission_mix::T
end

Shader() = Shader(ShaderRGBA(), ShaderRGBA(), 0.0, ShaderRGBA(), 0.0)

end
