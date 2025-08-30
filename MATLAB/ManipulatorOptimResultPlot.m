clc;clear;close 
opt_table = readtable("ManipulatorOptimDesign.csv");
props_radius = opt_table.prop;
[props_radius, idxs] = sort(props_radius);
L1 = opt_table.L1(idxs);
L2 = opt_table.L2(idxs);
W  = opt_table.Weight(idxs);

figure
subplot(311)
plot(props_radius, L1, "LineWidth", 2, "Marker","diamond", "LineStyle","none")
ylabel("L_1 [m]", "FontSize", 16, "FontName", "Times New Roman")
grid on
ylim([0 1])
yticks(0:0.2:1)
xticks(0:0.05:.6)
subplot(312)
plot(props_radius, L2, "LineWidth", 2, "Marker","diamond", "LineStyle","none")
ylabel("L_2 [m]", "FontSize", 16, "FontName", "Times New Roman")
grid on
ylim([0 1])
yticks(0:0.2:1)
xticks(0:0.05:.6)
subplot(313)
plot(props_radius, W, "LineWidth", 2, "Marker","diamond", "LineStyle","none")
ylabel("Manipulator Mass [Kg]", "FontSize", 16, "FontName", "Times New Roman")
xlabel("Propeller Radius [m]", "FontSize", 16, "FontName", "Times New Roman")
grid on
ylim([0 3])
yticks(0:0.5:3)
xticks(0:0.05:.6)

% sgtitle("Manipulator Optimization results", "FontSize", 16 + 2, "FontName", "Times New Roman")