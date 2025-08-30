function throttle = calculate_throttle_at_given_thrust(thrust, test_data_struct)
throttle = interp1(test_data_struct.thrust, test_data_struct.thr, thrust, "linear", "extrap");
end