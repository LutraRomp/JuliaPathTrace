#!/usr/bin/julia

@enum SHADER diffuse=1 glossy=2 refraction=3

Mix(a,b,mix) = b*mix + a*(1.0-mix)

normalize(x) = x/norm(x)

CalcRefl(RayDir, Normal) = normalize( -2 * Normal * dot(RayDir,Normal) + RayDir )

function CalcDiffuse(RayDir, Normal)
    Theta = 2*pi*rand()
    z = rand()
    sz2 = sqrt(1-z*z)
    x = sz2*cos(Theta)
    y = sz2*sin(Theta)

#http://math.stackexchange.com/questions/56784/generate-a-random-direction-within-a-cone
#    v  = cross([0.0, 0.0, 1.0], Normal)
#    s  = abs(v)
#    c  = dot([0.0, 0.0, 1.0], Normal)
#    vx = 
#    R  = eye(3) + 

    w=normalize(cross([0.0, 0.0, 1.0], Normal))

    w_hat=[0 -w[3] w[2]; w[3] 0 -w[1]; -w[2] w[1] 0]

    cos_tht=normalize([0.0, 0.0, 1.0])'*normalize(Normal)
    tht=acos(cos_tht[1])

    R=eye(3)+w_hat*sin(tht)+w_hat^2*(1-cos(tht))

    return R*[x,y,z]
end

function CalcEmis(RayDir, normal)
end

function CalcRefr(RayDir, normal, n1, n2)
    eta = n1/n2
    c1 = -dot(RayDir, normal)
    cs2 = 1.0 - eta*eta*(1.0-c1*c1)
    if cs2 < 0.0
        return zeros(3)
    end
    return normalize( eta*RayDir + (eta*c1-sqrt(cs2))*normal )
end

type Camera{T}
    origin::Array{T}
    lookdir::Array{T}
    updir::Array{T}
end

type Shader{T}
    ShaderType::SHADER
    ShaderValue::T
end

type Sphere{T}
    center::Array{T}
    radius::T
    radius2::T
    Material::Shader{T}

    function Sphere()
        center=zeros(T,3)
        radius=1.0
        radius2=1.0
        Material=Shader(diffuse, T(1.0))
        new(center,radius,radius2,Material)
    end
end

function Intersect(RayOrig, RayDir, sphere::Sphere)
    l = sphere.center - RayOrig
    tca = dot(l, RayDir)
    if tca < 0
        return (false, 0.0)
    end

    d2 = dot(l, l) - (tca * tca)
    if d2 > sphere.radius2
        return (false, 0.0)
    end

    thc = sqrt(sphere.radius2 - d2)
    t0 = tca - thc
    t1 = tca + thc
    if t0 < 0
        t0 = t1
    end
    return (true, t0)
end 

function CalcNormal(RayOrig, RayDir, sphere::Sphere, t0)
    phit=RayOrig+RayDir*t0
    nhit=normalize(phit - sphere.center)
    return (phit, nhit)
end

function Trace(WorldObjects, RayOrig, RayDir, depth)
    if depth == 0
        return 0.0
    end

    SelectedItem=0
    ClosestDist=1e100
    for i in 1:length(WorldObjects)
        hit,dist=Intersect(RayOrig, RayDir, WorldObjects[i])
        if hit
            if dist < ClosestDist
                SelectedItem=i
                ClosestDist=dist
            end
        end
    end

    if SelectedItem == 0
        return 1.0     # Ambient Light.  Hard Coded for now
    end

    PointHit, NormalOfHit = CalcNormal(RayOrig, RayDir, WorldObjects[SelectedItem], ClosestDist)

    if WorldObjects[SelectedItem].Material.ShaderType == glossy
        NewRayDir = CalcRefl(RayDir, NormalOfHit)
        Multiplier = 1.0
    else
        NewRayDir = CalcDiffuse(RayDir, NormalOfHit)
        Multiplier = WorldObjects[SelectedItem].Material.ShaderValue*max(0.0,dot(NormalOfHit,NewRayDir))
    end

    return Multiplier*Trace(WorldObjects, PointHit, NewRayDir, depth-1)
end

function go()
    WorldObjects=[]
    for i in 1:100
        append!(WorldObjects,[Sphere{Float32}()])
        WorldObjects[i].center=10*(rand(Float32,3)-0.5)
        if (i % 2) == 1
            WorldObjects[i].Material.ShaderType=glossy
         end
    end

    xrange=-1:0.01:1
    yrange=-1:0.01:1

    Image=zeros(length(xrange),length(yrange))
    eyez = 10.0
    for i in 1:length(xrange)
      for j in 1:length(yrange)

          x=xrange[i]
          y=yrange[j]
          Color=0.0
          for xx in randn(2)
            xpt=x+xx/100.0
            for yy in randn(2)
              ypt=y+yy/100.0
              for s in 1:5
                  Color+=Trace(WorldObjects, [0.0, 0.0, eyez], normalize([xpt, ypt, -1.0]), 4)
              end
            end
          end

          #Image[i,j]=Color/125.0
          Image[i,j]=Color/25.0

      end
      print("Column: $(i)\n")
    end

    fname="out.csv"
    print(fname,"\n")
    fid=open(fname ,"w")
    write(fid,"x,y,z\n")
    for i in 1:length(xrange)
      for j in 1:length(yrange)
        write(fid,"$(xrange[i]),$(yrange[j]),$(Image[i,j])\n")
      end
    end
    close(fid)
end

go()
