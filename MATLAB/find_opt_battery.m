function bat = find_opt_battery(bat_specs, test_data_struct, current_at_max_thrust, hover_current, hover_flight_time)
voltages_cells = bat_specs.("Cells (S)");
min_voltages = bat_specs.("Min Voltage per cell") .* bat_specs.("Cells (S)");
continuous_c_rates  = bat_specs.("Continuous C-Rate");
caps = bat_specs.("Cap (mAh)") * 0.001 * 3600; % A.sec

min_required_cap = hover_current * hover_flight_time;
num_of_p_bats    = ceil(min_required_cap ./ caps);
required_voltage_cells = ceil(mean(test_data_struct.vol)/4.2);
num_of_s_bats = ceil(required_voltage_cells ./ voltages_cells);

voltage_based_idx = required_voltage_cells == (voltages_cells .* num_of_s_bats);
current_based_idx = current_at_max_thrust <= (caps .* num_of_p_bats - min_required_cap) .* continuous_c_rates;
idx = voltage_based_idx & current_based_idx;
bats = bat_specs(idx, :);

weights = bats.("Weight (Kg)");
weights_norm = weights/mean(weights);
prices = bats.("Price ($)");
prices_norm = prices/mean(prices);

cost = (1.5 * weights_norm + prices_norm) .* (num_of_p_bats(idx) .* num_of_s_bats(idx));

[~, sorted_idxs] = sort(cost);

bat = bats(sorted_idxs(1), :);
num_of_p_bats = num_of_p_bats(idx);
num_of_s_bats = num_of_s_bats(idx);
bat.("Cells (S)") = bat.("Cells (S)") * num_of_s_bats(sorted_idxs(1));
bat.("Cells (P)") = bat.("Cells (P)") * num_of_p_bats(sorted_idxs(1));
bat.("Price ($)") = bat.("Price ($)") * (num_of_s_bats(sorted_idxs(1)) * num_of_p_bats(sorted_idxs(1)));
bat.("Weight (Kg)") = bat.("Weight (Kg)") * (num_of_s_bats(sorted_idxs(1)) * num_of_p_bats(sorted_idxs(1)));
end