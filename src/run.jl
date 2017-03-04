#!/usr/bin/env julia

@everywhere push!(LOAD_PATH, ".")
using Images

using ArrayEnv
using JuliaShader


function GenObjects()
    WorldObjects=[]
    for i in 1:100
        append!(WorldObjects,[RayTrace.Sphere{Float64}()])
        WorldObjects[i].center=5*randn(3)
        if (i % 2) == 1
            WorldObjects[i].Material.ShaderType=RayTrace.glossy
        else
            WorldObjects[i].Material.ShaderValue=rand(3)
        end
    end
    return WorldObjects
end

function RenderObjects(WorldObjects,xrange,yrange)
    Img=zeros(Float64, length(xrange), length(yrange), 3)

    eyez = 25.0
    for j in 1:length(yrange)
        for i in 1:length(xrange)
            x=xrange[i]
            y=yrange[j]
            Color=0.0
            for xtw in randn(2)*0.001
                for ytw in randn(2)*0.001
                    Color+=RayTrace.Trace(WorldObjects, [0.0, 0.0, eyez], normalize([x+xtw, y+ytw, -1.0]), 128)
                end
            end
            Img[i,j]=Color/4.0
        end
        if (j % 50) == 0
            print("$(j) of $(length(xrange))\n")
        end
    end
    print("Done Rendering\n")
    
    return Img
end

function go(i)
    WorldObjects=GenObjects()
    xrange=-1.5:0.01:1.5
    yrange=-1.5:0.01:1.5
    Img=RenderObjects(WorldObjects, xrange, yrange)
    fname=@sprintf "notebook_%04d.csv" i
    print(fname)
    fid=open(fname,"w")
    write(fid,"x,y,z\n")
    for i in 1:length(xrange)
        for j in 1:length(yrange)
            write(fid,"$(xrange[i]),$(yrange[j]),$(Img[i,j])\n")
        end
    end
    close(fid)
    
    return Img
end

img=go(1)

imwrite(convert(Image, img), "test.png")
