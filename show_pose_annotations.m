% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Yu Xiang
% --------------------------------------------------------
% Overlap 3D shapes to images according to the pose annotations
function show_pose_annotations

opt = globals();

% save the images or not
is_save = 0;
if is_save
    out_dir = 'Images_gt';
    if exist(out_dir, 'dir') == 0
        mkdir(out_dir);
    end
end

% load CAD models
fprintf('loading CAD models\n');
object = load(fullfile(opt.root, 'CAD/cads.mat'));
fprintf('CAD models loaded\n');
cads = object.cads;
class_names = object.class_names;

cmap = colormap(hsv(9));

% list annotation files
ann_dir = fullfile(opt.root, 'Annotations');
filename = fullfile(ann_dir, '*.mat');
files = dir(filename);

if is_save
    index = 1:numel(files);
else
    % randomly show annotations
    index = randperm(numel(files));
end

% for each annotation
for k = index
    name = files(k).name;
    id = name(1:end-4);
    fprintf('%d: %s\n', k, id);

    % read image
    filename = fullfile(opt.root, sprintf('Images/%s.JPEG', id));
    I = imread(filename);
    hf = figure(1);
    imshow(I);
    hold on;

    % load annotation
    filename = fullfile(ann_dir, name);
    object = load(filename);
    objects = object.record.objects;
    num = numel(objects);

    % for each object
    for j = 1:num
        % draw bounding box
        bbox = objects(j).bbox;
        bbox_draw = [bbox(1) bbox(2) bbox(3)-bbox(1) bbox(4)-bbox(2)];
        rectangle('Position', bbox_draw, 'EdgeColor', 'g', 'LineWidth', 2);
        cls = objects(j).class;
        text(bbox(1), bbox(2), cls, 'BackgroundColor', [.7 .9 .7]);

        if isempty(objects(j).viewpoint) == 0
            cls = objects(j).class;
            cls_index = find(strcmp(cls, class_names) == 1);
            cad_index = objects(j).cad_index;

            % viewpoint information
            viewpoint = objects(j).viewpoint;
            % azimuth
            if isfield(viewpoint, 'azimuth') == 0 || isempty(viewpoint.azimuth) == 1
                a = viewpoint.azimuth_coarse;
            else
                a = viewpoint.azimuth;
            end
            % elevation
            if isfield(viewpoint, 'elevation') == 0 || isempty(viewpoint.elevation) == 1
                e = viewpoint.elevation_coarse;
            else
                e = viewpoint.elevation;
            end
            
            % focal length
            f = viewpoint.focal;
            % in-plane rotation
            theta = viewpoint.theta;
            % distance
            d = viewpoint.distance;
            % principal point
            px = viewpoint.px;
            py = viewpoint.py;
            % viewport
            viewport = viewpoint.viewport;

            if isempty(theta), theta = 0; end
            if isempty(d), d = 5; end
            if isempty(f), f = 1; end
            if isempty(viewport), viewport = 2000; end
            if isempty(px), px = (bbox(3) + bbox(1))/2; end
            if isempty(py), py = (bbox(4) + bbox(2))/2; end
            principal = [px py];

            % overlap the CAD model
            vertex = cads{cls_index}(cad_index).vertices;
            face = cads{cls_index}(cad_index).faces;
            % projection function
            x2d = project_3d_msid(vertex, a, e, d, f, theta, principal, viewport);
            index_color = 1 + floor((j-1) * size(cmap,1) / num);
            patch('vertices', x2d, 'faces', face, ...
                'FaceColor', cmap(index_color,:), 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end
    end
    hold off;

    if is_save
        filename = fullfile(out_dir, [id '.png']);
        hgexport(hf, filename, hgexport('factorystyle'), 'Format', 'png');
    else
        pause;
    end
end