function [cost, servos] = manipulator_cost_function(params, x)
R_prop = params.R_prop;

Xins0 = 0;
L1    = x(1);
L2    = x(2);

[THIS_FILES_ADDRESS, ~, ~] = fileparts(mfilename('fullpath'));
THIS_FILES_ADDRESS = THIS_FILES_ADDRESS + "/";
addpath(THIS_FILES_ADDRESS + "\mr")
servo_table = readtable(THIS_FILES_ADDRESS + "..\Required Data\servo_data.csv", 'VariableNamingRule', 'preserve');
% Structure -------------------------------------------------------------------
rho_fiber_carbon = 1780;
joint_1_struct_weight = (4/3) * 0.5 * pi * (0.075^3 - 0.073^3) * rho_fiber_carbon;
arm_cross_section_area = 0.02 * 0.05 - 0.016 * 0.046;
arm_weight_1 = arm_cross_section_area * L1 * rho_fiber_carbon;
arm_weight_2 = arm_cross_section_area * L2 * rho_fiber_carbon;
wrist_weight = 0.05 * 0.1 * 0.01 * rho_fiber_carbon;
pos_flange = [Xins0 + 2 * R_prop + R_prop; -0; 0];
M = [1 0 0 L1+L2
     0 1 0 0
     0 0 1 0
     0 0 0 1];
S_list = [0 0 0  1 0     1
          0 1 1  0 1     0
          1 0 0  0 0     0
          0 0 0  0 0     0
          0 0 0  0 0     0
          0 0 L1 0 L1+L2 0];

T = [eye(3) ([R_prop;0;0]);
    zeros(1,3) 1];
[theta_list_1, done_1] = IKinSpace(S_list, M, T, [0;-pi/4;pi/4;0;0;0], 10000, 1e-6);

T = [eye(3) (pos_flange - [Xins0;0;0]);
    zeros(1,3) 1];
[theta_list, done] = IKinSpace(S_list, M, T, [0;-pi/4;pi/4;0;0;0], 10000, 1e-6);

max_torque_j6 = 50;
servo_6 = get_the_most_economical_servo(servo_table, max_torque_j6);
servo_weight_6 = servo_6.("Weight (g)") * 0.001;
max_torque_j5 = 50;
servo_5 = get_the_most_economical_servo(servo_table, max_torque_j5);
servo_weight_5 = servo_5.("Weight (g)") * 0.001;
max_torque_j4 = 50;
servo_4 = get_the_most_economical_servo(servo_table, max_torque_j4);
servo_weight_4 = servo_4.("Weight (g)") * 0.001;
F_end_effector = [0;(1.1*0.2*9.81);0;0;0;(1.1+wrist_weight+servo_weight_4+servo_weight_5+servo_weight_6)*9.81];

pos_j3 = ([Xins0; 0; 0] + ...
          [cos(theta_list(1)) -sin(theta_list(1)) 0
           sin(theta_list(1)) cos(theta_list(1))  0
           0                  0                   1] * ...
          [cos(theta_list(2))  0 sin(theta_list(2))
           0                   1 0
          -sin(theta_list(2)) 0 cos(theta_list(2))] * [L1;0;0]);
pos_cj_arm_2 = pos_j3 + ...
                          [cos(theta_list(1)) -sin(theta_list(1)) 0
                           sin(theta_list(1)) cos(theta_list(1))  0
                           0                  0                   1] * ...
                          [cos(theta_list(2))  0 sin(theta_list(2))
                           0                   1 0
                          -sin(theta_list(2)) 0 cos(theta_list(2))] * ...
                          [cos(theta_list(3))  0 sin(theta_list(3))
                           0                   1 0
                          -sin(theta_list(3)) 0 cos(theta_list(3))] * [L2*0.5;0;0];
