clc;clear;close all

test_data_structs = read_motor_prop_test_data();
n_test_data = length(test_data_structs);
try
    result_table = readtable("ManipulatorOptimDesign.csv");
    used_prop_radiuses = result_table.prop;
catch
    used_prop_radiuses = [];
    result_table = table();
    result_table.prop = {};
    result_table.L1 = {};
    result_table.L2 = {};
    result_table.Weight = {};
    result_table.Servo1 = {};
    result_table.Servo2 = {};
    result_table.Servo3 = {};
    result_table.Servo4 = {};
    result_table.Servo5 = {};
    result_table.Servo6 = {};
end

for i_test = 1:n_test_data
    params.R_prop        = get_prop_diameter(test_data_structs(i_test).prop_type)/2;
    if sum(abs(used_prop_radiuses - params.R_prop) < 0.01) || isnan(params.R_prop) || params.R_prop > 1
        continue
    else
        used_prop_radiuses = [used_prop_radiuses; params.R_prop];
    end
    tic
    L1 = 1.5*params.R_prop:1e-2:2.5*params.R_prop;
    L2 = L1;
    L1_total = L1;
    L2_total = L2;
    pre_length_step = 0;
    figure
    for exp = 2:3
        length_step = 10^-exp;
        L1 = sort(L1);
        L2 = sort(L2);
        if length(L1) > 1
            L1 = L1(1):length_step:L1(end);
        else
            L1 = L1(1)-pre_length_step:length_step:L1(end)+pre_length_step;
        end
        if length(L2) > 1
            L2 = L2(1):length_step:L2(end);
        else
            L2 = L2(1)-pre_length_step:length_step:L2(end)+pre_length_step;
        end
    
        [L1, L2] = meshgrid(L1, L2);
        Cost = zeros(length(L1), length(L2));
        Servos = repmat({{}}, [length(L1), length(L2)]);
        for i = 1:length(L1)
            for j = 1:length(L2)
                [Cost(i, j), Servos{i, j}] = manipulator_cost_function(params, [L1(i, j) L2(i, j)]);
            end
            clc
            disp("Prop: " + string(i_test) + "/" + string(n_test_data) + ...
                 ", Progress: " + string(i/length(L1) * 100) + ...
                 ", exp: " + string(exp))
        end
        contour(L1, L2, Cost, 300)
        colorbar
        grid on
        axis equal
        xlabel("L1 (m)")
        ylabel("L2 (m)")
        title(sprintf("R_p_r_o_p = %.2fin", params.R_prop/0.0254))
        hold on
        
        L1 = L1(Cost == min(min(Cost)));
        L2 = L2(Cost == min(min(Cost)));
        pre_length_step = length_step;
    end
    
    Servos = Servos(Cost == min(min(Cost)));
    Cost = Cost(Cost == min(min(Cost)));
    if mod(length(L1), 2)
        opt_idx = (length(L1) + 1)/2;
        L1_opt = L1(opt_idx);
        L2_opt = L2(opt_idx);
        Cost_opt = Cost(opt_idx);
        Servos = Servos{opt_idx};
    else
        opt_idx_left = (length(L1))/2;
        opt_idx_right = opt_idx_left + 1;
        L1_opt = mean(L1(opt_idx_left:opt_idx_right));
        L2_opt = mean(L2(opt_idx_left:opt_idx_right));
        Cost_opt = mean(Cost(opt_idx_left:opt_idx_right));
        Servos_left = Servos{opt_idx_left};
        Servos_right = Servos{opt_idx_right};
        if string(Servos_left{2}.Model{1}) ~= string(Servos_right{2}.Model{1})
            error ServoModelConflict
        else
            Servos = Servos_left;
        end
    end
    toc
    
    fprintf("R:%s,  X(%.6f, %.6f),  cost: %.6f\n", params.R_prop, L1_opt, L2_opt, Cost_opt)  
    temp_table = table();
    temp_table.prop = params.R_prop;
    temp_table.L1 =  L1_opt;
    temp_table.L2 =  L2_opt;
    temp_table.Weight = Cost_opt;
    tempf_table.Servo1 = Servos{1}.Model{1};
    temp_table.Servo2 = Servos{2}.Model{1};
    temp_table.Servo3 = Servos{3}.Model{1};
    temp_table.Servo4 = Servos{4}.Model{1};
    temp_table.Servo5 = Servos{5}.Model{1};
    temp_table.Servo6 = Servos{6}.Model{1};

    result_table = [result_table; temp_table(1,:)];
    writetable(result_table, "ManipulatorOptimDesign.csv")
end