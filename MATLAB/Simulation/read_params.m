clc;clear;close all
debug_mode = false;
% Trajectory --------------------------------------------------------------
data_table = readtable("Data.xlsx", 'VariableNamingRule', 'preserve');
data = table2array(data_table(:, 2:end));
params.pos_0 = data(1, 1:3) + [0 0 0.025];
params.v_cruise = data(2, 1);
params.v_monitoring = data(3, 1);
params.stack_r = data(4, 1);
params.stack_fence_r = data(5, 1);
params.stack_origin_offset = data(7, 1:3);
params.stack_1_pos = data(9, 1:3);
params.stack_2_pos = data(10, 1:3);
params.stack_safe_trajectory_offset = data(11, 1);
params.stack_safe_monitoring_r = data(12, 1);
params.manipulator_offset_from_cg = data(13, 1);
params.flange_offset = data(14, 1:3);
params.flange_1_pos = data(15, 1:3);
params.flange_2_pos = data(16, 1:3);
params.flange_1_psi = data(17, 1);
params.flange_2_psi = data(18, 1);
params.stack_safe_monitoring_offset = data(19, 1);
params.prebe_rest_pos = data(20, 1:3);

params.stack_3_pos = data(21, 1:3);
params.flange_3_pos = data(22, 1:3);
params.flange_3_psi = data(23, 1);
params.flange_3_2_delta_h = data(24, 1);

params.ground_alt = data(25, 1);
params.van_pos = [data(26, 1:2)'; -0.008];
params.asm2base = data(27, 1:3)';
params.base2center = data(28, 1:3)';
params.center2asm = -(params.asm2base + params.base2center) + [80*.5; 0; 0];
params.world2center = -params.base2center + [80*.5; 0; 0];
params.asm2tm_x  = data(29, 1:3)';
params.tm_x2center = (params.center2asm + params.asm2tm_x);
params.asm2tm_y = data(30, 1:3)';
params.tm_y2center = (params.center2asm + params.asm2tm_y);
params.tm_xrotf_deg = data(31, 1:3)';
params.tm_yrotf_deg = data(32, 1:3)';

% Manipulator Trajectory
params.t_arm_lift_up = 2;
params.t_arm_wait = 0.3;
params.t_arm_forward_time = 6;
params.t_flange_placement = params.t_arm_lift_up + params.t_arm_wait + params.t_arm_forward_time;
max_reaction_time_for_testo_350 = 40; %sec
params.t_inspection = max_reaction_time_for_testo_350 * 3 * 0; % part 3-2 ) Assumption 3
params.t_probe_backward = params.t_arm_forward_time;
params.t_probe_down     = params.t_arm_lift_up;
params.t_flight_backward = 10;

% Arm params
data_table = readtable("Data.xlsx", "Sheet", 2, 'VariableNamingRule', 'preserve');
for i = 1:height(data_table)
    params.(['manipulator_', data_table.Name{i}, '_m']) = table2array(data_table(i, 2)) * .001;
end

data_table = readtable("Data.xlsx", "Sheet", 3, 'VariableNamingRule', 'preserve');
for i = 1:height(data_table)
    params.(['manipulator_rest_pos_', data_table.Name{i}, '_deg']) = table2array(data_table(i, 2));
end

data_table = readtable("Data.xlsx", "Sheet", 4, 'VariableNamingRule', 'preserve');
for i = 1:height(data_table)
    params.(data_table.Name{i}) = table2array(data_table(i, 2));
end

% Waypoints
params.TAKEOFF_MODE = 0;
params.LAND_MODE = 1;
params.MIDPOINT_MODE = 2;
params.CRUISE_MODE = 3;
params.MONITORING_MODE = 4;

r_safe = (params.stack_fence_r + params.stack_safe_trajectory_offset);
params.waypoint(:, 1) = params.pos_0';
params.waypoint_mode(1) = params.TAKEOFF_MODE;


