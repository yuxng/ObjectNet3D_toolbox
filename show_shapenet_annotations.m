% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% Display the 3D shape retrieval results from ShapeNet
% Note that, our retrieval results are not perfect
% For some objects, the selected 3D shape may not similar
% Especially for occluded and truncated objects
function show_shapenet_annotations

opt = globals();

% directory for ShapeNetCore, change it to your path
shapenet_dir = opt.shapenetcore;
if exist(shapenet_dir, 'dir') == 0
    fprintf('ShapeNet path %s does not exist\n', shapenet_dir);
    return;
end

% list annotation files
ann_dir = fullfile(opt.root, 'Annotations');
filename = fullfile(ann_dir, '*.mat');
files = dir(filename);

% randomly show images
index = randperm(numel(files));
for k = index
    name = files(k).name;
    id = name(1:end-4);
    fprintf('%d: %s\n', k, id);

    % read image
    filename = fullfile(opt.root, sprintf('Images/%s.JPEG', id));
    I = imread(filename);

    % load annotation
    filename = fullfile(ann_dir, name);
    object = load(filename);
    objects = object.record.objects;
    num = numel(objects);

    % for each object
    for j = 1:num
        if isempty(objects(j).shapenet)
            continue;
        end
        
        % show image and bbox
        subplot(1, 2, 1);
        imshow(I);
        title([id '.JPEG']);
        hold on;
        bbox = objects(j).bbox;
        bbox_draw = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
        rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth', 2);
        cls = objects(j).class;
        text(bbox(1), bbox(2), cls, 'BackgroundColor', [.7 .9 .7]);
        hold off;
        
        % viewpoint information
        viewpoint = objects(j).viewpoint;
        if isfield(viewpoint, 'azimuth') == 0 || isempty(viewpoint.azimuth) == 1
            a = viewpoint.azimuth_coarse;
        else
            a = viewpoint.azimuth;
        end
        if isfield(viewpoint, 'elevation') == 0 || isempty(viewpoint.elevation) == 1
            e = viewpoint.elevation_coarse;
        else
            e = viewpoint.elevation;
        end
        fprintf('azimuth %.2f, elevation %.2f\n', a, e);

        % load shapenet model, this step is slow
        synset = objects(j).shapenet(1).synset;
        model_name = objects(j).shapenet(1).selected;
        filename = fullfile(shapenet_dir, synset, model_name{1}, 'model.obj');
        fprintf('loading model %s\n', filename);
        obj = load_obj_file(filename);
        fprintf('model loaded\n');

        % display the obj model
        subplot(1, 2, 2);
        faces = obj.f3';
        vertices = obj.v';
        trimesh(faces, vertices(:,1), vertices(:,3), vertices(:,2), 'EdgeColor', 'b');
        title(fullfile(synset, model_name{1}, 'model.obj'));
        axis equal;
        xlabel('x');
        ylabel('y');
        zlabel('z');
        
        % For 3D shapes in ShapeNet in general, the front view azimuth 
        % is 90 degree difference from our definition
        % for knife, skateborad, pillow and telephone, the 3D shapes have
        % to be handled specifically due to the alignment in ShapeNetCore
        if strcmp(cls, 'knife') || strcmp(cls, 'skateboard')
            view(a + 90 + 90, e);
        elseif strcmp(cls, 'pillow')
            view(a + 90, e + 90);
        elseif strcmp(cls, 'telephone')
            view(a + 90, -e);
        else
            view(a + 90, e);
        end
        axis off;
        
        % press any key to show the next object
        pause;
    end
end