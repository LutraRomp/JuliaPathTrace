module RayTrace

export Camera, render

using MatrixTools, JuliaShader, Geometries, GridAccel

# Object related code
type Camera{T,U}
    origin::Array{T}
    rotation::Array{T}

    focal_length::T
    fov::T
    ppu::T

    res_x::U
    res_y::U
end

function Camera()
    origin = zeros(3)
    rotation = zeros(3)

    res_x = 1920
    res_y = 1080

    focal_length = 10.0
    fov = deg2rad(30.0)
    ppu = CalcPPU(res_x, res_y, focal_length, fov)

    Camera(origin, rotation, focal_length, fov, ppu, res_x, res_y)
end

function Camera{T<:Integer}(res_x::T, res_y::T)
    origin = zeros(3)
    rotation = zeros(3)

    focal_length = 10.0
    fov = deg2rad(30.0)
    ppu = CalcPPU(res_x, res_y, focal_length, fov)

    Camera(origin, rotation, focal_length, fov, ppu, res_x, res_y)
end

function CalcPPU{T<:Integer, U<:AbstractFloat}(res_x::T, res_y::T, focal_length::U, fov::U)
    f_x::U = convert(U, res_x)
    f_y::U = convert(U, res_y)

    opposite_half::U = sqrt(f_x^2 + f_y^2)/2.0
    opposite_size::U = focal_length * tan(fov/2.0)

    return opposite_size / opposite_half
end


function get_ray(camera::Camera, i, j, jitter=false)
    p_x::Float64 = convert(Float64, i - camera.res_x/2) * camera.ppu
    p_y::Float64 = convert(Float64, j - camera.res_y/2) * camera.ppu

    if jitter
        p_x += 0.2*randn()*camera.ppu
        p_y += 0.2*randn()*camera.ppu
    end

    # Would be a bit clearer to include this code, but
    # I'm avoiding a matrix multiply below
    #t_m = [1.0  0.0  0.0  0.0;
    #       0.0  1.0  0.0  0.0;
    #       0.0  0.0  1.0  0.0;
    #       0.0  0.0  0.0  1.0]

    t_m = rotate_x(camera.rotation[1])
    t_m *= rotate_y(camera.rotation[2])
    t_m *= rotate_z(camera.rotation[3])

    ray_dir = t_m * [p_x, p_y, camera.focal_length, 1.0]
    return normalize(ray_dir[1:3])
end


function trace_path(accel_struct, ray_orig, ray_dir, depth::Int32)
    local new_glossy_ray_dir::Array{Float64,1}
    local new_diffuse_ray_dir::Array{Float64,1}

    local diffuse_color::ShaderRGBA
    local glossy_color::ShaderRGBA
    local emission_color::ShaderRGBA

    local glossy_mix::Float64
    local emission_mix::Float64

    local world_objects = accel_struct.oa  # world_objects is the object array

    if depth == 0
        return ShaderRGBA(0.0, 0.0, 0.0)
    end

    selected_item = 0
    closest_dist = 1e100

    if (ray_orig[1] >= accel_struct.xmin) && (ray_orig[1] <= accel_struct.xmax) &&
       (ray_orig[2] >= accel_struct.ymin) && (ray_orig[2] <= accel_struct.ymax) &&
       (ray_orig[3] >= accel_struct.zmin) && (ray_orig[3] <= accel_struct.zmax)

        grid_i = convert(Int64, ceil( (ray_orig[1] - accel_struct.xmin)/accel_struct.dx ))
        grid_j = convert(Int64, ceil( (ray_orig[2] - accel_struct.ymin)/accel_struct.dy ))
        grid_k = convert(Int64, ceil( (ray_orig[3] - accel_struct.zmin)/accel_struct.dz ))

        while true
            a = accel_struct.a[grid_i, grid_j, grid_k]
            for i in 1:length(a)
                hit,dist = obj_intersect(world_objects[a[i]], ray_orig, ray_dir)
                if hit
                    if dist < closest_dist
                        selected_item=i
                        closest_dist=dist
                    end
                end
            end
            selected_item > 0 && break

            x1 = accel_struct.dx*(grid_i-1) + accel_struct.xmin
            x2 = accel_struct.dx*grid_i + accel_struct.xmin
            y1 = accel_struct.dy*(grid_j-1) + accel_struct.ymin
            y2 = accel_struct.dy*grid_j + accel_struct.ymin
            z1 = accel_struct.dz*(grid_k-1) + accel_struct.zmin
            z2 = accel_struct.dz*grid_k + accel_struct.zmin

            bx_ex = box_exit(x1, x2, y1, y2, z1, z2, ray_orig, ray_dir)
            if bx_ex == 1   grid_i = grid_i + 1  end
            if bx_ex == 2   grid_j = grid_j + 1  end
            if bx_ex == 3   grid_k = grid_k + 1  end
            if bx_ex == -1  grid_i = grid_i - 1  end
            if bx_ex == -2  grid_j = grid_j - 1  end
            if bx_ex == -3  grid_k = grid_k - 1  end

            grid_i < 1               && break
            grid_i > accel_struct.nx && break
            grid_j < 1               && break
            grid_j > accel_struct.ny && break
            grid_k < 1               && break
            grid_k > accel_struct.nz && break
         end
    else
        if selected_item == 0
            for i in 1:length(world_objects)
                hit,dist = obj_intersect(world_objects[i], ray_orig, ray_dir)
                if hit
                     if dist < closest_dist
                        selected_item=i
                        closest_dist=dist
                    end
                end
            end
        end
    end

    # If no object is seen, return ambient light conditions (hard coded for now.)
    if selected_item == 0
      return ShaderRGBA(1.0, 1.0, 1.0)
    end

    diffuse_color = ShaderRGBA(0.0, 0.0, 0.0)
    glossy_color = ShaderRGBA(0.0, 0.0, 0.0)
    emission_color = ShaderRGBA(0.0, 0.0, 0.0)
    ret_color = ShaderRGBA(0.0, 0.0, 0.0)

    # Shader Work
    point_hit, normal_of_hit = calc_intersection(world_objects[selected_item], ray_orig, ray_dir, closest_dist)

    diffuse_set   = world_objects[selected_item].material.diffuse_set
    glossy_set    = world_objects[selected_item].material.glossy_set
    emission_set  = world_objects[selected_item].material.emission_set

    if diffuse_set
        new_diffuse_ray_dir = calc_diff(ray_dir, normal_of_hit)
        ret_diffuse_color = trace_path(accel_struct, point_hit, new_diffuse_ray_dir, depth-1)
        diffuse_color = world_objects[selected_item].material.diffuse * max(0.0, dot(normal_of_hit, new_diffuse_ray_dir))
        diffuse_color = diffuse_color * ret_diffuse_color
        if !glossy_set && !emission_set
            return diffuse_color
        end
    else
        glossy_mix = 1.0
    end

    if glossy_set
        new_glossy_ray_dir = calc_refl(ray_dir, normal_of_hit)
        ret_glossy_color = trace_path(accel_struct, point_hit, new_glossy_ray_dir, depth-1)
        glossy_color = world_objects[selected_item].material.glossy * ret_glossy_color
        if !diffuse_set && !emission_set
            return glossy_color
        end
    else
        glossy_mix = 0.0
    end

    if emission_set
        emission_color = world_objects[selected_item].material.emission
        if !diffuse_set && !glossy_set
            return emission_color
        end
    else
        emission_mix = 0.0
    end

    glossy_mix   = world_objects[selected_item].material.glossy_mix
    emission_mix = world_objects[selected_item].material.emission_mix

    return mix(emission_mix, mix(glossy_mix, diffuse_color, glossy_color), emission_color)
