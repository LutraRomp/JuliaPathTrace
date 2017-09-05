#!/usr/bin/env julia

push!(LOAD_PATH, "./")

using DataFrames
using Images
using FileIO

using JuliaShader
using Geometries
using ArrayEnv
#using ArrayAccel
using GridAccel
using RayTrace
using MatrixTools

function GenObjects(numb)
    oa = ObjectArray(numb)
    for i in 1:length(oa)
        oa[i] = Sphere()
        oa[i].center  = 5.0*randn(3)
        oa[i].radius  = 0.05
        oa[i].radius2 = oa[i].radius
        oa[i].material.diffuse = ShaderRGBA(1.0, 1.0, 1.0)
        oa[i].material.glossy = ShaderRGBA(1.0, 1.0, 1.0)

        if i % 27 == 0
            oa[i].material.emission_mix = 1.0
            oa[i].material.emission.r = 2.0
            oa[i].material.emission_set = true
        else
            oa[i].material.emission_set = false
        end

        if i % 11 == 0
            oa[i].material.glossy_mix = rand()
            oa[i].material.glossy_set = true
        else
            oa[i].material.glossy_mix =0.0
            oa[i].material.glossy_set = false
        end

        if i % 7 == 0
            oa[i].material.diffuse.r = 0.0
            oa[i].material.diffuse.g = 0.0
        end
        if i % 9 == 0
            oa[i].material.diffuse.g = 0.0
            oa[i].material.diffuse.b = 0.0
        end
        if i % 10 == 0
            oa[i].material.diffuse.b = 0.0
            oa[i].material.diffuse.r = 0.0
        end
    end
    return oa
end

function GenAccelStructure(oa, n)
    aa = GenerateStructure(oa, Int64(n), Int64(n), Int64(n))
#    aa = GenerateStructure(oa)
    return aa
end

function go()
    # Warm up section
    srand(1)
    camera = Camera(10, 10)
    camera.origin = [0.0, 0.0, -40.0]
    camera.rotation = [0.0, 0.0, 0.0]

    oa = GenObjects(convert(Int64,10))
    aa = GenAccelStructure(oa, 10)

    img=render(camera, aa, 4)


    # Actual pat tracer
    srand(1)
    oa = GenObjects(convert(Int64,1000000))
    camera = Camera(800, 600)
    camera.origin = [0.0, 0.0, -40.0]
    camera.rotation = [0.0, 0.0, 0.0]
    #Profile.init(delay=0.01)
    #Profile.clear()
    #@profile @time img=render(camera, oa, 4)
    n=30
    println(n)
    aa = GenAccelStructure(oa, n)
    @time img=render(camera, aa, 40)
    save("out.png", colorview(RGB, img))
end

go()
