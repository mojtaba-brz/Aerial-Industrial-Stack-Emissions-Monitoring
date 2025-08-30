function current_at_max_thrust = calculate_current_at_given_thrust(required_max_thrust, test_data_struct)
current_at_max_thrust = interp1(test_data_struct.thrust, test_data_struct.current, required_max_thrust, "linear", "extrap");
end