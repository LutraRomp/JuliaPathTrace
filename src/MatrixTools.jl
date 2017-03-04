module MatrixTools

export rotate_x, rotate_y, rotate_z
export scale, translate

rotate_x(theta) = [1.0  0.0         0.0          0.0;
                   0.0  cos(theta)  -sin(theta)  0.0;
                   0.0  sin(theta)  cos(theta)   0.0;
                   0.0  0.0         0.0          1.0]

rotate_y(theta) = [cos(theta)   0.0  sin(theta)  0.0;
                   0.0          1.0  0.0         0.0;
                   -sin(theta)  0.0  cos(theta)  0.0;
                   0.0          0.0  0.0         1.0]

rotate_z(theta) = [cos(theta)  -sin(theta)  0.0  0.0;
                   sin(theta)  cos(theta)   0.0  0.0;
                   0.0         0.0          1.0  0.0;
                   0.0         0.0          0.0  1.0]

scale(x, y, z)     = [x     0.0   0.0   0.0;
                      0.0   y     0.0   0.0;
                      0.0   0.0   z     0.0;
                      0.0   0.0   0.0   1.0]

translate(x, y, z) = [1.0   0.0   0.0   x; 
                      0.0   1.0   0.0   y;
                      0.0   0.0   1.0   z;
                      0.0   0.0   0.0   1.0]

end
