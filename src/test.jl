#!/usr/bin/env julia
push!(LOAD_PATH, "./")

using DataFrames

using JuliaShader
using Geometries
using ArrayEnv
using ArrayAccel
using RayTrace
using MatrixTools

function GenObjects()
    oa = ObjectArray(50)
    for i in 1:length(oa)
        oa[i] = Sphere()
        oa[i].center  = 9.0*(rand(3)-0.5)
        oa[i].radius  = 1.0
        oa[i].radius2 = 1.0
        oa[i].material.diffuse = ShaderRGBA(1.0, 1.0, 1.0)
        oa[i].material.glossy = ShaderRGBA(1.0, 1.0, 1.0)

        if i % 4 == 0
            oa[i].material.glossy_mix = rand()
        else
            oa[i].material.glossy_mix =0.0
        end
    end
    return oa
end

function GenAccelStructure(oa)
    aa = GenerateStructure(oa)
end

function render(camera::Camera, aa)
    println("i,j,r,g,b,a")
    for i in 1:camera.res_x
        for j in 1:camera.res_y
            r = 0.0
            g = 0.0
            b = 0.0
            a = 0.0
            for itter = 1:5
                ray_dir = get_ray(camera, i, j)
                x = trace_path(aa, camera.origin, ray_dir, 10)
                r += x.r
                g += x.g
                b += x.b
                a += x.a
            end
            #df = vcat(df, DataFrame(i=i, j=j, r=r/10.0, g=g/10.0, b=b/10.0, a=a/10.0))
            r=r/5.0
            g=g/5.0
            b=b/5.0
            a=a/5.0
            println("$i,$j,$r,$g,$b,$a")
        end
    end
end

function go()
    camera = Camera(120, 120)
    camera.origin = [0.0, 0.0, -40.0]
    camera.rotation = [0.0, 0.0, 0.0]

    oa = GenObjects()
    aa = GenAccelStructure(oa)

    @time render(camera, aa)
end


go()
