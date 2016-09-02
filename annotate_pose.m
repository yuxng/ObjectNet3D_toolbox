% --------------------------------------------------------
% ObjectNet3D
% Copyright (c) 2016 CVGL Stanford University
% Licensed under The MIT License [see LICENSE for details]
% Written by Wonhui Kim, Yu Xiang
% --------------------------------------------------------
% pose annotation tool
function varargout = annotate_pose(varargin)
% ANNOTATE_POSE MATLAB code for annotate_pose.fig
%      ANNOTATE_POSE, by itself, creates a new ANNOTATE_POSE or raises the existing
%      singleton*.
%
%      H = ANNOTATE_POSE returns the handle to a new ANNOTATE_POSE or the handle to
%      the existing singleton*.
%
%      ANNOTATE_POSE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATE_POSE.M with the given input arguments.
%
%      ANNOTATE_POSE('Property','Value',...) creates a new ANNOTATE_POSE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before annotate_pose_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to annotate_pose_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help annotate_pose

% Last Modified by GUIDE v2.5 06-Apr-2016 13:02:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @annotate_pose_OpeningFcn, ...
                   'gui_OutputFcn',  @annotate_pose_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% 

% --- Executes just before annotate_pose is made visible.
function annotate_pose_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to annotate_pose (see VARARGIN)

% Choose default command line output for annotate_pose
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes annotate_pose wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = annotate_pose_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%{
    Callback functions for the pushbuttons
%}

% --- Executes on button press in pushbutton_opendir_annotation.
function pushbutton_opendir_annotation_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_opendir_annotation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

anno_dir = uigetdir;
if isequal(anno_dir, 0)
    return
end
set(handles.text_annotation_dir, 'String', anno_dir);

% load annotation files
files = dir(sprintf('%s/*.mat', anno_dir));
num_anno_files = length(files);

% read or create a cache file
cachefile = 'cache';
if exist(cachefile, 'file')
    fid = fopen(cachefile, 'r');
    out = double(cell2mat( textscan(fid, '%d', 'delimiter', ' \n') ));
    img_pos = out(1);
    obj_pos = out(2);
    fclose(fid);
    if isempty(obj_pos)
        obj_pos = 1;
    end
    
    % read the number of objects
    filename = files(img_pos).name;
    obj = load(sprintf('%s/%s', anno_dir, filename));
    record = obj.record;
    num_objects = length(record.objects);    
    
else
    img_pos = 1;
    obj_pos = 1;
    num_objects = 1;
end

flag = 0;
while img_pos <= num_anno_files && obj_pos <= num_objects && flag == 0
    
    % load mat-format annotation file
    % annotation file name should start with 'n'
    filename = files(img_pos).name;
    assert( strcmp(filename(1), 'n') )
    assert( strcmp(filename(end-3:end), '.mat') )
    
    % load object
    obj = load(sprintf('%s/%s', anno_dir, filename));
    record = obj.record;
    img_filename = record.filename;
    object = record.objects(obj_pos);    
    num_objects = length(record.objects);
    
    % class name
    cls = object.class;
    
    % bbox and cad
    bbox = object.bbox;
    cad_index = object.cad_index;
    if isempty(cad_index)
        cad_index = 1;
    end    
    
    % viewpoint
    if isfield(object.viewpoint, 'azimuth_coarse') == 0
        azimuth = 0;
    else
        azimuth = object.viewpoint.azimuth_coarse;
    end
    if isfield(object.viewpoint, 'elevation_coarse') == 0
        elevation = 0;
    else
        elevation = object.viewpoint.elevation_coarse;
    end
    if isfield(object.viewpoint, 'theta') == 0
        theta = 0;
    else
        theta = object.viewpoint.theta; % mod(object.viewpoint.theta, 360);
    end
    if isfield(object.viewpoint, 'distance') == 0
        distance = 5;
    else
        distance = object.viewpoint.distance;
    end
    if isfield(object.viewpoint, 'focal') == 0
        focal = 1;
    else
        focal = object.viewpoint.focal;
    end
    if isfield(object.viewpoint, 'px') == 0
        px = [];
    else
        px = object.viewpoint.px;
    end
    if isfield(object.viewpoint, 'py') == 0
        py = [];
    else
        py = object.viewpoint.py;
    end
    if isfield(object.viewpoint, 'viewport') == 0
        viewport = [];
    else
        viewport = object.viewpoint.viewport;    
    end
    if isempty(theta), theta = 0; end
    if isempty(distance), distance = 5; end
    if isempty(focal), focal = 1; end
    if isempty(viewport), viewport = 2000; end
    if isempty(px), px = (bbox(3) + bbox(1))/2; end
    if isempty(py), py = (bbox(4) + bbox(2))/2; end

    % occlusion, truncation, difficulty
    if ~isempty(object.truncated) && object.truncated == 1
        handles.truncated = 1;
    else
        handles.truncated = 0;
    end
    if ~isempty(object.occluded) && object.occluded == 1
        handles.occluded = 1;
    else
        handles.occluded = 0;
    end
    if ~isempty(object.difficult) && object.difficult == 1
        handles.difficult = 1;
    else
        handles.difficult = 0;
    end
    
    % annotation loaded successfully
    flag = 1;

    % activate callback functions
    set(handles.pushbutton_opendir_image, 'Enable', 'On');
    set(handles.pushbutton_opendir_mesh, 'Enable', 'On');
