% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% project 3D points to 2D according to the camera parameters
function x = project_3d_msid(x3d, a, e, d, f, theta, principal, viewport)

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

a = -a;
e = pi/2+e;
theta=-theta;

% rotation matrix
Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];   %rotate by a
Rx = [1 0 0; 0 cos(e) -sin(e); 0 sin(e) cos(e)];   %rotate by e
Rz2= [cos(theta), -sin(theta),0; sin(theta), cos(theta), 0; 0,0,1];
R = Rz2*Rx*Rz;

% perspective project matrix
M = viewport;
P = [M*f 0 0; 0 M*f 0; 0 0 1] * [R -R*C];

% project
x = P*[x3d ones(size(x3d,1), 1)]';
x(1,:) = x(1,:) ./ x(3,:);
x(2,:) = x(2,:) ./ x(3,:);
x = x(1:2,:)';
% transform to image coordinates
x = x + repmat(principal, size(x,1), 1);