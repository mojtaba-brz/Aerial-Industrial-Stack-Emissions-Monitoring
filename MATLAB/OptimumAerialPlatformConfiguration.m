clc;clear;close all

[THIS_FILES_ADDRESS, ~, ~] = fileparts(mfilename('fullpath'));
THIS_FILES_ADDRESS = THIS_FILES_ADDRESS + "/";
%% Load Data ==============================================================
WeightEstimation

bat_specs = readtable(THIS_FILES_ADDRESS + "../Required Data/BatterySpecs.csv", 'VariableNamingRule', 'preserve');
esc_specs = readtable(THIS_FILES_ADDRESS + "../Required Data/ESCsSpecs.csv", 'VariableNamingRule', 'preserve');
motors_specs = readtable(THIS_FILES_ADDRESS + "../Required Data/MotorsSpecs.csv", 'VariableNamingRule', 'preserve');
prop_specs = readtable(THIS_FILES_ADDRESS + "../Required Data/PropsScpecs.csv", 'VariableNamingRule', 'preserve');
manipulator_opt_specs = readtable(THIS_FILES_ADDRESS + "ManipulatorOptimDesign.csv", 'VariableNamingRule', 'preserve');

test_data_structs = read_motor_prop_test_data();

monitoring_device_weight = 4.8; % Kg
probe_weight = 1.19;
%% Propulsion System Selection and Margin Weight Optimization =============
% Requirements ------------------------------------------------------------
hover_flight_time = 25 * 60; % sec at sea level
max_tilt_deg = 30;

% Max required thrust -----------------------------------------------------
safety_factor = 1.1;
trim_control_margin = 1.3;

% Cost function -----------------------------------------------------------
mean_prop_price  = mean(prop_specs.("Price ($)"));
mean_motor_price = mean(motors_specs.("Price ($)"));
mean_bat_price   = mean(bat_specs.("Price ($)"));
mean_esc_price   = mean(esc_specs.("Price ($)"));
testo_longest_dim = 0.438;

price_norm_factor  = mean_prop_price + mean_motor_price + mean_bat_price + mean_esc_price;
weight_norm_factor = (mean(prop_specs.("Weight (g)")) + mean(motors_specs.("Weight (g)")) + mean(bat_specs.("Weight (Kg)"))*1000 + mean(esc_specs.("Weight (g)")))*0.001;

cost_function = @(propulsion_system_weight, propulsion_system_price, ...
                  center_to_front_of_prop_disk_dist, hover_throttle) ...
                  ...
                propulsion_system_price/price_norm_factor + ...
                propulsion_system_weight/weight_norm_factor + ...
                center_to_front_of_prop_disk_dist/testo_longest_dim + ... % To consider the frame weight effect as function of its dimension 
                (abs(hover_throttle - 62.5) > 10) * abs(hover_throttle - 62.5) * 100; % To consider enough control margin 

% Optimization ------------------------------------------------------------
n_test_data = length(test_data_structs);

final_table = table();
final_table.W_to = {};
final_table.W_oe = {};
final_table.W_p = {};
final_table.W_pr = {};
final_table.NumOfMotors = {};
final_table.Motor = {};
final_table.Prop = {};
final_table.H_thr = {};
final_table.Bat = {};
final_table.ESC = {};
final_table.Price = {};
final_table.Cost = {};

for num_of_motors = 6 : 2 : 10
    frame_factor = 1.3;
    max_required_thrust_factor = 1/cosd(max_tilt_deg) * ...
                                 safety_factor * ...
                                 trim_control_margin * ...
                                 get_motor_failure_factor(num_of_motors, 0);
    for i= 1: n_test_data
        test_data_struct = test_data_structs(i);
        R_prop = get_prop_diameter(test_data_struct.prop_type)/2;
        manipulator_weight = manipulator_opt_specs.Weight(abs(manipulator_opt_specs.prop - R_prop) < 0.01);
        W_p = monitoring_device_weight + probe_weight + manipulator_weight;
        w_to_est = estimate_w_to(W_p, A, B);
        max_required_thrust = max_required_thrust_factor * w_to_est;
        single_motor_required_max_thrust = (max_required_thrust/num_of_motors);
        single_motor_required_hover_thrust = (w_to_est/num_of_motors);
        if test_data_struct.thrust(end) > single_motor_required_max_thrust
            single_motor_current_at_max_thrust = calculate_current_at_given_thrust(single_motor_required_max_thrust, test_data_struct);
            single_motor_hover_current = calculate_current_at_given_thrust(single_motor_required_hover_thrust * safety_factor, test_data_struct);

            esc = find_opt_esc(esc_specs, test_data_struct, single_motor_current_at_max_thrust);
            bat = find_opt_battery(bat_specs, test_data_struct, ...
                single_motor_current_at_max_thrust * num_of_motors, ...
                single_motor_hover_current * num_of_motors, ...
                hover_flight_time);
            [motor, prop] = find_motor_and_prop_spec(motors_specs, prop_specs, test_data_struct);

            total_weight_g = bat.("Weight (Kg)") * 1000 + num_of_motors * (esc.("Weight (g)") + motor.("Weight (g)") + prop.("Weight (g)"));
            total_price  = bat.("Price ($)") + num_of_motors * (esc.("Price ($)") + motor.("Price ($)") + prop.("Price ($)"));

            cost =  cost_function(total_weight_g * 0.001, total_price, ...
                    get_center_to_front_of_prop_disk_dist(num_of_motors, 0, test_data_struct), ...
                    calculate_throttle_at_given_thrust(single_motor_required_hover_thrust, test_data_struct));

            result_table = table;
            result_table.Motor = test_data_struct.motor_type;
            result_table.Prop = test_data_struct.prop_type;
            result_table.H_thr = calculate_throttle_at_given_thrust(single_motor_required_hover_thrust, test_data_struct);
            result_table.W_to = w_to_est;
            result_table.W_oe = w_to_est - W_p;
            result_table.W_p = W_p;
            result_table.Bat = sprintf("%s %iS%iP", bat.Name{1}, bat.("Cells (S)"), bat.("Cells (P)"));
            result_table.ESC = esc.Name{1};
            result_table.Price = total_price;
            result_table.W_pr = (bat.("Weight (Kg)") * 1000 + num_of_motors * (esc.("Weight (g)") + motor.("Weight (g)") + prop.("Weight (g)"))) * 0.001;
            result_table.NumOfMotors = num_of_motors;
            result_table.Cost = cost;
            final_table = [final_table; result_table(1, :)];
        end
    end
end
clc
[~, idx] = sort([final_table.Cost{:}]);
final_table = final_table(idx, :);
disp(final_table(1:10, :))

function w_to_est = estimate_w_to(W_p, A, B)
weight_equations = @(x) [x(1) - x(2) - W_p; log10(x(2)) - A * log10(x(1)) - B];

% Solve the system
x0 = [30 40];
[x, ~, ~] = fsolve(weight_equations, x0);

w_to_est = x(1);
% w_oe_est = x(2);
end