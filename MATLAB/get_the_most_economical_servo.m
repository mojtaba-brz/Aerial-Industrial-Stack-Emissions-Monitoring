function [servo, not_found] = get_the_most_economical_servo(servo_table, max_torque_req_kg_cm)
capable_servos =  servo_table(servo_table.("Torque (kg.cm)") > max_torque_req_kg_cm, :);
weight_norm_coef = mean(capable_servos.("Weight (g)"));
price_norm_coef  = mean(capable_servos.("Price ($)"));
[~, i] = sort(capable_servos.("Weight (g)") * weight_norm_coef * 3 + ...
              capable_servos.("Price ($)") * price_norm_coef);
try
    servo = capable_servos(i(1), :);
    not_found = false;
catch
    servo = servo_table(1, :);
    not_found = true;
end

end