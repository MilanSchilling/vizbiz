function [query_descriptors,database_descriptors, matches_untriang, new_kp] = eightPointRansac_cont(params, p_hom_i1, p_hom_i2, matches, K1, K2)
% Estimates the essential matrix from a set of image keypoints and
% robustifies pose estimate with RANSAC rejecting outlier keypoint
% correspondences.
% 
% Input:
%  - params(struct) : parameter struct
%  - p_hom_i1(3xN) :  2D points of image 1, each [v u]
%  - p_hom_i2(3xN) : homogeneous 2D points of image 2, each [u v 1]
%  - K1(3x3) : intrinsics matrix of camera 1
%  - K2(3x3) : intrinsics matrix of camera 2
%
% Output:
%  - E(3x3) : essential matrix

global fig_init;

[~,matched_query_indices,matched_database_indices] = find(matches);
p_hom_i1 = flipud(p_hom_i1(:,matched_query_indices));
p_hom_i2 = flipud(p_hom_i2(:,matched_database_indices));

p_hom_i1 = [p_hom_i1; ones(1, size(p_hom_i1, 2))];
p_hom_i2 = [p_hom_i2; ones(1, size(p_hom_i2, 2))];

% sample size
s = 8;

% needed iterations to reach delta-probable outlier free solution
num_iterations = ceil(log(1-params.eightPoint_ransac.p_success)/...
                 log(1-params.eightPoint_ransac.fract_inliers^s));

% initialize RANSAC
best_guess_inliers = NaN(1, size(p_hom_i2,2));
max_num_inliers_history = NaN(1,num_iterations);
max_num_inliers = 0;
inliers = zeros(1,size(p_hom_i1,2));

% run RANSAC for pose estimation
for i=1:num_iterations
    [p_hom_i1_sample,idx] = datasample(p_hom_i1,s,2,'Replace',false);
    p_hom_i2_sample = p_hom_i2(:,idx);
    
    % estimate fundamental matrix given data sample
    F_guess = fundamentalEightPoint_normalized(p_hom_i1_sample,p_hom_i2_sample);
    
    % count inliers based on pixel difference
    %errors = algError2EpipolarLine(p_hom_i1,p_hom_i2,F_guess);
    errors = geomError2EpipolarLine(p_hom_i1,p_hom_i2,F_guess);
    inliers = errors <= params.eightPoint_ransac_cont.max_error;
    num_inliers = nnz(inliers);

    if (num_inliers > max_num_inliers)        
        % update benchmark
        max_num_inliers = num_inliers;
        max_num_inliers_history(i) = num_inliers;        
        
        % save best inliers
        best_guess_inliers = inliers;
    else
        max_num_inliers_history(i) = max_num_inliers;
    end
end

% display count of inliers evolution
if params.eightPoint_ransac.show_iterations
    figure('name','8-point estimation RANSAC');
    plot(max_num_inliers_history);
    axis([0 num_iterations 0 size(p_hom_i1,2)]);
    title('Max num inliers over iterations');
    
    % display fraction of inlier matches
    fprintf('  %0.2f %% of inliers matches found\n',100*max_num_inliers/size(p_hom_i1,2));
end

% display best guess inlier matches
if params.eightPoint_ransac.show_inlier_matches
    figure(fig_init);
    subplot(2,2,4);
    plotPoints(flipud(p_hom_i2(1:2,best_guess_inliers)),'g.');
    plotMatches(1:nnz(best_guess_inliers),flipud(p_hom_i2(1:2,best_guess_inliers)),flipud(p_hom_i1(1:2,best_guess_inliers)),'y-');
    title('Inlier (yellow) matches found');
end

query_descriptors = flipud(p_hom_i1(1:2,best_guess_inliers));
new_kp = flipud(p_hom_i1(1:2,best_guess_inliers==0));
database_descriptors = flipud(p_hom_i2(1:2,best_guess_inliers));
matches_untriang = 1:size(query_descriptors, 2);


end
