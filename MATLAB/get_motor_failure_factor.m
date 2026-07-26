function factor = get_motor_failure_factor(num_of_motors, is_coaxial, motor_positions, user_yaw_factor)
%GET_MOTOR_FAILURE_FACTOR Maximum thrust factor after a single motor loss.
%
%   factor = GET_MOTOR_FAILURE_FACTOR(N, IS_COAXIAL) uses the original
%   equally spaced motor geometry and alternating yaw coefficients.
%
%   factor = GET_MOTOR_FAILURE_FACTOR(N, IS_COAXIAL, MOTOR_POSITIONS)
%   uses the supplied N-by-2 matrix of [x, y] motor positions.
%
%   factor = GET_MOTOR_FAILURE_FACTOR(N, IS_COAXIAL, MOTOR_POSITIONS,
%   USER_YAW_FACTOR) also uses the supplied N-element yaw-coefficient
%   vector. Empty optional inputs retain the original defaults.

r_x = zeros(num_of_motors, 1);
r_y = zeros(num_of_motors, 1);
yaw_factor = zeros(num_of_motors, 1);
thr_factor = zeros(num_of_motors, 1);
L = 1;
coaxial_thrust_factor = 1;

use_user_positions = nargin >= 3 && ~isempty(motor_positions);
use_user_yaw_factor = nargin >= 4 && ~isempty(user_yaw_factor);

if use_user_positions
    if ~isequal(size(motor_positions), [num_of_motors, 2])
        error('motor_positions must be a num_of_motors-by-2 matrix of [x, y] coordinates.')
    end
    r_x = motor_positions(:, 1);
    r_y = motor_positions(:, 2);
end

if use_user_yaw_factor
    if numel(user_yaw_factor) ~= num_of_motors
        error('user_yaw_factor must contain one coefficient per motor.')
    end
    yaw_factor = user_yaw_factor(:);
end

if is_coaxial
    if (mod(num_of_motors, 2) ~= 0)
        factor = inf;
        return
    end
    theta = 4 * pi / (num_of_motors); % angle between motors
    coaxial_thrust_factor = 1.7 * 0.5;
else
    theta = 2 * pi / (num_of_motors); % angle between motors
end


for i = 1 : num_of_motors
    if ~use_user_positions
        psi_motor_installation = (1.5 - i) * theta;
        r_x(i) = L * cos(psi_motor_installation);
        r_y(i) = L * sin(psi_motor_installation);
    end
    if ~use_user_yaw_factor
        yaw_factor(i) = (-1)^(i+1)/num_of_motors * 2;
    end
    thr_factor(i) = 1/num_of_motors;
end

% Roll, Pitch, Yaw, Throttle
mixer_matrix = [-r_y'
                r_x'
                yaw_factor'
                thr_factor'*coaxial_thrust_factor];

hover_typical_cmds = [0;0;0;0.5];
W = eye(4);

% QuadProg params----------------------------------------------------------
H = mixer_matrix' * W * mixer_matrix;
f = (- hover_typical_cmds' * W * mixer_matrix)';
A = [eye(num_of_motors); -eye(num_of_motors)];
b = [eye(num_of_motors, 1); -0.2*eye(num_of_motors, 1)];
Aeq = zeros(1, num_of_motors);
beq = 0;

max_x = 0;
for failed_motor_idx = 1:num_of_motors
    Aeq(failed_motor_idx) = 1;
    x = quadprog(H, f, [], [], Aeq, beq);
    Aeq(failed_motor_idx) = 0;
    if all(abs(mixer_matrix*x - hover_typical_cmds) < 1e-4)
        max_x = max(max(x), max_x);
    else
        max_x = 0;
        break;
    end
end
if max_x == 0
    factor = inf;
else
    factor = max_x / hover_typical_cmds(end);
end
end