end

if flag == 0
    errordlg('No anontation file in the directory.');
else
    handles.name = filename(1:end-4);
    handles.img_name = img_filename;
    handles.anno_dir = anno_dir;
    handles.img_dir = '.';
    handles.mesh_dir = '.';
    handles.files = files; % annotation mat files
    handles.filepos = img_pos; % image position; counter
    handles.objpos = obj_pos; % object(bounding box) position; counter
    handles.num_objects = num_objects;
    handles.cls = cls;
    handles.bbox = bbox;
    handles.azimuth = azimuth;
    handles.elevation = elevation;
    handles.theta = theta; % in-plane rotation
    handles.distance = distance; % default distance value
    handles.focal = focal;
    handles.px = px;
    handles.py = py;
    handles.viewport = viewport;
    handles.cad_index = cad_index; % cad id
    handles.overlay_on = 0;
    handles.count_save = 0;
    set(handles.text_count, 'String', ['#Annotation saved: ' num2str(handles.count_save)]);
    guidata(hObject, handles);
end

% --- Executes on button press in pushbutton_opendir_image.
function pushbutton_opendir_image_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_opendir_image (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

img_dir = uigetdir(sprintf('%s/..',handles.anno_dir));
if isequal(img_dir, 0)
    return
end
set(handles.text_image_dir, 'String', img_dir);
set(handles.text_image_filename, 'String', handles.img_name);

% load image
filename = sprintf('%s/%s', img_dir, handles.img_name);
if exist(filename, 'file')
    I = imread(filename);
    handles.image = I;
    
    % draw the bounding box
    bbox = handles.bbox;
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla;
    imshow(I); hold on
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    hold off
else
    set(handles.text_image_filename, 'String', 'No image available!');
end

handles.img_dir = img_dir;
guidata(hObject, handles);

% activate callback functions
set(handles.pushbutton_next, 'Enable', 'On');
set(handles.pushbutton_prev, 'Enable', 'On');
set(handles.pushbutton_save, 'Enable', 'On');
set(handles.checkbox_truncated, 'Enable', 'On');
set(handles.checkbox_occluded, 'Enable', 'On');
set(handles.checkbox_difficult, 'Enable', 'On');
set(handles.togglebutton_display_overlay, 'Enable', 'On');


% --- Executes on button press in pushbutton_opendir_mesh.
function pushbutton_opendir_mesh_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_opendir_mesh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% mesh directory string
mesh_dir = uigetdir(sprintf('%s/..',handles.anno_dir));
if isequal(mesh_dir, 0) || isempty(mesh_dir)
    return
end
set(handles.text_mesh_dir, 'String', mesh_dir);

% load all cad models from the mat file
fprintf('Loading mesh files ......\n');
fprintf('This will take some time. Please wait until you see the message "done".\n');
obj = load(sprintf('%s/cads.mat', mesh_dir));
cads = obj.cads;
class_names = obj.class_names;
assert(~isempty(obj))

% save vertices and faces
handles.cads = cads;
handles.class_names = class_names;
handles.cls_ind = find(strcmp(class_names, handles.cls) == 1);

% validity check
if isempty(handles.cad_index) || handles.cad_index > length(cads{handles.cls_ind})
    handles.cad_index = 1;
end

% display one cad model in the current axis
faces = handles.cads{handles.cls_ind}(handles.cad_index).faces;
vertices = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
set(handles.figure1, 'CurrentAxes', handles.display_mesh);
trimesh(faces,vertices(:,1),vertices(:,2),vertices(:,3), 'EdgeColor','b');
view([handles.azimuth, handles.elevation]);
axis equal, axis off
rotate3d on
% h = rotate3d(handles.display_mesh);
% set(h, 'ActionPostCallback', @rotate3d_post_Callback);
% set(h, 'Enable', 'on');

handles.mesh_dir = mesh_dir;
guidata(hObject, handles);

fprintf('done.\n\n');

% click the overlay_on/off pushbutton
set(handles.togglebutton_display_overlay, 'Value', get(handles.togglebutton_display_overlay,'Max'));
togglebutton_display_overlay_Callback(hObject, eventdata, handles);

% activate prev/next pushbuttons
set(handles.pushbutton_prev_cad, 'Enable', 'On');
set(handles.pushbutton_next_cad, 'Enable', 'On');

% --- Executes on button press in pushbutton_next.
function pushbutton_next_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

anno_dir = handles.anno_dir;
files = handles.files;
img_pos = handles.filepos;
obj_pos = handles.objpos;
num_anno_files = length(files);
num_objects = handles.num_objects;
flag = 0;

set(handles.text_save, 'String', '');
set(handles.pushbutton_left, 'Enable', 'Off');
set(handles.pushbutton_right, 'Enable', 'Off');
set(handles.pushbutton_up, 'Enable', 'Off');
set(handles.pushbutton_down, 'Enable', 'Off');
set(handles.slider_zoom, 'Enable', 'Off');
set(handles.slider_rotate_inplane, 'Enable', 'Off');
set(handles.togglebutton_display_overlay, 'Value', get(handles.togglebutton_display_overlay,'Max'));

if obj_pos == num_objects
    img_pos = img_pos + 1;
    obj_pos = 1;
else
    obj_pos = obj_pos + 1;
end

while img_pos <= num_anno_files && obj_pos <= num_objects && flag == 0
    
    filename = files(img_pos).name;
    assert( strcmp(filename(1), 'n') )
    assert( strcmp(filename(end-3:end), '.mat') )
    
    obj = load(sprintf('%s/%s', anno_dir, filename));
    record = obj.record;
    img_filename = record.filename;
    object = record.objects(obj_pos);    
    num_objects = length(record.objects);
    
    % class name and index
    cls = object.class;
    cls_ind = find(strcmp(handles.class_names, cls) == 1);
    
    % bbox and cad
    bbox = object.bbox;
    cad_index = object.cad_index;
    if isempty(cad_index) || cad_index > length(handles.cads)
        cad_index = 1;
    end
    
    % viewpoint
    if isfield(object.viewpoint, 'azimuth_coarse') == 0
        azimuth = 0;
    else
        azimuth = object.viewpoint.azimuth_coarse;
    end
    if isfield(object.viewpoint, 'elevation_coarse') == 0
        elevation = 0;
    else
        elevation = object.viewpoint.elevation_coarse;
    end
    if isfield(object.viewpoint, 'theta') == 0
        theta = 0;
    else
        theta = object.viewpoint.theta; % mod(object.viewpoint.theta, 360);
    end
    if isfield(object.viewpoint, 'distance') == 0
        distance = 5;
    else
        distance = object.viewpoint.distance;
    end
    if isfield(object.viewpoint, 'focal') == 0
        focal = 1;
    else
        focal = object.viewpoint.focal;
    end
    if isfield(object.viewpoint, 'px') == 0
        px = [];
    else
        px = object.viewpoint.px;
    end
    if isfield(object.viewpoint, 'py') == 0
        py = [];
    else
        py = object.viewpoint.py;
    end
    if isfield(object.viewpoint, 'viewport') == 0
        viewport = [];
    else
        viewport = object.viewpoint.viewport;    
    end
    if isempty(theta), theta = 0; end
    if isempty(distance), distance = 5; end
    if isempty(focal), focal = 1; end
    if isempty(viewport), viewport = 2000; end
    if isempty(px), px = (bbox(3) + bbox(1))/2; end
    if isempty(py), py = (bbox(4) + bbox(2))/2; end
    
    % occlusion, truncation, difficulty
    if ~isempty(object.truncated) && object.truncated == 1
        handles.truncated = 1;
    else
        handles.truncated = 0;
    end
    if ~isempty(object.occluded) && object.occluded == 1
        handles.occluded = 1;
    else
        handles.occluded = 0;
    end
    if ~isempty(object.difficult) && object.difficult == 1
        handles.difficult = 1;
    else
        handles.difficult = 0;
    end
    
    flag = 1;

    set(handles.text_image_filename, 'String', img_filename);
    set(handles.checkbox_truncated, 'Value', handles.truncated);
    set(handles.checkbox_occluded, 'Value', handles.occluded);
    set(handles.checkbox_difficult, 'Value', handles.difficult);
    
    % load image
    imfilename = sprintf('%s/%s', handles.img_dir, img_filename);
    if exist(imfilename, 'file')
        I = imread(imfilename);
        handles.image = I;
        
        % draw the bounding box
        set(handles.display_image, 'NextPlot', 'replace');
        set(handles.figure1, 'CurrentAxes', handles.display_image);
        cla;
        imshow(I); hold on
        rectangle('EdgeColor', 'g', ...
            'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
        hold off
    else
        set(handles.text_image_filename, 'String', 'No image available!');
    end    
    
    % load mesh
    set(handles.figure1, 'CurrentAxes', handles.display_mesh);
    vertices = handles.cads{cls_ind}(cad_index).vertices;
    faces = handles.cads{cls_ind}(cad_index).faces;
    trimesh(faces, vertices(:,1), vertices(:,2), vertices(:,3), 'EdgeColor', 'b');
    xlabel('x'); ylabel('y'); zlabel('z'); axis equal; axis off;    
    view([azimuth, elevation]);
    rotate3d on
%     h = rotate3d(handles.display_mesh);
%     set(h, 'ActionPostCallback', @rotate3d_post_Callback);
%     set(h, 'Enable', 'on');
end

if flag == 0
    errordlg('No annotation file left.');
else
    handles.name = filename(1:end-4);
    handles.img_name = img_filename;
    handles.filepos = img_pos;
    handles.objpos = obj_pos;
    handles.num_objects = num_objects;
    handles.cls = cls;
    handles.cls_ind = cls_ind;
    handles.bbox = bbox;
    handles.azimuth = azimuth;
    handles.elevation = elevation;
    handles.theta = theta; % in-plane rotation
    handles.distance = distance; % default distance value    
    handles.focal = focal;
    handles.px = px;
    handles.py = py;
    handles.viewport = viewport;    
    handles.cad_index = cad_index;
    handles.overlay_on = 0;    
    guidata(hObject, handles);
end

togglebutton_display_overlay_Callback(hObject, eventdata, handles);

% --- Executes on button press in pushbutton_prev.
function pushbutton_prev_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_prev (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

anno_dir = handles.anno_dir;
files = handles.files;
img_pos = handles.filepos;
obj_pos = handles.objpos;
num_anno_files = length(files);
num_objects = handles.num_objects;
flag = 0;

set(handles.text_save, 'String', '');
set(handles.pushbutton_left, 'Enable', 'Off');
set(handles.pushbutton_right, 'Enable', 'Off');
set(handles.pushbutton_up, 'Enable', 'Off');
set(handles.pushbutton_down, 'Enable', 'Off');
set(handles.slider_zoom, 'Enable', 'Off');
set(handles.slider_rotate_inplane, 'Enable', 'Off');
set(handles.togglebutton_display_overlay, 'Value', get(handles.togglebutton_display_overlay,'Max'));

if obj_pos > 1 % no need to load image
    obj_pos = obj_pos - 1;
    flag = 1;
else
    img_pos = img_pos - 1;
end

if img_pos >= 1
    
    filename = files(img_pos).name;
    assert( strcmp(filename(1), 'n') )
    assert( strcmp(filename(end-3:end), '.mat') )
    
    obj = load(sprintf('%s/%s', anno_dir, filename));
    record = obj.record;
    img_filename = record.filename;
    num_objects = length(record.objects);    
    if flag == 0
        obj_pos = num_objects;
    end       
    object = record.objects(obj_pos);
    
    % class name and index
    cls = object.class;
    cls_ind = find(strcmp(handles.class_names, cls) == 1);    
    
    % bbox and cad
    bbox = object.bbox;
    cad_index = object.cad_index;
    if isempty(cad_index) || cad_index > length(handles.cads)
        cad_index = 1;
    end
    
    % viewpoint
    if isfield(object.viewpoint, 'azimuth_coarse') == 0
        azimuth = 0;
    else
        azimuth = object.viewpoint.azimuth_coarse;
    end
    if isfield(object.viewpoint, 'elevation_coarse') == 0
        elevation = 0;
    else
        elevation = object.viewpoint.elevation_coarse;
    end
    if isfield(object.viewpoint, 'theta') == 0
        theta = 0;
    else
        theta = object.viewpoint.theta; % mod(object.viewpoint.theta, 360);
    end
    if isfield(object.viewpoint, 'distance') == 0
        distance = 5;
    else
        distance = object.viewpoint.distance;
    end
    if isfield(object.viewpoint, 'focal') == 0
        focal = 1;
    else
        focal = object.viewpoint.focal;
    end
    if isfield(object.viewpoint, 'px') == 0
        px = [];
    else
        px = object.viewpoint.px;
    end
    if isfield(object.viewpoint, 'py') == 0
        py = [];
    else
        py = object.viewpoint.py;
    end
    if isfield(object.viewpoint, 'viewport') == 0
        viewport = [];
    else
        viewport = object.viewpoint.viewport;    
    end    
      
    if isempty(theta), theta = 0; end
    if isempty(distance), distance = 5; end
    if isempty(focal), focal = 1; end
    if isempty(viewport), viewport = 2000; end
    if isempty(px), px = (bbox(3) + bbox(1))/2; end
    if isempty(py), py = (bbox(4) + bbox(2))/2; end

    % occlusion, truncation, difficulty
    if ~isempty(object.truncated) && object.truncated == 1
        handles.truncated = 1;
    else
        handles.truncated = 0;
    end
    if ~isempty(object.occluded) && object.occluded == 1
        handles.occluded = 1;
    else
        handles.occluded = 0;
    end
    if ~isempty(object.difficult) && object.difficult == 1
        handles.difficult = 1;
    else
        handles.difficult = 0;
    end    
    
    set(handles.text_image_filename, 'String', img_filename);
    set(handles.checkbox_truncated, 'Value', handles.truncated);
    set(handles.checkbox_occluded, 'Value', handles.occluded);
    set(handles.checkbox_difficult, 'Value', handles.difficult);
    
    % load image
    imfilename = sprintf('%s/%s', handles.img_dir, img_filename);
    if exist(imfilename, 'file')
        I = imread(imfilename);
        handles.image = I;
        
        % draw the bounding box
        set(handles.display_image, 'NextPlot', 'replace');
        set(handles.figure1, 'CurrentAxes', handles.display_image);
        cla;
        imshow(I); hold on
        rectangle('EdgeColor', 'g', ...
            'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
        hold off
    else
        set(handles.text_image_filename, 'String', 'No image available!');
    end

    % load mesh
    set(handles.figure1, 'CurrentAxes', handles.display_mesh);
    vertices = handles.cads{cls_ind}(cad_index).vertices;
    faces = handles.cads{cls_ind}(cad_index).faces;
    trimesh(faces, vertices(:,1), vertices(:,2), vertices(:,3), 'EdgeColor', 'b');
    xlabel('x'); ylabel('y'); zlabel('z'); axis equal; axis off;
    view([azimuth, elevation]);
    rotate3d on

    handles.name = filename(1:end-4);
    handles.img_name = img_filename;
    handles.filepos = img_pos;
    handles.objpos = obj_pos;
    handles.num_objects = num_objects;
    handles.cls = cls;
    handles.cls_ind = cls_ind;
    handles.bbox = bbox;
    handles.azimuth = azimuth;
    handles.elevation = elevation;
    handles.theta = theta; % in-plane rotation
    handles.distance = distance; % default distance value
    handles.focal = focal;
    handles.px = px;
    handles.py = py;
    handles.viewport = viewport;
    handles.cad_index = cad_index;
    handles.overlay_on = 0;
    guidata(hObject, handles);

else
    errordlg('No annotation file left.');
end

togglebutton_display_overlay_Callback(hObject, eventdata, handles);



% --- Executes on button press in pushbutton_save.
function pushbutton_save_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.figure1, 'CurrentAxes', handles.display_mesh);
[handles.azimuth, handles.elevation] = view;

matfile = sprintf('%s/%s.mat', handles.anno_dir, handles.name);
if exist(matfile, 'file')    
    obj = load(matfile);
    record = obj.record;
    assert( handles.objpos <= length(record.objects) )
    
    record.objects(handles.objpos).cad_index = handles.cad_index;
    record.objects(handles.objpos).viewpoint.azimuth_coarse = handles.azimuth;
    record.objects(handles.objpos).viewpoint.elevation_coarse = handles.elevation;
    record.objects(handles.objpos).viewpoint.theta = handles.theta; % mod(handles.theta, 360);
    record.objects(handles.objpos).viewpoint.distance = handles.distance;
    record.objects(handles.objpos).viewpoint.px = handles.px;
    record.objects(handles.objpos).viewpoint.py = handles.py;
    record.objects(handles.objpos).viewpoint.focal = handles.focal;
    record.objects(handles.objpos).viewpoint.viewport = handles.viewport;
    record.objects(handles.objpos).truncated = handles.truncated;
    record.objects(handles.objpos).occluded = handles.occluded;
    record.objects(handles.objpos).difficult = handles.difficult;
    save(matfile, 'record', '-v7.3');    
    set(handles.text_save, 'String', 'Annotation saved.');
    
    handles.count_save = handles.count_save + 1;
    set(handles.text_count, 'String', ['#Annotation saved: ' num2str(handles.count_save)]);
    guidata(hObject, handles);
else
    set(handles.text_save, 'String', 'No annotation available!');
end

% save current image/object position to cache
cachefile = 'cache';
fid = fopen(cachefile, 'w');
fprintf(fid, '%d %d\n', handles.filepos, handles.objpos);
fclose(fid);


% --- Executes on button press in togglebutton_display_overlay.
function togglebutton_display_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton_display_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton_display_overlay
% set(handles.figure1, 'CurrentAxes', handles.display_image);

if get(hObject, 'Value') == get(hObject, 'Min')
    handles.overlay_on = 1;
    % de-activate opendir pushbuttons
    set(handles.pushbutton_left, 'Enable', 'Off');
    set(handles.pushbutton_right, 'Enable', 'Off');
    set(handles.pushbutton_up, 'Enable', 'Off');
    set(handles.pushbutton_down, 'Enable', 'Off');
    set(handles.pushbutton_update_overlay, 'Enable', 'Off');
    set(handles.slider_zoom, 'Enable', 'Off');
    set(handles.slider_rotate_inplane, 'Enable', 'Off');
    
    % disp('Do nothing!');
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on
    bbox = handles.bbox;
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    hold off
end
if get(hObject, 'Value') == get(hObject, 'Max')
    
    handles.overlay_on = 1;
    % activate opendir pushbuttons
    set(handles.pushbutton_left, 'Enable', 'On');
    set(handles.pushbutton_right, 'Enable', 'On');
    set(handles.pushbutton_up, 'Enable', 'On');
    set(handles.pushbutton_down, 'Enable', 'On');
    set(handles.pushbutton_update_overlay, 'Enable', 'On');    
    set(handles.slider_rotate_inplane, 'Enable', 'On');
    set(handles.slider_zoom, 'Enable', 'On');
    set(handles.slider_rotate_inplane,'Value', -sin(handles.theta*pi/180/2));
    set(handles.slider_zoom,'Value', max( get(handles.slider_zoom,'Min'), ...
        min(get(handles.slider_zoom,'Max'), -log(handles.distance)) ));
    
    set(handles.figure1, 'CurrentAxes', handles.display_mesh);
    [handles.azimuth, handles.elevation] = view;

    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;

    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    patch('vertices', x2d, 'faces', f, ...
            'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
end

guidata(hObject, handles);



% --- Executes on button press in pushbutton_update_overlay.
function pushbutton_update_overlay_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_update_overlay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.figure1, 'CurrentAxes', handles.display_mesh);
[handles.azimuth, handles.elevation] = view;
v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
f = handles.cads{handles.cls_ind}(handles.cad_index).faces;
x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
    handles.focal, handles.theta, [handles.px handles.py], handles.viewport);

set(handles.display_image, 'NextPlot', 'replacechildren');
set(handles.figure1, 'CurrentAxes', handles.display_image);
cla(handles.figure1);
imshow(handles.image); hold on
bbox = handles.bbox;
rectangle('EdgeColor', 'g', ...
    'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
patch('vertices', x2d, 'faces', f, ...
    'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
hold off

guidata(hObject, handles);




% --- Executes on button press in pushbutton_right.
function pushbutton_left_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

step_size = (handles.bbox(3)-handles.bbox(1)+1) / 30;
handles.px = handles.px - step_size;
guidata(hObject, handles);

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end


% --- Executes on button press in pushbutton_right.
function pushbutton_right_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_right (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

step_size = (handles.bbox(3)-handles.bbox(1)+1) / 30;
handles.px = handles.px + step_size;
guidata(hObject, handles);

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end


% --- Executes on button press in pushbutton_up.
function pushbutton_up_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_up (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

step_size = (handles.bbox(4)-handles.bbox(2)+1) / 30;
handles.py = handles.py - step_size;
guidata(hObject, handles);

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end


% --- Executes on button press in pushbutton_down.
function pushbutton_down_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_down (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

step_size = (handles.bbox(4)-handles.bbox(2)+1) / 30;
handles.py = handles.py + step_size;
guidata(hObject, handles);

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end


% --- Executes on slider movement.
function slider_zoom_Callback(hObject, eventdata, handles)
% hObject    handle to slider_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.distance = exp(-get(hObject,'Value'));

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end

guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function slider_zoom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_zoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


%{
    Callback and Create functions for the slider
%}

% --- Executes on slider movement.
function slider_rotate_inplane_Callback(hObject, eventdata, handles)
% hObject    handle to slider_rotate_inplane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

handles.theta = 2 * asin_linear(-get(hObject, 'Value'), ...
    get(hObject,'Min'), get(hObject,'Max')) / pi * 180; % radian to degree
set(handles.text_slider, 'String', sprintf('%.2f degree', -handles.theta));
% handles.theta = mod(360 * (get(hObject,'Value') - get(hObject,'Min')) ...
%     / (get(hObject,'Max') - get(hObject,'Min')), 360);
% set(handles.text_slider, 'String', sprintf('%.2f degree', handles.theta));

% display new overlay
if handles.overlay_on
    bbox = handles.bbox;
    v = handles.cads{handles.cls_ind}(handles.cad_index).vertices;
    f = handles.cads{handles.cls_ind}(handles.cad_index).faces;    
    x2d = project_3d(v, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on    
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);
    patch('vertices', x2d, 'faces', f, ...
        'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end

guidata(hObject, handles);

% if overlay is on, then update the overlay



% --- Executes during object creation, after setting all properties.
function slider_rotate_inplane_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider_rotate_inplane (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
    set(hObject,'Value',mod(handles.theta, 360)/360);
end

%{
    Callback functions for the checkboxes
%}

% --- Executes on button press in checkbox_truncated.
function checkbox_truncated_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_truncated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.truncated = ( get(hObject, 'Value') == get(hObject, 'Max') );
guidata(hObject, handles);

% --- Executes on button press in checkbox_occluded.
function checkbox_occluded_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_occluded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.occluded = ( get(hObject, 'Value') == get(hObject, 'Max') );
guidata(hObject, handles);


% --- Executes on button press in checkbox_difficult.
function checkbox_difficult_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_difficult (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_difficult
handles.difficult = ( get(hObject, 'Value') == get(hObject, 'Max') );
guidata(hObject, handles);

% --- Executes on key press with focus on figure1 and none of its controls.
function keyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

switch eventdata.Key
    case 'n'
        pushbutton_next_Callback(hObject, eventdata, handles);
    case 'p'
        pushbutton_prev_Callback(hObject, eventdata, handles);
    case 's'
        pushbutton_save_Callback(hObject, eventdata, handles);
end

% annotate_pose('figure1_KeyPressFcn',hObject,eventdata,guidata(hObject))


% --- Executes on button press in pushbutton_next_cad.
function pushbutton_next_cad_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_next_cad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if handles.cad_index == length(handles.cads)
%     errordlg('No next CAD.');
%     return
% end

handles.cad_index = mod(handles.cad_index, length(handles.cads{handles.cls_ind})) + 1;
faces = handles.cads{handles.cls_ind}(handles.cad_index).faces;
vertices = handles.cads{handles.cls_ind}(handles.cad_index).vertices;

set(handles.figure1, 'CurrentAxes', handles.display_mesh);
[handles.azimuth, handles.elevation] = view;
trimesh(faces, vertices(:,1),vertices(:,2),vertices(:,3), 'EdgeColor','b');
view([handles.azimuth, handles.elevation]);
axis equal, axis off
rotate3d on

guidata(hObject, handles);

if handles.overlay_on == 1
    % re-display
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on
    bbox = handles.bbox;
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);

    x2d = project_3d(vertices, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    patch('vertices', x2d, 'faces', faces, ...
            'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end

% --- Executes on button press in pushbutton_prev_cad.
function pushbutton_prev_cad_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_prev_cad (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.cad_index == 1
    handles.cad_index = length(handles.cads{handles.cls_ind}) + 1;
%     errordlg('No perv CAD.');
%     return
end

handles.cad_index = handles.cad_index - 1;
faces = handles.cads{handles.cls_ind}(handles.cad_index).faces;
vertices = handles.cads{handles.cls_ind}(handles.cad_index).vertices;

set(handles.figure1, 'CurrentAxes', handles.display_mesh);
[handles.azimuth, handles.elevation] = view;
trimesh(faces,vertices(:,1),vertices(:,2),vertices(:,3), 'EdgeColor','b');
view([handles.azimuth, handles.elevation]);
axis equal, axis off
rotate3d on

guidata(hObject, handles);

if handles.overlay_on == 1
    % re-display
    set(handles.display_image, 'NextPlot', 'replacechildren');
    set(handles.figure1, 'CurrentAxes', handles.display_image);
    cla(handles.figure1);
    imshow(handles.image); hold on
    bbox = handles.bbox;
    rectangle('EdgeColor', 'g', ...
        'Position', [bbox(1), bbox(2), bbox(3)-bbox(1)+1, bbox(4)-bbox(2)+1]);

    x2d = project_3d(vertices, handles.azimuth, handles.elevation, handles.distance, ...
        handles.focal, handles.theta, [handles.px handles.py], handles.viewport);
    patch('vertices', x2d, 'faces', faces, ...
            'FaceColor', 'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
    hold off
end

function rad = asin_linear(value, val_min, val_max)

scale = (val_max - val_min);
rad = (value - val_min) / scale * pi - pi/2;


% asin(1) * 180/pi = 90;
% asin(0) * 180/pi = 0;
% asin(-1) * 180/pi = -90;

% compare with asin function
% figure; hold on;
% plot(tmp, asin(tmp), '-rs'); 
% plot(tmp, asin_linear(tmp, -1, 1), '-bs')
