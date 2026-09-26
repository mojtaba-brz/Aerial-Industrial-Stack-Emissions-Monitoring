%% CAD-based single-motor-loss analysis
% Reads the motor centers from the SolidWorks XML export, evaluates the
% existing get_motor_failure_factor algorithm, writes a text report, and
% draws the motor-allocation geometry over the CAD top view.

clear
close all
clc

script_dir = fileparts(mfilename('fullpath'));
simulation_dir = fullfile(script_dir, 'Simulation');
cad_dir = fullfile(simulation_dir, 'SolidworksOutput');
xml_file = fullfile(cad_dir, 'AerialPlatformTotal.xml');

supply_repo_dir = fileparts(script_dir);
article_dir = fullfile(fileparts(supply_repo_dir), 'UAV-Design-Article');
figure_file = fullfile(article_dir, 'Pictures', ...
    'Figure_MotorTopView.png');
report_file = fullfile(script_dir, 'MotorLossAnalysisReport.txt');

num_of_motors = 8;
is_coaxial = false;
takeoff_mass = 21.13;             % kg
gravity = 9.81;                   % m/s^2
propeller_radius = 22*0.0254/2;   % m
available_thrust = 6.680*gravity; % N, MN505S with P22x6.6 test data

%% Read CAD motor centers and form the original mixer inputs
cad_motor_xyz = readMotorCenters(xml_file, num_of_motors);
cad_centre_xz = mean(cad_motor_xyz(:, [1, 3]), 1);

% Body coordinates used in the article: x_b points forward (toward the
% manipulator) and y_b points laterally. In the CAD export, forward is -z
% and lateral is +x.
motor_positions = [ ...
    cad_centre_xz(2)-cad_motor_xyz(:, 3), ...
    cad_motor_xyz(:, 1)-cad_centre_xz(1)];

yaw_factor = (-1).^(0:num_of_motors-1)'/num_of_motors*2;

% The first output is still the maximum thrust factor returned by the
% original quadratic-program allocation.
evalc('failure_factor = get_motor_failure_factor(num_of_motors, is_coaxial, motor_positions, yaw_factor);');

% Retain the individual cases for the report and verify their maximum
% against the value returned by get_motor_failure_factor.
failure_factors = evaluateIndividualFailures( ...
    motor_positions, yaw_factor);
assert(abs(max(failure_factors)-failure_factor) < 1e-9)

hover_thrust = takeoff_mass*gravity/num_of_motors;
moment_arms = vecnorm(motor_positions, 2, 2);
initial_moments = hover_thrust*moment_arms;
required_thrust = hover_thrust*failure_factor;
thrust_reserve = available_thrust-required_thrust;

%% Write the analysis report
report_id = fopen(report_file, 'w');
if report_id < 0
    error('Could not open the motor-loss report for writing.')
end
report_cleanup = onCleanup(@() fclose(report_id));

writeLine(report_id, 'CAD-based single-motor-loss analysis');
writeLine(report_id, '====================================');
writeLine(report_id, ...
    'The thrust factor is the largest motor command divided by the hover command.');
writeLine(report_id, 'A larger factor therefore represents a worse case.');
writeLine(report_id, '');
writeLine(report_id, ...
    'Motor    x_b (m)    y_b (m)    r_i (m)    T_h r_i (N m)    factor');

for motor_idx = 1:num_of_motors
    writeLine(report_id, sprintf( ...
        'M%-2d     %+7.3f    %+7.3f      %.3f          %5.1f        %.4f', ...
        motor_idx, motor_positions(motor_idx, 1), ...
        motor_positions(motor_idx, 2), moment_arms(motor_idx), ...
        initial_moments(motor_idx), failure_factors(motor_idx)));
end

writeLine(report_id, '');
writeLine(report_id, sprintf( ...
    'Maximum single-motor-loss factor: %.4f', failure_factor));
