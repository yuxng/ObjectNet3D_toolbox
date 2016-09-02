% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% load the vertices and faces of an .off file
function [v,f] = load_off_file(filename)

v = [];
f = [];

fid = fopen(filename, 'r');
line = fgetl(fid);
if strcmp(line, 'OFF') == 0
    error('Wrong format .off file!\n');
end

line = fgetl(fid);
num = sscanf(line, '%f', 3);
nv = num(1);
nf = num(2);
v = zeros(nv,3);
f = zeros(nf,3);

for i = 1:nv
    line = fgetl(fid);
    v(i,:) = sscanf(line, '%f', 3);
end

for i = 1:nf
    line = fgetl(fid);
    fsize = sscanf(line, '%f', 1);
    if fsize ~= 3
        printf('Face contains more than 3 vertices!\n');
    end
    temp = sscanf(line, '%f', 4);
    f(i,:) = temp(2:4);
end
f = f + 1;
fclose(fid);