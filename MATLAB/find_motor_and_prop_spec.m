function [motor, prop] = find_motor_and_prop_spec(motors_specs, prop_specs, test_data_struct)
motor = [];
motor_name  = test_data_struct.motor_type;
motor_kv    = extract_kv_from_motor_name(motor_name);
motor_name = split(motor_name, "KV");
motor_name = motor_name{1};
% motor_name = split(motor_name, "-");
% motor_name = motor_name(1);
% motor_name = split(motor_name, "S");
% motor_name = motor_name(1);
n_motors    = length(motors_specs.Name);

best_c_chars = 0;
for i=1: n_motors
    name = string(motors_specs.Name(i));
    % name = split(name, " ");
    % name = name(1);
    % name = split(name, "-");
    % name = name(1);
    kv   = motors_specs.Kv(i);
    if motor_kv == kv || isnan(motor_kv)
        c_chars = num_of_common_chars(motor_name, name);
        if c_chars > best_c_chars
            best_c_chars = c_chars;
            motor = motors_specs(i, :);
        end
    end
end


prop = [];
prop_name = test_data_struct.prop_type;
n_props = length(prop_specs.Name);
best_c_chars = 0;
for i=1: n_props
    name = string(prop_specs.Name{i});
    c_chars = num_of_common_chars(prop_name, name);
    if c_chars > best_c_chars
        best_c_chars = c_chars;
        prop = prop_specs(i, :);
    end
end
end

function motor_kv    = extract_kv_from_motor_name(motor_name)
    temp = split(motor_name, 'KV');
    motor_kv = str2double(string(temp{end}));
end

function c_chars = num_of_common_chars(motor_name, name)
c_chars = 0;
d_motor_name = double(motor_name);
d_name = double(char(name));
previous_idx = 1;
for i = 1: length(d_name)
    for j = previous_idx: length(d_motor_name)
        if d_name(i) == double(' ')
            break;
        end
        if d_motor_name(j) == double(' ')
            continue;
        end
        if d_name(i) == d_motor_name(j)
            if i == length(d_name) || ...
               j == length(d_motor_name) || ...
               d_name(i+1) == d_motor_name(j+1) || ...
               d_name(i+1) == double(' ') || ...
               d_motor_name(j+1) == double(' ')
                previous_idx = j + 1;
                c_chars = c_chars + 1;
                break;
            end
        end
    end
end
end