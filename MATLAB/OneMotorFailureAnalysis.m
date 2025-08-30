clc;clear;close all

num_of_motors = 5;
L = 1;
m = 1;
I = eye(3);
A = [I zeros(3,1); zeros(1, 3), m]^-1;
% X config ==================================================================
r_x = zeros(num_of_motors, 1);
r_y = zeros(num_of_motors, 1);
yaw_factor = zeros(num_of_motors, 1);
thr_factor = zeros(num_of_motors, 1);

theta = 2 * pi / (num_of_motors); % angle between motors

for i = 1 : num_of_motors
    psi_motor_installation = (1.5 - i) * theta;
    r_x(i) = L * cos(psi_motor_installation);
    r_y(i) = L * sin(psi_motor_installation);
    yaw_factor(i) = (-1)^(i+1)/num_of_motors * 2;
    thr_factor(i) = 1/num_of_motors;
end

% Roll, Pitch, Yaw, Throttle
mixer_matrix = [-r_y'
                r_x'
                yaw_factor'
                thr_factor'];

hover_typical_cmds = [0;0;0;0.5];
for failed_motor_idx = 1:num_of_motors
    temp_mixer = mixer_matrix;
    temp_mixer = temp_mixer(:, 1:num_of_motors ~= failed_motor_idx);

    pinv(temp_mixer) * hover_typical_cmds;
    B = temp_mixer;
    rank(ctrb(A, B))
end


% Co-axial X config =======================================================
r_x = zeros(num_of_motors, 1);
r_y = zeros(num_of_motors, 1);
yaw_factor = zeros(num_of_motors, 1);
thr_factor = zeros(num_of_motors, 1);

theta = 4 * pi / (num_of_motors); % angle between motors

for i = 1 : num_of_motors
    psi_motor_installation = (1.5 - i) * theta;
    r_x(i) = L * cos(psi_motor_installation);
    r_y(i) = L * sin(psi_motor_installation);
    if i <= num_of_motors/2
        yaw_factor(i) = (-1)^(i+1)/num_of_motors * 2;
    else
        yaw_factor(i) = (-1)^(i)/num_of_motors * 2;
    end
    yaw_factor(i) = (-1)^(i+1)/num_of_motors * 2;
    thr_factor(i) = 1/num_of_motors;
end

% Roll, Pitch, Yaw, Throttle
mixer_matrix = [-r_y'
                r_x'
                yaw_factor'
                thr_factor'];

hover_typical_cmds = [0;0;0;0.6];
for failed_motor_idx = 1:num_of_motors
    temp_mixer = mixer_matrix;
    temp_mixer = temp_mixer(:, 1:num_of_motors ~= failed_motor_idx);

    temp_mixer * pinv(temp_mixer) * hover_typical_cmds;
    % B = temp_mixer;
    % rank(ctrb(A, B))
end

