function R = rotation_matrix(a, e, theta)

a = -a;
e = pi/2+e;
theta=-theta;

% rotation matrix
Rz = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1];   %rotate by a
Rx = [1 0 0; 0 cos(e) -sin(e); 0 sin(e) cos(e)];   %rotate by e
Rz2= [cos(theta), -sin(theta),0; sin(theta), cos(theta), 0; 0,0,1];
R = Rz2*Rx*Rz;