params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [103.27; -22.031; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [38.663; -22.031; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;

[x_tan, y_tan] = line2circle(params.stack_1_pos(1), params.stack_1_pos(2), ...
                             r_safe, ...
                             params.waypoint(1:2, 1), -1);
params.waypoint(:, size(params.waypoint, 2)+1) = [x_tan; y_tan; params.pos_0(3)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.stack_1_pos(1); 
                         params.stack_1_pos(2) + params.stack_r + params.stack_safe_monitoring_offset + params.manipulator_offset_from_cg; 
                         params.pos_0(3)];
params.waypoint_mode(size(params.waypoint, 2)) = params.MIDPOINT_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, size(params.waypoint, 2)) + [0;0.1;0];
params.waypoint_mode(size(params.waypoint, 2)) = params.MONITORING_MODE;
% -------------------------------------------------------------------------
params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [-18.186; -15.322; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
% params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [-26.069; 5.5; params.waypoint(3, 1)];
% params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.stack_3_pos(1); 
                         params.stack_3_pos(2) - (params.stack_r + params.stack_safe_monitoring_offset + params.manipulator_offset_from_cg); 
                         params.pos_0(3)+params.flange_3_2_delta_h];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, size(params.waypoint, 2)) - [0;0.05;0];
params.waypoint_mode(size(params.waypoint, 2)) = params.MIDPOINT_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, size(params.waypoint, 2)) - [0;0.05;0];
params.waypoint_mode(size(params.waypoint, 2)) = params.MONITORING_MODE;
% -------------------------------------------------------------------------
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, size(params.waypoint, 2)) + [13; 0; 0];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.stack_2_pos(1); 
                         params.stack_2_pos(2) - (params.stack_r + params.stack_safe_monitoring_offset + params.manipulator_offset_from_cg); 
                         params.pos_0(3)+params.flange_3_2_delta_h];
params.waypoint_mode(size(params.waypoint, 2)) = params.MIDPOINT_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, size(params.waypoint, 2)) - [0;0.05;0];
params.waypoint_mode(size(params.waypoint, 2)) = params.MONITORING_MODE;
% -------------------------------------------------------------------------
params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [0; 24.7; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [38.7; 32.7; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.world2center(1:2);0] + [110; 32.7; params.waypoint(3, 1)];
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, 1);
params.waypoint_mode(size(params.waypoint, 2)) = params.CRUISE_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = params.waypoint(:, 1);
params.waypoint_mode(size(params.waypoint, 2)) = params.MIDPOINT_MODE;
params.waypoint(:, size(params.waypoint, 2)+1) = [params.waypoint(1:2, 1); params.ground_alt];
params.waypoint_mode(size(params.waypoint, 2)) = params.LAND_MODE;

if params.waypoint_mode(1) == params.TAKEOFF_MODE
    params.pos_0(3) = params.ground_alt;
end

params.psi_0_deg = atan2d(params.waypoint(2, 2)-params.waypoint(2, 1), params.waypoint(1, 2)-params.waypoint(1, 1));

% Camera ------------------------------------------------------------------
params.thrd_person_cam_rel_pos = [7; -2; -3];
params.thrd_person_cam_rel_rot = [180 + atan2d(params.thrd_person_cam_rel_pos(2), params.thrd_person_cam_rel_pos(1));
                                  atan2d(params.thrd_person_cam_rel_pos(3), params.thrd_person_cam_rel_pos(1)); 
                                  0]; % psi; theta; phi

params.back_cam_rel_pos = [4; 0; -2];
params.back_cam_rel_rot = [0; 
                          atan2d(params.back_cam_rel_pos(3), params.back_cam_rel_pos(1)); 
                          0]; % psi; theta; phi

if debug_mode == true
plot(params.waypoint(1, :), params.waypoint(2, :), '-o')
hold on
theta = 0:0.01:2*pi;
plot(params.stack_1_pos(1), params.stack_1_pos(2), 'x')
plot(params.stack_1_pos(1)+r_safe*cos(theta), params.stack_1_pos(2)+r_safe * sin(theta))
plot(params.stack_2_pos(1), params.stack_2_pos(2), 'x')
plot(params.stack_2_pos(1)+r_safe*cos(theta), params.stack_2_pos(2)+r_safe * sin(theta))
axis equal
end

createBusFromStruct(params, "Params")