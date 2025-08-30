function dist = get_center_to_front_of_prop_disk_dist(num_of_motors, is_coaxial, test_data_structor_R_prop)
    if isnumeric(test_data_structor_R_prop)
        d = 2 * test_data_structor_R_prop;
    else
        d = get_prop_diameter(test_data_structor_R_prop.prop_type);
    end
    
    if is_coaxial
        if (mod(num_of_motors, 2) ~= 0)
            dist = inf;
            return
        end
        theta = 4 * pi / (num_of_motors); % angle between motors
    else
        theta = 2 * pi / (num_of_motors); % angle between motors
    end

    L = sqrt((1.4 * d)^2/(2 - 2 * cos(theta)));

    dist = (L) * cos(theta/2) + d/2;
end