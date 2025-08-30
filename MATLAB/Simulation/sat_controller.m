function [x_dot_des] = sat_controller(e_x, x_ddot_max, x_dot_max_inpt, K)
    x_dot_des = K * e_x;
    x_dot_des = max(-x_dot_max_inpt, min(x_dot_max_inpt, x_dot_des));
    if abs(e_x) > K/2
        
        x_dot_des_max = sqrt(2 * x_ddot_max * abs(e_x));
        x_dot_des = max(-x_dot_des_max, min(x_dot_des_max, x_dot_des));
    end
end