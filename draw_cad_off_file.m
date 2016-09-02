% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% display CAD model and anchor points
% example: draw_cad_off_file('car', 1) 
function draw_cad_off_file(cls, index)

opt = globals();

% load mat file
filename = fullfile(opt.root, sprintf('CAD/mat/%s.mat', cls));
object = load(filename);
cads = object.(cls);
cad = cads(index);

filename = fullfile(opt.root, sprintf('CAD/off/%s/%02d.off', cls, index));
[vertices, faces] = load_off_file(filename);

% display mesh
figure;
trimesh(faces, vertices(:,1), vertices(:,2), vertices(:,3), 'EdgeColor', 'b');
% axis off;
axis equal;
hold on;

% display anchor points
for i = 1:numel(cad.pnames)
    filename = fullfile(opt.root, sprintf('CAD/off/%s/%02d_%s.off', cls, index, cad.pnames{i}));
    if exist(filename) == 0
        continue;
    end
    X = load_off_file(filename);
    if size(X,1) > 1
        X = mean(X);
    end
    plot3(X(1), X(2), X(3), 'ro', 'LineWidth', 5);
end