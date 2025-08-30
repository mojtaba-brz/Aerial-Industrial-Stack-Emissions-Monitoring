function test_data_structs = read_motor_prop_test_data()

[THIS_FILES_ADDRESS, ~, ~] = fileparts(mfilename('fullpath'));
THIS_FILES_ADDRESS = THIS_FILES_ADDRESS + "/";
DATA_DIR = THIS_FILES_ADDRESS + "../Required Data/";
data_files = dir(DATA_DIR);
n = length(data_files);


empty_test_data_struct.name = "";
empty_test_data_struct.motor_type = "";
empty_test_data_struct.prop_type = "";
empty_test_data_struct.thr  = [];
empty_test_data_struct.vol  = [];
empty_test_data_struct.thrust = [];
empty_test_data_struct.torque = [];
empty_test_data_struct.current = [];
empty_test_data_struct.rpm     = [];
empty_test_data_struct.power   = [];

test_data_structs = [];
for i = 1: n
    file_name = data_files(i).name;
    if contains(file_name, "TMotorTestData")
        test_data = readtable(DATA_DIR + file_name, 'VariableNamingRule', 'preserve');
        try
            motor_name = test_data.Type;
            prop_name  = test_data.Propeller;
        catch
            try
                motor_name = test_data.("Item No.");
                prop_name  = test_data.("Prop");
            catch
                motor_name = test_data.("Item No");
                prop_name  = test_data.("Prop");
            end
        end

        try
            thrust  = test_data.("Thrust (g)") * 0.001;
        catch
            thrust  = test_data.("Thrust (G)") * 0.001;
        end

        try
            torque  = test_data.("Torque (N*m)");
        catch
            try
                torque  = test_data.("Torqu (N*m)");
            catch
                torque  = -1 * ones(size(motor_name));
            end
        end

        try
            power   = test_data.("Power (W)");
        catch
            power   = test_data.("Inputpower (W)");
        end


        vol     = parse_voltage_column(test_data.("Voltage (V)"));
        thr     = parse_thr_column(test_data.("Throttle"));
        current = test_data.("Current (A)");
        rpm     = test_data.("RPM");

        n_rows = length(motor_name);
        test_data_struct = empty_test_data_struct;
        for row = 1: n_rows
            if test_data_struct.name == ""
                test_data_struct.name = motor_name{row} + "  ,  " + prop_name{row};
                test_data_struct.motor_type = motor_name{row};
                test_data_struct.prop_type = prop_name{row};
            end
            test_data_struct.thr = [test_data_struct.thr; thr(row)];
            test_data_struct.thrust = [test_data_struct.thrust; thrust(row)];
            test_data_struct.torque = [test_data_struct.torque; torque(row)];
            test_data_struct.power = [test_data_struct.power; power(row)];
            test_data_struct.rpm = [test_data_struct.rpm; rpm(row)];
            test_data_struct.current = [test_data_struct.current; current(row)];
            test_data_struct.vol = [test_data_struct.vol; vol(row)];

            if row < n_rows && (string(motor_name{row}) ~= string(motor_name{row + 1})  || ...
                                string(prop_name{row}) ~= string(prop_name{row + 1})    || ...
                                abs(vol(row) - vol(row + 1)) > 4.2)
                test_data_structs = [test_data_structs; test_data_struct];
                test_data_struct = empty_test_data_struct;
            end
        end

    end
end
end

function vol = parse_voltage_column(vol_column)
vol = [];
if isnumeric(vol_column)
    vol = vol_column;
else
    for i = 1:length(vol_column)
        temp = vol_column{i};
        temp = split(temp, '(');
        temp = temp(end);
        temp = split(temp, ')');
        temp = temp{1};
        vol = [vol; str2double(temp(1:end-1))];
    end
end
end

function thr = parse_thr_column(thr_column)
thr = [];
if isnumeric(thr_column)
    thr = thr_column;
else
    for i = 1:length(thr_column)
        temp = thr_column{i};
        thr = [thr; str2double(temp(1:end-1))];
    end
end
end
