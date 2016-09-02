% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% project 3D points to 2D according to the camera parameters
function x = project_3d(x3d, a, e, d, f, theta, principal, viewport)

if d == 0
    x = [];
    return;
end

a = a * pi / 180;
e = e * pi / 180;
theta = theta * pi / 180;

% camera center
C = zeros(3,1);
C(1) = d*cos(e)*sin(a);
C(2) = -d*cos(e)*cos(a);
C(3) = d*sin(e);

% Rotate coordinate system by theta is equal to rotating the model by -theta.
a = -a;
e = -(pi/2-e);

% rotation matrix
Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];   %rotate by a
Rx = [1 0 0; 0 cos(e) -sin(e); 0 sin(e) cos(e)];   %rotate by e
R = Rx*Rz;

% perspective project matrix
% however, we set the viewport to 3000, which makes the camera similar to
% an affine-camera. Exploring a real perspective camera can be a future work.
M = viewport;
P = [M*f 0 0; 0 M*f 0; 0 0 -1] * [R -R*C];

% project
x = P*[x3d ones(size(x3d,1), 1)]';
x(1,:) = x(1,:) ./ x(3,:);
x(2,:) = x(2,:) ./ x(3,:);
x = x(1:2,:);

% rotation matrix 2D
R2d = [cos(theta) -sin(theta); sin(theta) cos(theta)];
x = (R2d * x)';
% x = x';

% transform to image coordinates
x(:,2) = -1 * x(:,2);
x = x + repmat(principal, size(x,1), 1);