pos_flang_rel_to_j3 = pos_flange - pos_j3;
pos_cj_arm_2_rel_to_j3 = pos_cj_arm_2 - pos_j3;
max_torque_j3 = abs([0 1 0] * cross(pos_flang_rel_to_j3, F_end_effector(4:6))) + ... 
                abs(F_end_effector(2)) + ...
                abs([0 1 0] * cross(pos_cj_arm_2_rel_to_j3, [0;0;-arm_weight_2*9.81]));
[servo_3, s3_not_found] = get_the_most_economical_servo(servo_table, max_torque_j3 * 100/9.81);
servo_weight_3 = servo_3.("Weight (g)") * 0.001;

pos_cg_arm1_rel_to_j2 = [cos(theta_list(1)) -sin(theta_list(1)) 0
           sin(theta_list(1)) cos(theta_list(1))  0
           0                  0                   1] * ...
          [cos(theta_list(2))  0 sin(theta_list(2))
           0                   1 0
          -sin(theta_list(2)) 0 cos(theta_list(2))] * [L1*0.5;0;0];
pos_flang_rel_to_j2 = pos_flange - [Xins0; 0; 0];
pos_cj_arm_2_rel_to_j3 = pos_cj_arm_2 - [Xins0;0;0];
max_torque_j2 = abs([0 1 0] * cross(pos_flang_rel_to_j2, F_end_effector(4:6))) + ...
                abs(F_end_effector(2)) + ...
                abs([0 1 0] * cross(pos_cg_arm1_rel_to_j2, [0;0;arm_weight_1 * 9.81])) + ...
                abs([0 1 0] * cross(pos_cj_arm_2_rel_to_j3, [0;0;arm_weight_2 * 9.81])) + ...
                abs([0 1 0] * cross(pos_j3, [0;0;servo_weight_3 * 9.81]));
[servo_2, s2_not_found] = get_the_most_economical_servo(servo_table, max_torque_j2 * 100/9.81);
servo_weight_2 = servo_2.("Weight (g)") * 0.001;

f_end_effector_oblique = [1 0 0
                          0 cos(pi/6) -sin(pi/6)
                          0 sin(pi/6) cos(pi/6)] * F_end_effector(4:6);
max_torque_j1  = abs([0 0 1] * cross(pos_flang_rel_to_j2, f_end_effector_oblique)) + abs(F_end_effector(3));
[servo_1, s1_not_found] = get_the_most_economical_servo(servo_table, max_torque_j1 * 100/9.81);
servo_weight_1 = servo_1.("Weight (g)") * 0.001;

j1 = JacobianSpace(S_list, theta_list_1);
j2 = JacobianSpace(S_list, theta_list);

[vec1, eig1] = eig(j1*j1');
eig1 = extract_linear_eigs(eig1, vec1);
[vec2, eig2] = eig(j2*j2');
eig2 = extract_linear_eigs(eig2, vec2);
if ~done || ~done_1
    cost = nan;

elseif L1*cos(theta_list(2)) > pos_flange(1) || L1*cos(theta_list_1(2)) > R_prop
    cost = nan;

elseif sqrt(max(eig1)/min(abs(eig1))) > 3 ||  sqrt(max(eig2)/min(abs(eig2))) > 3
    cost = nan;

elseif s1_not_found || s2_not_found || s3_not_found
    cost = nan;

else
    cost = joint_1_struct_weight + ...
           arm_weight_1 + ...
           arm_weight_2 + ...
           wrist_weight + ...
           servo_weight_1 + ...
           servo_weight_2 + ...
           servo_weight_3 + ...
           servo_weight_4 + ...
           servo_weight_5 + ...
           servo_weight_6;
    % fprintf("R:%.6f,   X(%.6f, %.6f),    cost: %.6f\n", R_prop, x, cost)   
end

servos = {servo_1 servo_2 servo_3 servo_4, servo_5 servo_6};
end

function lin_eigs = extract_linear_eigs(eigs, eig_vecs)
lin_eigs = [];
for i = 1: length(eigs)
    [~, idx] = max(abs(eig_vecs(:, i)));
    if idx > 3
        lin_eigs = [lin_eigs; eigs(i,i)];
    end
end
end