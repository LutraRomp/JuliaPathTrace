module JuliaShader

export Shader,ShaderRGBA,calc_refl,calc_diff,calc_refr,mix

import Base.+, Base.-, Base.*, Base./

type ShaderRGBA{T<:AbstractFloat}
    r::T
    g::T
    b::T
    a::T
end

ShaderRGBA{T<:AbstractFloat}(r::T,g::T,b::T) = ShaderRGBA{T}(r,g,b,1.0)
ShaderRGBA() = ShaderRGBA(0.0, 0.0, 0.0, 1.0)
+(x::ShaderRGBA, y::ShaderRGBA) =
        ShaderRGBA(x.r+y.r, x.g+y.g, x.b+y.b, x.a+y.a)
-(x::ShaderRGBA, y::ShaderRGBA) =
        ShaderRGBA(x.r-y.r, x.g-y.g, x.b-y.b, x.a-y.a)
*(x::ShaderRGBA, y::ShaderRGBA) =
        ShaderRGBA(x.r*y.r, x.g*y.g, x.b*y.b, x.a*y.a)
*{T<:AbstractFloat}(x::ShaderRGBA, y::T) = ShaderRGBA(x.r*y, x.g*y, x.b*y, x.a*y)
*{T<:AbstractFloat}(x::T, y::ShaderRGBA) = y*x
/(x::ShaderRGBA, y::ShaderRGBA) =
        ShaderRGBA(x.r/y.r, x.g/y.g, x.b/y.b, x.a/y.a)
/{T<:AbstractFloat}(x::ShaderRGBA, y::T) = ShaderRGBA(x.r/y, x.g/y, x.b/y, x.a/y)

mix{T<:AbstractFloat, U<:ShaderRGBA}(mix::T,a::U,b::U) = b*mix + a*(1.0-mix)

type Shader{T<:AbstractFloat}
    diffuse::ShaderRGBA{T}
    glossy::ShaderRGBA{T}
    glossy_mix::T

    emission::ShaderRGBA{T}
    emission_mix::T
end

Shader() = Shader(ShaderRGBA(), ShaderRGBA(), 0.0, ShaderRGBA(), 0.0)


# Ray path related code
calc_refl(ray_dir, normal) = normalize( ray_dir - 2 * normal * dot(ray_dir,normal) )

function calc_diff(ray_dir, normal)
    Theta = 2*pi*rand()
    z = rand()
    sz2 = sqrt(1-z*z)
    x = sz2*cos(Theta)
    y = sz2*sin(Theta)

    w = normalize(cross([0.0, 0.0, 1.0], normal))

    w_hat = [0 -w[3] w[2]; w[3] 0 -w[1]; -w[2] w[1] 0]

    cos_tht = normalize([0.0, 0.0, 1.0])'*normalize(normal)
    tht = acos(cos_tht[1])

    R = eye(3)+w_hat*sin(tht)+w_hat^2*(1-cos(tht))

    return R*[x,y,z]
end

function calc_refr(ray_dir, normal, n1, n2)
    eta = n1/n2
    c1 = -dot(ray_dir, normal)
    cs2 = 1.0 - eta*eta*(1.0-c1*c1)
    if cs2 < 0.0
        return zeros(3)
    end
    return normalize( eta*ray_dir + (eta*c1-sqrt(cs2))*normal )
end

end