end


function trace_path2(world_objects, ray_orig, ray_dir, depth::Int32)
    local new_glossy_ray_dir::Array{Float64,1}
    local new_diffuse_ray_dir::Array{Float64,1}

    local diffuse_color::ShaderRGBA
    local glossy_color::ShaderRGBA
    local emission_color::ShaderRGBA

    local glossy_mix::Float64
    local emission_mix::Float64

    if depth == 0
        return ShaderRGBA(0.0, 0.0, 0.0)
    end

    selected_item = 0
    closest_dist = 1e100

    for i in 1:length(world_objects)
        hit,dist=obj_intersect(world_objects[i], ray_orig, ray_dir)
        if hit
            if dist < closest_dist
                selected_item=i
                closest_dist=dist
            end
        end
    end

    # If no object is seen, return ambient light conditions (hard coded for now.)
    if selected_item == 0
      return ShaderRGBA(1.0, 1.0, 1.0)
    end

    diffuse_color = ShaderRGBA(0.0, 0.0, 0.0)
    glossy_color = ShaderRGBA(0.0, 0.0, 0.0)
    emission_color = ShaderRGBA(0.0, 0.0, 0.0)
    ret_color = ShaderRGBA(0.0, 0.0, 0.0)

    # Shader Work
    point_hit, normal_of_hit = calc_intersection(world_objects[selected_item], ray_orig, ray_dir, closest_dist)

    diffuse_set   = world_objects[selected_item].material.diffuse_set
    glossy_set    = world_objects[selected_item].material.glossy_set
    emission_set  = world_objects[selected_item].material.emission_set

    if diffuse_set
        new_diffuse_ray_dir = calc_diff(ray_dir, normal_of_hit)
        ret_diffuse_color = trace_path(world_objects, point_hit, new_diffuse_ray_dir, depth-1)
        diffuse_color = world_objects[selected_item].material.diffuse * max(0.0, dot(normal_of_hit, new_diffuse_ray_dir))
        diffuse_color = diffuse_color * ret_diffuse_color
        if !glossy_set && !emission_set
            return diffuse_color
        end
    else
        glossy_mix = 1.0
    end

    if glossy_set
        new_glossy_ray_dir = calc_refl(ray_dir, normal_of_hit)
        ret_glossy_color = trace_path(world_objects, point_hit, new_glossy_ray_dir, depth-1)
        glossy_color = world_objects[selected_item].material.glossy * ret_glossy_color
        if !diffuse_set && !emission_set
            return glossy_color
        end
    else
        glossy_mix = 0.0
    end

    if emission_set
        emission_color = world_objects[selected_item].material.emission
        if !diffuse_set && !glossy_set
            return emission_color
        end
    else
        emission_mix = 0.0
    end

    glossy_mix   = world_objects[selected_item].material.glossy_mix
    emission_mix = world_objects[selected_item].material.emission_mix

    return mix(emission_mix, mix(glossy_mix, diffuse_color, glossy_color), emission_color)
end

function render(camera::Camera, aa, samples)
    fsamples::Float64 = convert(Float64, samples)
    img = SharedArray{Float32}(3, camera.res_y, camera.res_x)
    @sync @parallel for i in 1:camera.res_x
        for j in 1:camera.res_y
        println("Column: $(i)  Row: $(j)")
            r::Float64 = 0.0
            g::Float64 = 0.0
            b::Float64 = 0.0
            a::Float64 = 0.0
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


end
