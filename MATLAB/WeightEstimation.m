[THIS_FILES_ADDRESS, ~, ~] = fileparts(mfilename('fullpath')); 
THIS_FILES_ADDRESS = THIS_FILES_ADDRESS + "/";
%% Load Data ==============================================================
uav_specs = readtable(THIS_FILES_ADDRESS + "../Required Data/MultirotorSpecs.csv", 'VariableNamingRule', 'preserve');
W_to = uav_specs.("Max Takeoff Weight (Kg)")(~isnan(uav_specs.("Empty Weight (inc.battery; Kg)")));
W_oe = uav_specs.("Empty Weight (inc.battery; Kg)")(~isnan(uav_specs.("Empty Weight (inc.battery; Kg)")));

%% Regression =============================================================
% If we assumed that:
% log10(W_OE) = A * log10(W_to) + B 
log_W_to = log10(W_to);
log_W_oe = log10(W_oe);

M = [log_W_to, ones(size(log_W_to))];
temp = (M'*M)^-1*M'*log_W_oe;
A = temp(1);
B = temp(2);
y_hat_log = A * log_W_to + B;
estiamted_W_oe = 10.^(y_hat_log);

%% Fit Quality ============================================================
n = numel(log_W_oe);
p = 1; % number of fitted predictors
residuals_log = log_W_oe - y_hat_log;
ss_res = sum(residuals_log.^2);
ss_tot = sum((log_W_oe - mean(log_W_oe)).^2);
R2_log = 1 - ss_res / ss_tot;
R2_adj_log = 1 - (1 - R2_log) * (n - 1) / (n - p - 1);
RMSE_log = sqrt(mean(residuals_log.^2));

FitQuality = table( ...
    ["Number of data points"; ...
     "W_TO range [kg]"; ...
     "R^2 in log space"; ...
     "Adjusted R^2 in log space"; ...
     "RMSE of log10(W_OE)"], ...
    [string(n); ...
     sprintf("%0.1f--%0.1f", min(W_to), max(W_to)); ...
     sprintf("%0.3f", R2_log); ...
     sprintf("%0.3f", R2_adj_log); ...
     sprintf("%0.3f", RMSE_log)], ...
    'VariableNames', {'Metric', 'Value'});

disp(FitQuality)


% Plot (Data and Approximation) =======================================
loglog(W_to, W_oe, '.', "MarkerSize", 20)
hold on
loglog(W_to, estiamted_W_oe, "LineWidth", 2)
% text(7, 12, sprintf('$$ W_{OE} = 10^{(%0.4f~log_{10}(W_{TO})~%+0.4f)} $$', A, B), 'Interpreter', 'latex', 'FontSize', 20, "FontWeight", "bold", "Rotation", 36);
axis equal
grid on
xlabel("Max Takeoff Weight [kg]", "FontSize", 20, "FontName", "Times New Roman")
ylabel("Operational Empty Weight [kg]", "FontSize", 20, "FontName", "Times New Roman")
legend("Data", "Approximation", "Location", "best", "FontSize", 20, "FontName", "Times New Roman")
