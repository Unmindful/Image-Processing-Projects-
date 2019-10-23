run('../Face Detection/vlfeat-0.9.21/toolbox/vl_setup')
load('my_svm.mat')
imageDir = 'test_images';
imageList = dir(sprintf('%s/*.jpg',imageDir));
nImages = length(imageList);

bboxes = zeros(0,4);
confidences = zeros(0,1);
image_names = cell(0,1);

cellSize = 3;
dim = 36;
threshold=0.1;
for i=1:nImages
    % load and show the image
    im = im2single(imread(sprintf('%s/%s',imageDir,imageList(i).name)));
    imshow(im);
    hold on;
    
    % generate a grid of features across the entire image. you may want to 
    % try generating features more densely (i.e., not in a grid)
    feats = vl_hog(im,cellSize);
    
    % concatenate the features into 12x12 bins, and classify them (as if they
    % represent 36x36-pixel faces)
    [rows,cols,~] = size(feats);    
    confs = zeros(rows,cols);
    for r=1:rows-(dim/cellSize-1)
        for c=1:cols-(dim/cellSize-1)

        window=feats(r:r+(dim/cellSize-1),c:c+(dim/cellSize-1),:);
        featvector=window(:);
        classifier=featvector'*w+b;
        confs(r,c)=classifier;    
        % create feature vector for the current window and classify it using the SVM model, 
              
        % take dot product between feature vector and w and add b,
        % store the result in the matrix of confidence scores confs(r,c)

        end
    end
       
    % get the most confident predictions 
    [~,inds] = sort(confs(:),'descend');
    inds = inds(1:20); % (use a bigger number for better recall)
    bbox_temp = [];
    for n=1:numel(inds)        
        [row,col] = ind2sub([size(feats,1) size(feats,2)],inds(n));
        
        bbox = [ col*cellSize ...
                 row*cellSize ...
                (col*cellSize+dim-1) ...
                (row*cellSize+dim-1)];
        conf = confs(row,col);
        image_name = {imageList(i).name};
        
%         % plot
%         plot_rectangle = [bbox(1), bbox(2); ...
%             bbox(1), bbox(4); ...
%             bbox(3), bbox(4); ...
%             bbox(3), bbox(2); ...
%             bbox(1), bbox(2)];
%         plot(plot_rectangle(:,1), plot_rectangle(:,2), 'g-');
        
        % Non-max suppression
        overlapRatio = 0;
        if n>1
        overlapRatio = bboxOverlapRatio(bbox,bbox_temp);                 
        
        if overlapRatio>threshold
            bbox=[];conf=[];image_name=[];
        end
        end
        bbox_temp = [bbox_temp; bbox];
        
        % plot
        if overlapRatio<threshold
        plot_rectangle = [bbox(1), bbox(2); ...
            bbox(1), bbox(4); ...
            bbox(3), bbox(4); ...
            bbox(3), bbox(2); ...
            bbox(1), bbox(2)];
        plot(plot_rectangle(:,1), plot_rectangle(:,2), 'g-');
        end
            
        % save         
        bboxes = [bboxes; bbox];
        confidences = [confidences; conf];
        image_names = [image_names; image_name];
    end
%   pause;
%     fprintf('got preds for image %d/%d\n', i,nImages);
end

% evaluate
label_path = 'test_images_gt.txt';
[gt_ids, gt_bboxes, gt_isclaimed, tp, fp, duplicate_detections] = ...
    evaluate_detections_on_test(bboxes, confidences, image_names, label_path);
