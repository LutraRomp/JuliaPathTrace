#!/usr/bin/env julia

push!(LOAD_PATH, "./")

using DataFrames
using Images
using FileIO

using JuliaShader
using Geometries
using ArrayEnv
using GridAccel
using RayTrace
using MatrixTools

function GenObjects(numb)
    oa = ObjectArray(numb)
    for i in 1:length(oa)
        oa[i] = Sphere()
        oa[i].center  = 10.0*randn(3)
        oa[i].radius  = 1.0
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

function GenAccelStructure(oa)
    aa = GenerateStructure(oa, 50, 50, 50)
end

function render(camera::Camera, aa, samples)
    fsamples = convert(Float64, samples)
    img = SharedArray(Float32, 3, camera.res_y, camera.res_x)
    @sync @parallel for i in 1:camera.res_x
        println("Column: $(i)")
        for j in 1:camera.res_y
            r = 0.0
            g = 0.0
            b = 0.0
            a = 0.0
            for itter = 1:samples
                ray_dir = get_ray(camera, i, j)
                x = trace_path(aa, camera.origin, ray_dir, 2)
                r += x.r
                g += x.g
                b += x.b
                a += x.a
            end
            img[1,j,i]=r/fsamples
            img[2,j,i]=g/fsamples
            img[3,j,i]=b/fsamples

            if img[1,j,i] > 1.0
                img[1,j,i] = 1.0
            end
            if img[2,j,i] > 1.0
                img[2,j,i] = 1.0
            end
            if img[3,j,i] > 1.0
                img[3,j,i] = 1.0
            end
        end
    end
    return img
end

function go()
    camera = Camera(10, 10)
    camera.origin = [0.0, 0.0, -40.0]
    camera.rotation = [0.0, 0.0, 0.0]

    oa = GenObjects(10)
    aa = GenAccelStructure(oa)

    img=render(camera, oa, 1)

    oa = GenObjects(40)
    aa = GenAccelStructure(oa)
    camera = Camera(100, 50)
    camera.origin = [0.0, 0.0, -40.0]
    camera.rotation = [0.0, 0.0, 0.0]
    @time img=render(camera, oa, 12)
    save("out.png", colorview(RGB, img))
end


go()
