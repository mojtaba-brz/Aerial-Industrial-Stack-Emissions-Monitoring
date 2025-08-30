function [pos, vel, acc, waypoint_idx] = second_order_trajectory_generator(t, last_t, ...
    last_pos, last_vel, last_acc, last_waypoint_idx, params)
    % Extract parameters
    waypoints = params.waypoint;        % 3 x n vector for n waypoints
    waypoint_vel = params.waypoint_vel; % 3 x n vector for n waypoints (only last must be zero)
    max_vel = params.v_cruise;
    g = 9.8066;
    max_acc = 0.5 * g;

    % Initialize outputs
    pos = last_pos;
    vel = last_vel;
    acc = last_acc;
    waypoint_idx = last_waypoint_idx;
    
    dt = t - last_t;
    if dt <= 0
        return;
    end
    
    num_waypoints = size(waypoints, 2);
    if waypoint_idx > num_waypoints
        pos = waypoints(:, end);
        vel = [0; 0; 0];
        acc = [0; 0; 0];
        return;
    end
    
    target = waypoints(:, waypoint_idx);
    target_vel = waypoint_vel(:, waypoint_idx);
    
    diff = target - last_pos;
    dist = norm(diff);
    dir = sign(diff);
    target_vel = (dir == sign(target_vel)) .* target_vel;
    
    if (dist < 0.2 && waypoint_idx < num_waypoints) || dist < 0.01
        waypoint_idx = waypoint_idx + 1;
        pos = target;
        vel = last_vel;
        acc = last_acc;
        return;
    end
    
    w = 3;
    zeta = 1.6;
    K_v = 2*zeta*w;
    K_p = w^2/K_v;
    des_vel = sat_controller(diff, max_acc, max_vel, K_p);
    target_vel = (target_vel'*direction(des_vel)) * direction(des_vel);
    des_vel = des_vel + target_vel;
    if norm(des_vel) > max_vel
        des_vel = des_vel/norm(des_vel) * max_vel;
    end
    acc = sat_controller(des_vel - last_vel, inf, max_acc, K_v);

    vel = last_vel + acc*dt;
    vel = max(-max_vel, min(max_vel, vel));
    pos = last_pos + vel*dt + acc*dt^2/2;
end