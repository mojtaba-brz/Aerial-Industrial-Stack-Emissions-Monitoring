function esc = find_opt_esc(esc_specs, test_data_struct, current_at_max_thrust)
voltages = esc_specs.("Max Voltage (Cells)") * 4.2;
max_currents  = esc_specs.("Max Current (A)");
peak_currents = esc_specs.("Peak Current (A)");

voltage_based_idx = mean(test_data_struct.vol) <= voltages;
current_based_idx = current_at_max_thrust <= max_currents & max(test_data_struct.current) <= peak_currents;
idx = voltage_based_idx & current_based_idx;
escs = esc_specs(idx, :);

weights = escs.("Weight (g)");
weights_norm = weights/mean(weights);
prices = escs.("Price ($)");
prices_norm = prices/mean(prices);

cost = 1.5 * weights_norm + prices_norm;

[~, sorted_idxs] = sort(cost);

esc = escs(sorted_idxs(1), :);
end