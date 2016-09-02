% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% display CAD model and anchor points
% example: draw_cad('car', 1) 
function draw_cad(cls, index)

opt = globals();

% load mat file
filename = fullfile(opt.root, sprintf('CAD/mat/%s.mat', cls));
object = load(filename);
cads = object.(cls);
cad = cads(index);

% display mesh
trimesh(cad.faces, cad.vertices(:,1), cad.vertices(:,2), cad.vertices(:,3), 'EdgeColor', 'b');
axis equal;
hold on;

% display anchor points
pnames = cad.pnames;
for i = 1:numel(pnames)
    X = cad.(pnames{i});
    if isempty(X) == 0
        plot3(X(1), X(2), X(3), 'ro', 'LineWidth', 5);
    end
end