writeLine(report_id, sprintf( ...
    'Governing failed motor(s):        %s', ...
    strjoin("M"+find(abs(failure_factors-failure_factor) < 5e-4)', ', ')));
writeLine(report_id, sprintf( ...
    'Required thrust per motor:        %.1f N (%.2f kgf)', ...
    required_thrust, required_thrust/gravity));
writeLine(report_id, sprintf( ...
    'Available maximum thrust:         %.1f N (%.2f kgf)', ...
    available_thrust, available_thrust/gravity));
writeLine(report_id, sprintf( ...
    'Available thrust reserve:         %.1f N (%.2f kgf)', ...
    thrust_reserve, thrust_reserve/gravity));

fprintf('Motor-loss report written to:\n  %s\n', report_file)
fprintf('Maximum single-motor-loss factor: %.4f\n', failure_factor)
fprintf('Required/available thrust: %.1f/%.1f N per motor\n', ...
    required_thrust, available_thrust)

%% Draw the allocation geometry over the CAD top view
fig = figure('Color', 'white', 'Position', [80, 80, 1500, 820]);
ax = axes(fig);
hold(ax, 'on')

plotCadAssemblyTopView(ax, xml_file, cad_dir)
hold(ax, 'on')

% The top-view camera is placed on the +y side of the CAD model. A positive
% y offset therefore places the annotations in front of the CAD surfaces.
overlay_height = max(cad_motor_xyz(:, 2))+0.12;
theta = linspace(0, 2*pi, 240);
rotation_colours = [0.10, 0.45, 0.76; 0.88, 0.32, 0.18];

for motor_idx = 1:num_of_motors
    colour_idx = 1+mod(motor_idx, 2);
    plot3(ax, ...
        cad_motor_xyz(motor_idx, 1)+propeller_radius*cos(theta), ...
        overlay_height*ones(size(theta)), ...
        cad_motor_xyz(motor_idx, 3)+propeller_radius*sin(theta), ...
        '-', 'Color', rotation_colours(colour_idx, :), 'LineWidth', 2.2)
    plot3(ax, cad_motor_xyz(motor_idx, 1), overlay_height, ...
        cad_motor_xyz(motor_idx, 3), 'o', ...
        'MarkerSize', 7, 'MarkerFaceColor', rotation_colours(colour_idx, :), ...
        'MarkerEdgeColor', 'white', 'LineWidth', 1.0)
    radial_offset = [cad_motor_xyz(motor_idx, 1)-cad_centre_xz(1), ...
        cad_motor_xyz(motor_idx, 3)-cad_centre_xz(2)];
    radial_offset = 0.12*radial_offset/norm(radial_offset);
    text(ax, cad_motor_xyz(motor_idx, 1)+radial_offset(1), ...
        overlay_height-0.01, ...
        cad_motor_xyz(motor_idx, 3)+radial_offset(2), ...
        sprintf('M%d\n(%+.3f, %+.3f)', motor_idx, ...
        motor_positions(motor_idx, 1), motor_positions(motor_idx, 2)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
        'FontWeight', 'bold', 'FontSize', 8, 'Color', [0.08, 0.08, 0.08], ...
        'BackgroundColor', 'white', 'Margin', 2, 'Interpreter', 'none')
end

plot3(ax, cad_centre_xz(1), overlay_height, cad_centre_xz(2), ...
    'kp', 'MarkerSize', 13, 'MarkerFaceColor', [1.00, 0.80, 0.10])

% The body x-axis points forward along -z_CAD.
quiver3(ax, cad_centre_xz(1), overlay_height, cad_centre_xz(2), ...
    0, 0, -0.38, 0, 'Color', 'white', ...
    'LineWidth', 1.8, 'MaxHeadSize', 0.45)
text(ax, cad_centre_xz(1), overlay_height-0.01, ...
    cad_centre_xz(2)-0.44, 'x_b', ...
    'HorizontalAlignment', 'left', 'FontSize', 10, 'FontWeight', 'bold', ...
    'Color', 'white')

% Look down from the top (+y) side. The camera-up vector rotates the
% projection so that the body x_b axis (-z_CAD) points to the right.
view(ax, [0, 1, 0])
camup(ax, [-1, 0, 0])
camproj(ax, 'orthographic')
daspect(ax, [1, 1, 1])
x_limits = [min(cad_motor_xyz(:, 1))-propeller_radius-0.10, ...
    max(cad_motor_xyz(:, 1))+propeller_radius+0.10];
z_limits = [min(cad_motor_xyz(:, 3))-propeller_radius-0.10, ...
    max(cad_motor_xyz(:, 3))+propeller_radius+0.10];
xlim(ax, x_limits)
ylim(ax, [min(cad_motor_xyz(:, 2))-0.08, overlay_height+0.05])
zlim(ax, z_limits)
axis(ax, 'off')
set(ax, 'Clipping', 'off')
ax.Toolbar.Visible = 'off';

exportgraphics(fig, figure_file, 'Resolution', 300)
fprintf('Motor-layout figure written to:\n  %s\n', figure_file)

%% Local functions
function motor_xyz = readMotorCenters(xml_file, num_of_motors)
xml_document = xmlread(xml_file);
instances = xml_document.getElementsByTagName('Instance');
motor_xyz = nan(num_of_motors, 3);

for node_idx = 0:instances.getLength-1
    instance = instances.item(node_idx);
    instance_name = char(instance.getAttribute('name'));
    motor_token = regexp(instance_name, ...
        '^Tmotor_MN505S_Base-(\d+)$', 'tokens', 'once');
    if isempty(motor_token)
        continue
    end

    motor_idx = str2double(motor_token{1});
    translation_node = instance.getElementsByTagName('Translation').item(0);
    motor_xyz(motor_idx, :) = sscanf( ...
        char(translation_node.getTextContent), '%f')';
end

if any(isnan(motor_xyz), 'all')
    error('The XML export does not contain all expected motor centers.')
end
end

function failure_factors = evaluateIndividualFailures( ...
    motor_positions, yaw_factor)
num_of_motors = size(motor_positions, 1);
r_x = motor_positions(:, 1);
r_y = motor_positions(:, 2);
thr_factor = ones(num_of_motors, 1)/num_of_motors;

% This is the same mixer and quadratic program used by
% get_motor_failure_factor. It is repeated here only to retain each case
% for the report; the function's maximum remains the governing result.
mixer_matrix = [-r_y'; r_x'; yaw_factor'; thr_factor'];
hover_typical_cmds = [0; 0; 0; 0.5];
W = eye(4);
H = mixer_matrix'*W*mixer_matrix;
f = (-hover_typical_cmds'*W*mixer_matrix)';
Aeq = zeros(1, num_of_motors);
quadprog_options = optimoptions('quadprog', 'Display', 'off');
failure_factors = inf(num_of_motors, 1);

for failed_motor_idx = 1:num_of_motors
    Aeq(failed_motor_idx) = 1;
    x = quadprog(H, f, [], [], Aeq, 0, [], [], [], quadprog_options);
    Aeq(failed_motor_idx) = 0;
    if all(abs(mixer_matrix*x-hover_typical_cmds) < 1e-4)
        failure_factors(failed_motor_idx) = ...
            max(x)/hover_typical_cmds(end);
    end
end
end

function plotCadAssemblyTopView(ax, xml_file, cad_dir)
xml_document = xmlread(xml_file);
instances = xml_document.getElementsByTagName('Instance');
part_expressions = {
    '^TopView-1$', 'TopView_Default_sldprt.STEP', [0.78, 0.80, 0.82]
    '^Arm1-8-\d+$', 'Arm1-8_Default_sldprt.STEP', [0.32, 0.34, 0.36]
    '^Arm2-7-\d+$', 'Arm2-7_Default_sldprt.STEP', [0.32, 0.34, 0.36]
    '^Arm3-6-\d+$', 'Arm3-6_Default_sldprt.STEP', [0.32, 0.34, 0.36]
    '^Arm4-5-\d+$', 'Arm4-5_Default_sldprt.STEP', [0.32, 0.34, 0.36]
    };
geometry_cache = containers.Map;

for expression_idx = 1:size(part_expressions, 1)
    expression = part_expressions{expression_idx, 1};
    geometry_name = part_expressions{expression_idx, 2};
    face_colour = part_expressions{expression_idx, 3};
    geometry_file = fullfile(cad_dir, geometry_name);

    if ~isKey(geometry_cache, geometry_file)
        geometry_cache(geometry_file) = fegeometry(geometry_file);
    end
    geometry = geometry_cache(geometry_file);

    for node_idx = 0:instances.getLength-1
        instance = instances.item(node_idx);
        instance_name = char(instance.getAttribute('name'));
        if isempty(regexp(instance_name, expression, 'once'))
            continue
        end

        transform_node = instance.getElementsByTagName('Transform').item(0);
        rotation_node = transform_node.getElementsByTagName('Rotation').item(0);
        translation_node = transform_node.getElementsByTagName('Translation').item(0);
        rotation = reshape(sscanf( ...
            char(rotation_node.getTextContent), '%f'), 3, 3)';
        translation = sscanf( ...
            char(translation_node.getTextContent), '%f');
        plotCadPart(ax, geometry, rotation, translation, face_colour)
    end
end

camlight(ax, 'headlight')
lighting(ax, 'gouraud')
end

function plotCadPart(ax, geometry, rotation, translation, face_colour)
old_children = ax.Children;
pdegplot(ax, geometry, 'FaceAlpha', 1);
hold(ax, 'on')
new_children = setdiff(ax.Children, old_children);
transform_group = hgtransform('Parent', ax);

for child_idx = 1:numel(new_children)
    object = new_children(child_idx);
    if isa(object, 'matlab.graphics.primitive.Patch')
        object.FaceColor = face_colour;
        object.EdgeColor = 'none';
        object.Parent = transform_group;
    elseif isa(object, 'matlab.graphics.chart.primitive.Line')
        object.Visible = 'off';
        object.Parent = transform_group;
    else
        delete(object)
    end
end

transform_group.Matrix = [rotation, translation(:); 0, 0, 0, 1];
end

function writeLine(file_id, text_line)
fprintf(file_id, '%s\n', text_line);
end
