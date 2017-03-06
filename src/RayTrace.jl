module RayTrace

export Camera, get_ray, trace_path

using MatrixTools, JuliaShader, Geometries

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
    f_x = convert(Float64, res_x)
    f_y = convert(Float64, res_y)

    opposite_half = sqrt(f_x^2 + f_y^2)/2.0
    opposite_size = focal_length * tan(fov/2.0)

    return opposite_size / opposite_half
end


function get_ray(camera::Camera, i, j, jitter=false)
    p_x = convert(Float64, i - camera.res_x/2) * camera.ppu
    p_y = convert(Float64, j - camera.res_y/2) * camera.ppu

    if jitter
        p_x += 0.8*(rand()-0.5)*camera.ppu
        p_y += 0.8*(rand()-0.5)*camera.ppu
    end

    #t_m = translate(camera.origin[1], camera.origin[2], camera.origin[3])
    t_m = [1.0  0.0  0.0  0.0;
           0.0  1.0  0.0  0.0;
           0.0  0.0  1.0  0.0;
           0.0  0.0  0.0  1.0]

    t_m *= rotate_x(camera.rotation[1])
    t_m *= rotate_y(camera.rotation[2])
    t_m *= rotate_z(camera.rotation[3])

    ray_dir = t_m * [p_x, p_y, camera.focal_length, 1.0]
    return normalize(ray_dir[1:3])
end


function trace_path(world_objects, ray_orig, ray_dir, depth)
    if depth == 0
        return ShaderRGBA(0.0, 0.0, 0.0)
    end

    selected_item=0
    closest_dist=1e100
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

    ret_color = ShaderRGBA(0.0, 0.0, 0.0)

    # Shader Work
    point_hit, normal_of_hit = calc_intersection(world_objects[selected_item], ray_orig, ray_dir, closest_dist)

    glossy_mix   = world_objects[selected_item].material.glossy_mix
    emission_mix = world_objects[selected_item].material.emission_mix
    if glossy_mix < 0.9999
        new_diffuse_ray_dir = calc_diff(ray_dir, normal_of_hit)
        ret_diffuse_color = trace_path(world_objects, point_hit, new_diffuse_ray_dir, depth-1)
        diffuse_color  = world_objects[selected_item].material.diffuse * max(0.0, dot(normal_of_hit, new_diffuse_ray_dir))
        diffuse_color  = diffuse_color * ret_diffuse_color
        ret_color = (1.0-glossy_mix) * diffuse_color
    end

    if glossy_mix > 0.0001
        new_glossy_ray_dir = calc_refl(ray_dir, normal_of_hit)
        ret_glossy_color = trace_path(world_objects, point_hit, new_glossy_ray_dir, depth-1)
        glossy_color   = world_objects[selected_item].material.glossy * ret_glossy_color
        ret_color = ret_color + glossy_mix*glossy_color
    end

    if emission_mix > 0.0001
        emission_color = world_objects[selected_item].material.emission
        return mix(emission_mix, ret_color, emission_color)
    end

    return ret_color
end

end
