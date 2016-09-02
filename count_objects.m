% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% count the number of objects for each class in ObjectNet3D
% count_all: the number of objects
% count_shapenet: the number of objects with shapenet annotations
function [classes, count_all, count_shapenet] = count_objects

opt = globals();

% load CAD model
object = load(fullfile(opt.root, '/CAD/cads.mat'));
cads = object.cads;
class_names = object.class_names;

classes = textread(fullfile(opt.root, 'Image_sets/classes.txt'), '%s');
n = numel(classes);
count_all = zeros(n, 1);
count_shapenet = zeros(n, 1);

fid = fopen('stats_object.txt', 'w');

files = dir(fullfile(opt.root, 'Annotations/*.mat'));
N = numel(files);

for i = 1:N
    name = files(i).name;
    filename = fullfile(opt.root, sprintf('Annotations/%s', name));
    object = load(filename);
    record = object.record;
    objects = record.objects;
    num = numel(objects);
    for j = 1:num
        cls = objects(j).class;
        cls_index = find(strcmp(cls, classes) == 1);
        count_all(cls_index) = count_all(cls_index) + 1;
        
        if isfield(objects(j), 'shapenet') && ...
                isempty(objects(j).shapenet) == 0
            count_shapenet(cls_index) = count_shapenet(cls_index) + 1;
        end
    end
end

for i = 1:n
    ind = strcmp(classes{i}, class_names);
    num = numel(cads{ind});
    fprintf(fid, '%s %d %d %d\n', classes{i}, count_all(i), count_shapenet(i), num);
end
fclose(fid);