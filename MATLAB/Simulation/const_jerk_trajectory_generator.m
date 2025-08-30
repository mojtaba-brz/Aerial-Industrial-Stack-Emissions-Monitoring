function [pos, vel, acc, waypoint_idx, jerk, in_brake] = const_jerk_trajectory_generator(t, last_t, ...
    last_pos, last_vel, last_acc, last_waypoint_idx, params, in_brake)
    % Extract parameters
    waypoints = params.waypoint;        % 3 x n vector for n waypoints
    waypoint_vel = params.waypoint_vel; % 3 x n vector for n waypoints (only last must be zero)
    max_vel = params.v_cruise;
    g = 9.8066;
    max_acc = 0.5 * g;
    max_jerk = 0.5 * g;

    % Initialize outputs
    pos = last_pos;
    vel = last_vel;
    acc = last_acc;
    jerk = [0;0;0];
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
        in_brake = false;
        return;
    end
    
    target = waypoints(:, waypoint_idx);
    target_vel = waypoint_vel(:, waypoint_idx);
    
    diff = target - last_pos;
    dist = norm(diff);
    dir = sign(diff);
    
    if dist < 0.001
        waypoint_idx = waypoint_idx + 1;
        pos = target;
        vel = last_vel;
        acc = last_acc;
        in_brake = false;
        return;
    end
    
    if in_brake
        jerk = -max_jerk * dir;
        for i=1:3
            jerk_end = -jerk(i);
            t_end = -last_acc(i)/jerk_end;
            if isnan(t_end) || t_end < 0
                continue
            end
            v_end  = last_vel(i) + last_acc(i)*t_end + jerk_end * t_end^2/2;
            p_end = -jerk(i) * t_end^3/6 + last_acc(i)*t_end^2/2 + last_vel(i)*t_end + last_pos(i);
            fprintf("brake(%0.3f, %0.3f)\n", (v_end - target_vel(i)), p_end)
            if -dir(i) * (p_end - target(i))/abs(target(i)) < 1 && (v_end - target_vel(i))<1e-2
                jerk(i) = -jerk(i);
                in_brake = false;
            end
        end
    else
        jerk = max_jerk * dir;
        for i=1:3
            j_t = -jerk(i);
            a_t = -sign(last_acc(i)) * sqrt(j_t * (target_vel(i) - last_vel(i)) + (0^2 + last_acc(i)^2)/2);
            if imag(a_t) ~=0 || a_t == 0
                continue
            end
            v_t = last_vel(i) + (a_t^2 - last_acc(i)^2)/(-2*jerk(i));
            t_t = (a_t - last_acc(i))/(j_t);
            p_t = j_t * t_t^3/6 + last_acc(i)*t_t^2/2 + last_vel(i)*t_t + last_pos(i);
            t_end = -a_t/jerk(i);
            if t_t < 0 || t_end < 0
                continue
            end
            p_end = jerk(i) * t_end^3/6 + a_t*t_end^2/2 + v_t*t_end + p_t;
            fprintf("acc(%0.3f)\n", p_end)
            if -dir(i) * (p_end - target(i))/abs(target(i)) < 0.01
                jerk(i) = -jerk(i);
                in_brake = true;
            end
        end
    end
    
    acc = last_acc + jerk*dt;
    acc = max(-max_acc, min(max_acc, acc));
    % jerk = (acc - last_acc)/dt;
    vel = last_vel + acc*dt + jerk*dt^2/2;
    vel = max(-max_vel, min(max_vel, vel));
    % acc = (vel - last_vel)/dt;
    pos = last_pos + vel*dt + acc*dt^2/2 + jerk*dt^3/6;
end