#!/usr/bin/env julia
push!(LOAD_PATH, "./")

using JuliaShader
using Geometries

r = ShaderRGBA(1.0,1.0,1.0)
print("$r\n")

r = ShaderRGBA()
print("$r\n")

s = Shader(ShaderRGBA(0.0, 0.0, 0.0),
           ShaderRGBA(0.0, 0.0, 0.0),
           0.0,
           ShaderRGBA(0.0, 0.0, 0.0),
           0.0)
print("$s\n")

s = Shader()
print("$s\n")

spr = Sphere(zeros(3), 1.2, 3.4, Shader())
print("$spr\n")
