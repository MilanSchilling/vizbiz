function params = loadParameters()
% Returns collection of parameters used throughout the VO pipeline.
% 
% Input: none
%
% Output:
%  - params(struct) : parameter struct

% general parameters
params.ds = 0; % 0: KITTI, 1: Malaga, 2: Parking
params.auto_bootstrap = false;
params.perf.profiling = false;
params.compare_against_groundthruth = false;
params.run_continous = true;
params.show_map_and_cams = false;
params.through_gui = false;

% additional gui parameters
params.gui.show_all_features = true;
params.gui.show_inlier_features = true;

% bootstrap parameters
params.boot.show_boot_images = false;
params.boot.num_keypoints = 600;
params.boot.show_boot_keypoints = false;
params.boot.show_matches = false;
params.boot.landmarks_cutoff = 100;
params.boot.show_boot_landmarks = false;
params.boot.min_num_inlier_kps = 100;
params.boot.min_b2dratio = 0.1;

% initialization parameters
params.init.show_keypoints = true;
params.init.show_inlier_matches = true;
params.init.show_landmarks = false;
params.init.use_KITTI_precalculated_init = false;
params.init.show_matches = true;
params.init.use_BA = false;
params.init.landmarks_cutoff = 100;

% correspondence parameters
params.corr.harris_patch_size = 9; % 9 [pixels]
params.corr.harris_kappa = 0.08;
params.corr.nonmaximum_supression_radius = 8;
params.corr.num_keypoints = 400; % 200
params.corr.descriptor_radius = 9; % [pixels]
params.corr.match_lambda = 6; % 5

params.eightPoint_ransac.show_iterations = false;
params.eightPoint_ransac.p_success = 0.999999;
params.eightPoint_ransac.fract_inliers = 0.5;
params.eightPoint_ransac.max_error = 1.0; % [pixels]
params.eightPoint_ransac_cont.max_error = 1.0; % [pixels]

% continuous operation parameters
params.cont.run_on_first_x_images = 6; % 0: for all images
params.cont.show_current_image = true;
params.cont.show_keypoints = true;
params.cont.show_matches = true;
params.cont.show_inlier_matches = true;
params.cont.show_matches = true;
params.cont.landmarks_cutoff = 5;

params.localization_ransac.show_inlier_matches = true; % rename to  p3pransac
params.localization_ransac.use_p3p = true;
params.localization_ransac.num_iterations_pnp = 3000; % 2000 fix?
params.localization_ransac.num_iterations_DLT = 200;
params.localization_ransac.show_projected_keypoints = true;
params.localization_ransac.pixel_tolerance = 10; % 10 [pixels]
params.localization_ransac.show_iterations = false;

params.keypoint_tracker.show_matches = true;
params.keypoint_tracker.show_triangulated = true;
params.keypoint_tracker.bearing_low_thr = 10;
params.keypoint_tracker.min_nr_trackings = 2;

end
