function [T_CiCj, p_new_matched_triang, kp_tracks_updated, Cj_new_landmarks] =...
    processFrame(params,img_new,img_prev, keypoints_prev_triang, kp_tracks_prev,Ci_landmarks_prev,T_WCi,K)
% Estimates pose transformation T_CiCj between two images.
% Tracks potential new keypoints and triangulates new landmarks if
% trianguability is good.
% 
% Input:
%  - params(struct) : parameter struct
%  - img_new(size) : current frame
%  - img_prev(size) : previous frame
%  - keypoints_prev_triang (2xN) : 2D points, [v u] which have
%    corresponding Landmarks
%  - kp_tracks_old : struct container for tracking keypoints (no associated
%    landmarks)
%  - Ci_landmarks_prev(3xN) : 3D points
%  - T_WCi : (4x4) Current transformation world to Ci
%  - K(3x3) : camera intrinsics matrix
%
% Output:
%  - T_CiCj(4x4) : transformation Cj to Ci
%  - p_new_matched_triang(2xN) : newly matched keypoints with 
%    corresponding landmarks, [v u] 
%  - updated_kp_tracks : struct updated container for tracking keypoints (no associated
%    landmarks)
%  - Cj_new_landmarks (3xN) : 3D points in frame Cj
%    verified inliers by ransac + new triangulated landmarks

global fig_cont fig_kp_tracks fig_kp_triangulate;

% show current frame
if params.cont.show_current_image
    figure(fig_cont);
    subplot(2,1,1);
    imshow(img_new);
    subplot(2,1,2);
    imshow(img_new);
end

% show current frame
if params.keypoint_tracker.show_matches
    figure(fig_kp_tracks);
    % subplot(2,1,1);
    % hold on;
    % imshow(img_new);
    % subplot(2,1,2);
    
    imshow(img_new);
    hold on;
end

% show current frame
if params.keypoint_tracker.show_triangulated
    figure(fig_kp_triangulate);
    clf;
    imshow(img_new);
    hold on;
end


%% Estimate delta rotation from frame Cj to Ci
[query_keypoints,matches] = ...
    findCorrespondeces_cont(params,img_prev,keypoints_prev_triang,img_new);

% delete landmark where no matching keypoint was found
corr_ldk_matches = matches(matches > 0);
Ci_corresponding_landmarks = Ci_landmarks_prev(:,corr_ldk_matches);

[~,matched_query_indices,matched_database_indices] = find(matches);

% filter query keypoints
matched_query_keypoints = query_keypoints(:,matched_query_indices);

% filter database keypoints
matched_database_keypoints = keypoints_prev_triang(:,matched_database_indices);

% check for consistent correspondences
assert(size(matched_query_keypoints,2) == length(corr_ldk_matches) && ...
       size(matched_database_keypoints,2) == length(corr_ldk_matches));

% display matched keypoints
if params.localization_ransac.show_matched_keypoints
    figure(fig_cont);
    subplot(2,1,1);
    plotPoints(matched_query_keypoints,'g.');
    plotCircles(matched_query_keypoints,'y',params.localization_ransac.pixel_tolerance);
    title('Matched (green) keypoints with (yellow) confidence');
    
    subplot(2,1,2);
    plotPoints(matched_query_keypoints,'g.');
    title('Matched (green) keypoints');
end

% estimate pose from Cj to Ci
[R_CiCj,Ci_t_CiCj,p_new_matched_triang,Ci_corresponding_inlier_landmarks] = ...
    ransacLocalization(params,matched_query_keypoints,Ci_corresponding_landmarks,K);

localized = false;  % flag

if (isempty(R_CiCj) && isempty(Ci_t_CiCj))
    R_CiCj = eye(3,3);
    Ci_t_CiCj = zeros(3,1);
    fprintf(' !! No transformation found !!\n');
else
    fprintf('  >> Successfully localized\n');
    localized = true;
end

% construct new camera pose
T_CiCj = [R_CiCj   Ci_t_CiCj;
          zeros(1,3)       1];

T_CjCi = tform2invtform(T_CiCj);      


%% Candiate Keypoint tracker

T_WCj = T_WCi*T_CiCj;
kp_tracks_updated = update_kp_tracks(params, kp_tracks_prev,img_prev, img_new, query_keypoints, T_WCj);


%% Triangulate new landmarks & update landmarks and keypoint list

[ Cj_P_hom_new_inliers, p_candidates_j_inliers, kp_tracks_updated ] =...
    triangulate_new_landmarks(params, kp_tracks_updated, K , fig_kp_triangulate, fig_kp_tracks, T_WCj);

% Append used candidate keypoints to p_new_matched_triang
p_new_matched_triang = [p_new_matched_triang, p_candidates_j_inliers];

Cj_P_hom_inliers = [];
if localized %otherwise index error since Ci_corresponding_inlier_landmarks = []
    Cj_P_hom_inliers = T_CjCi*[Ci_corresponding_inlier_landmarks; ones(1,size(Ci_corresponding_inlier_landmarks,2))];
end

Cj_P_hom = [Cj_P_hom_inliers, Cj_P_hom_new_inliers];
Cj_new_landmarks = [];
if (size(Cj_P_hom,2)>0)
    Cj_new_landmarks = Cj_P_hom(1:3,:);
end

%% display statistics

fprintf('  Number of landmarks (total/new): %i / %i\n'...
         ,size(Cj_new_landmarks,2), size(Cj_P_hom_new_inliers,2)); 

end

