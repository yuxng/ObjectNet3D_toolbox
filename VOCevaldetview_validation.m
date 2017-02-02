function VOCevaldetview_validation

% path of the results
network = 'vgg16';
region_proposal = 'selective_search';
minoverlap = 0.5;
result_dir = '/var/Projects/SubCNN/fast-rcnn/output/objectnet3d/objectnet3d_val';
method = sprintf('%s_fast_rcnn_view_objectnet3d_%s_iter_160000', network, region_proposal);

poolobj = parpool;

opt = globals();
root = opt.root;

% load class name
classes = textread(sprintf('%s/Image_sets/classes.txt', root), '%s');
num_cls = numel(classes);

% load validation set
gtids = textread(sprintf('%s/Image_sets/val.txt', root), '%s');
M = numel(gtids);

% read ground truth
recs = cell(1, M);
count = 0;
for i = 1:M
    % read ground truth 
    filename = sprintf('%s/Annotations/%s.mat', root, gtids{i});
    object = load(filename);
    recs{i} = object.record;
    count = count + numel(object.record.objects);
end
fprintf('load ground truth done, %d objects\n', count);

recalls_det = cell(num_cls, 1);
precisions_det = cell(num_cls, 1);
aps_det = zeros(num_cls, 1);

recalls_view = cell(num_cls, 1);
precisions_view = cell(num_cls, 1);
aps_view = zeros(num_cls, 1);
similarities_view = cell(num_cls, 1);
accuracies_view = cell(num_cls, 1);
avps_view = zeros(num_cls, 1);
avss_view = zeros(num_cls, 1);
errors_view = cell(num_cls, 1);
parfor k = 1:num_cls
    cls = classes{k};
    
    % extract ground truth objects
    npos = 0;
    npos_view = 0;
    gt = [];
    for i = 1:M
        % extract objects of class
        clsinds = strmatch(cls, {recs{i}.objects(:).class}, 'exact');
        gt(i).BB = cat(1, recs{i}.objects(clsinds).bbox)';
        gt(i).det = false(length(clsinds), 1);
        gt(i).ignore = false(length(clsinds), 1);
        
        % viewpoint
        num = length(clsinds);
        gt(i).view = cell(num, 1);
        gt(i).azimuth = zeros(num, 1);
        gt(i).elevation = zeros(num, 1);
        gt(i).rotation = zeros(num, 1);
        for j = 1:num
            viewpoint = recs{i}.objects(j).viewpoint;
            if isempty(viewpoint) == 1
                gt(i).ignore(j) = true;
                continue;
            end
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
            theta = viewpoint.theta;
            
            a = a * pi / 180;
            e = e * pi / 180;
            theta = theta * pi / 180;
            gt(i).view{j} = rotation_matrix(a, e, theta);
            gt(i).azimuth(j) = a;
            gt(i).elevation(j) = e;
            gt(i).rotation(j) = theta;
            npos_view = npos_view + 1;
        end
        
        npos = npos + length(clsinds);
    end

    % load detections
    filename = sprintf('%s/%s/detections_%s.txt', result_dir, method, cls);
    fid = fopen(filename, 'r');
    C = textscan(fid, '%s %f %f %f %f %f %f %f %f');
    fclose(fid);
    
    ids = C{1};
    b1 = C{2};
    b2 = C{3};
    b3 = C{4};
    b4 = C{5};
    confidence = C{6};
    azimuth = C{7};
    elevation = C{8};
    rotation = C{9};
    BB = [b1 b2 b3 b4]';

    % sort detections by decreasing confidence
    [~, si]=sort(-confidence);
    ids = ids(si);
    BB = BB(:,si);
    azimuth = azimuth(si);
    elevation = elevation(si);
    rotation = rotation(si);

    % assign detections to ground truth objects
    nd = length(confidence);
    tp = zeros(nd, 1);
    fp = zeros(nd, 1);
    vp = zeros(nd, 1);
    vs = zeros(nd, 1);
    ignore = false(nd, 1);
    vd = zeros(nd, 3);
    tic;
    for d = 1:nd
        % display progress
        if toc > 1
            fprintf('%s: pr: compute: %d/%d\n', cls, d, nd);
            tic;
        end

        % find ground truth image
        i = find(strcmp(ids{d}, gtids) == 1);
        if isempty(i)
            error('unrecognized image "%s"', ids{d});
        elseif length(i)>1
            error('multiple image "%s"', ids{d});
        end

        % assign detection to ground truth object if any
        bb = BB(:,d);
        ovmax = -inf;
        jmax = -1;
        for j = 1:size(gt(i).BB, 2)
            bbgt = gt(i).BB(:,j);
            bi = [max(bb(1),bbgt(1)) ; max(bb(2),bbgt(2)) ; min(bb(3),bbgt(3)) ; min(bb(4),bbgt(4))];
            iw = bi(3) - bi(1) + 1;
            ih = bi(4) - bi(2) + 1;
            if iw > 0 && ih > 0                
                % compute overlap as area of intersection / area of union
                ua=(bb(3)-bb(1)+1)*(bb(4)-bb(2)+1)+...
                   (bbgt(3)-bbgt(1)+1)*(bbgt(4)-bbgt(2)+1)-...
                   iw*ih;
                ov= iw * ih / ua;
                if ov > ovmax
                    ovmax = ov;
                    jmax = j;
                end
            end
        end
        % assign detection as true positive/don't care/false positive
        if ovmax >= minoverlap
            if ~gt(i).det(jmax)
                tp(d) = 1;            % true positive
                gt(i).det(jmax) = true;
                % compute viewpoint accuracy
                Rgt = gt(i).view{jmax};
                if isempty(Rgt) == 0
                    R = rotation_matrix(azimuth(d), elevation(d), rotation(d));
                    X = logm(Rgt' * R);
                    angle = 1/sqrt(2) * norm(X, 'fro');
                    % viewpoint similarity
                    vs(d) = (1 + cos(angle)) / 2;
                    % viewpoint accraucy
                    if abs(angle) < pi/6
                        vp(d) = 1;
                    end
                    
                    % compute angle errors
                    da = abs(angdiff(azimuth(d), gt(i).azimuth(jmax)));
                    de = abs(angdiff(elevation(d), gt(i).elevation(jmax)));
                    dr = abs(angdiff(rotation(d), gt(i).rotation(jmax)));
                    vd(d, 1) = da / ( da + de + dr);
                    vd(d, 2) = de / ( da + de + dr);
                    vd(d, 3) = dr / ( da + de + dr);
                end
            else
                fp(d) = 1;            % false positive (multiple detection)
            end
            if gt(i).ignore(jmax)
                ignore(d) = true;
            end
        else
            fp(d) = 1;                % false positive
        end
    end

    % compute precision/recall
    fp_det = cumsum(fp);
    tp_det = cumsum(tp);
    rec_det = tp_det / npos;
    prec_det = tp_det ./ (fp_det + tp_det);
    ap_det = VOCap(rec_det, prec_det);
    
    aps_det(k) = ap_det;
    recalls_det{k} = rec_det;
    precisions_det{k} = prec_det;
    fprintf('%s, ap: %f\n', cls, ap_det);
    
    % compute precision/recall for view
    fp_view = cumsum(fp(~ignore));
    tp_view = cumsum(tp(~ignore));
    vp_view = cumsum(vp(~ignore));
    vs_view = cumsum(vs(~ignore));
    rec_view = tp_view / npos_view;
    prec_view = tp_view ./ (fp_view + tp_view);
    ap_view = VOCap(rec_view, prec_view);
    
    accu_view = vp_view ./ (fp_view + tp_view);
    avp_view = VOCap(rec_view, accu_view);
    
    sim_view = vs_view ./ (fp_view + tp_view);
    avs_view = VOCap(rec_view, sim_view);    
    
    aps_view(k) = ap_view;
    avps_view(k) = avp_view;
    avss_view(k) = avs_view;    
    recalls_view{k} = rec_view;
    precisions_view{k} = prec_view;
    accuracies_view{k} = accu_view;
    similarities_view{k} = sim_view;
    fprintf('%s, ap view: %f, avp view %f, avs view %f\n', cls, ap_view, avp_view, avs_view);
    
    % keep the view error distribution
    vd = vd(tp == 1 & ignore == 0, :);
    errors_view{k} = vd;
end

% write to file
fid = fopen(sprintf('views_%s_%d.txt', method, minoverlap*100), 'w');
for i = 1:num_cls
    fprintf(fid, '%s %f %f %f %f\n', classes{i}, aps_det(i), aps_view(i), avps_view(i), avss_view(i));
end
fprintf(fid, 'mAP %f %f %f %f\n', mean(aps_det), mean(aps_view), mean(avps_view), mean(avss_view));
fclose(fid);

% save to matfile
matfile = sprintf('views_%s_%d.mat', method, minoverlap*100);
save(matfile, 'recalls_det', 'precisions_det', 'aps_det', ...
    'recalls_view', 'precisions_view', 'aps_view', 'avps_view', 'avss_view', 'errors_view', '-v7.3');

delete(poolobj);

function d = angdiff(a, b)

d = a - b;
if d > pi
    d = d - 2*pi;
end
if d < -pi
    d = d + 2*pi;
end