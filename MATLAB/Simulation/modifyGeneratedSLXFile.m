function modifyGeneratedSLXFile(inputFile, config_servos)
outputFile = [inputFile, '_Modified.slx'];
inputFile = [inputFile, '.slx'];
try
    save_system(gcs)
    close_system(gcs)
catch
    % pass
end
load_system(inputFile);
save_system(gcs, outputFile);
close_system(gcs);
load_system(outputFile);

param_table = readtable("Data.xlsx");
x_cg_mm = param_table.Column1(13) * 1000;

% Find all Revolute Joint blocks in the model
sm_blocks = find_system(gcs, 'LookUnderMasks', 'all', 'BlockType', 'SimscapeMultibodyBlock');

% Initialize a counter for renamed blocks
renamedCount = 0;

% Process each Revolute Joint block
for i = 1:length(sm_blocks)
    currentBlock = sm_blocks{i};
    if contains(currentBlock, '/Revolute') || contains(currentBlock, '/Cylindrical')
        % Get the source and destination ports
        srcPorts = get_param(currentBlock, 'PortConnectivity');

        srcBlock = get_param(srcPorts(1).DstBlock, 'Name');
        dstBlock = get_param(srcPorts(2).DstBlock, 'Name');

        if ~isempty(srcBlock) && ~isempty(dstBlock)
            % Check if the connection matches our pattern
            [isTmotor, iVal] = isTmotorSubsystem(srcBlock);
            [isProp, ~] = isPropSubsystem(dstBlock);

            if ~isTmotor || ~isProp
                % Check the reverse connection
                [isTmotor, iVal] = isTmotorSubsystem(dstBlock);
                [isProp, ~] = isPropSubsystem(srcBlock);
            end

            if isTmotor && isProp
                newName = ['M_', num2str(iVal)];

                % Check if the name already exists in the current subsystem
                parent = get_param(currentBlock, 'Parent');
                existingBlocks = find_system(parent, 'SearchDepth', 1, 'Name', newName);

                if isempty(existingBlocks) || strcmp(existingBlocks{1}, currentBlock)
                    if contains(currentBlock, '/Cylindrical')
                        set_param(currentBlock, 'RzMotionActuationMode', "InputMotion");
                        set_param(currentBlock, 'RzTorqueActuationMode', "ComputedTorque");
                    else
                        set_param(currentBlock, 'MotionActuationMode', "InputMotion");
                        set_param(currentBlock, 'TorqueActuationMode', "ComputedTorque");
                    end

                    model_name = split(currentBlock, '/');
                    model_name = char(model_name(1));
                    sim_to_ps_block = [model_name, '/S-PS_M_', num2str(iVal)];
                    add_block('nesl_utility/Simulink-PS Converter', sim_to_ps_block);
                    set_param(sim_to_ps_block, "FilteringAndDerivatives", "filter")
                    set_param(sim_to_ps_block, "SimscapeFilterOrder", "2")
                    set_param(sim_to_ps_block, "InputFilterTimeConstant", "0.01")

                    input_block = [model_name, '/In_M_', num2str(iVal)];
                    add_block('simulink/Sources/In1', input_block);

                    % tfParams.num = [1, 0];
                    % tfParams.den = [1/100, 2*10/100, 1];
                    % configureTransferFunction(model_name, tfParams, input_block, currentBlock);

                    input_ports = get_param(input_block, "PortHandles");
                    sim_to_ps_ports = get_param(sim_to_ps_block, "PortHandles");
                    block_ports = get_param(currentBlock, "PortHandles");
                    add_line(model_name, input_ports.Outport, sim_to_ps_ports.Inport);
                    add_line(model_name, sim_to_ps_ports.RConn, block_ports.LConn(2));

                    set_param(currentBlock, 'Name', newName);
                    fprintf('Renamed block %s to %s\n', currentBlock, newName);
                    renamedCount = renamedCount + 1;
                else
                    fprintf('Skipped block %s - name %s already exists\n', currentBlock, newName);
                end
            end

            if config_servos && ...
               (contains(srcBlock, 'Servo_') || contains(dstBlock, 'Servo_')) && ...
               ~(contains(srcBlock, 'TopView') || contains(dstBlock, 'TopView'))
                if contains(srcBlock, 'Servo_')
                    servo_name_split = split(srcBlock, '_');
                else
                    servo_name_split = split(dstBlock, '_');
                end
                servo_name = [servo_name_split{1:end-1}];
                if contains(currentBlock, '/Cylindrical')
                    set_param(currentBlock, 'RzMotionActuationMode', "InputMotion");
                    set_param(currentBlock, 'RzTorqueActuationMode', "ComputedTorque");
                else
                    set_param(currentBlock, 'MotionActuationMode', "InputMotion");
                    set_param(currentBlock, 'TorqueActuationMode', "ComputedTorque");
                end
                model_name = char(gcs);
                sim_to_ps_block = [model_name, '/S-PS_', servo_name];
                add_block('nesl_utility/Simulink-PS Converter', sim_to_ps_block);
                set_param(sim_to_ps_block, "FilteringAndDerivatives", "filter")
                set_param(sim_to_ps_block, "SimscapeFilterOrder", "2")
                set_param(sim_to_ps_block, "InputFilterTimeConstant", "0.01")

                input_block = [model_name, '/In_', char(servo_name)];
                add_block('simulink/Sources/In1', input_block);

                % tfParams.num = [1, 0];
                % tfParams.den = [1/100, 2*10/100, 1];
                % configureTransferFunction(model_name, tfParams, input_block, currentBlock);

                input_ports = get_param(input_block, "PortHandles");
                sim_to_ps_ports = get_param(sim_to_ps_block, "PortHandles");
                block_ports = get_param(currentBlock, "PortHandles");
                add_line(model_name, input_ports.Outport, sim_to_ps_ports.Inport);
                add_line(model_name, sim_to_ps_ports.RConn, block_ports.LConn(2));

                set_param(currentBlock, 'Name', servo_name);
                fprintf('Renamed block %s to %s\n', currentBlock, servo_name);
                renamedCount = renamedCount + 1;
            end
        end
    end
end

transform_block = [gcs, '/Transform'];
config_block    = [gcs, '/MechanismConfiguration'];
top_view_block  = [gcs, '/TopView_1_RIGID'];
sixdof_block  = [gcs, '/SixDOF'];
cartezian_block = [gcs, '/UAV Pos'];
psi_block = [gcs, '/UAV Psi'];
theta_block = [gcs, '/UAV Theta'];
phi_block = [gcs, '/UAV Phi'];
transform_block_body = [top_view_block, '/body_coordinate'];
transform_block_body_port = [top_view_block, '/body_coordinate_port'];
transform_block_psi_theta = [gcs, '/psi_theta'];
transform_block_theta_phi = [gcs, '/theta_phi'];
transform_block_rev_body = [gcs, '/rev_body'];

add_block('sm_lib/Frames and Transforms/Rigid Transform', transform_block_body);
add_block('sm_lib/Frames and Transforms/Rigid Transform', transform_block_psi_theta);
add_block('sm_lib/Frames and Transforms/Rigid Transform', transform_block_theta_phi);
add_block('sm_lib/Frames and Transforms/Rigid Transform', transform_block_rev_body);
add_block('nesl_utility/Connection Port', transform_block_body_port);
add_block('sm_lib/Joints/Revolute Joint', psi_block);
add_block('sm_lib/Joints/Revolute Joint', phi_block);
add_block('sm_lib/Joints/Revolute Joint', theta_block);
add_block('sm_lib/Joints/Cartesian Joint', cartezian_block);

set_param(transform_block, 'RotationMethod', 'None')
set_param(transform_block, 'TranslationMethod', 'None')

set_param(config_block, 'GravityVector', '[0 0 9.80665]')

set_param(psi_block, 'MotionActuationMode', "InputMotion");
set_param(psi_block, 'TorqueActuationMode', "ComputedTorque");
set_param(theta_block, 'MotionActuationMode', "InputMotion");
set_param(theta_block, 'TorqueActuationMode', "ComputedTorque");
set_param(phi_block, 'MotionActuationMode', "InputMotion");
set_param(phi_block, 'TorqueActuationMode', "ComputedTorque");

config_rigid_transform_block(transform_block_body, [-90 90 0], [0 0 x_cg_mm])
config_rigid_transform_block(transform_block_psi_theta, [0 0 -90], [0 0 0])
config_rigid_transform_block(transform_block_theta_phi, [0 90 0], [0 0 0])
config_rigid_transform_block(transform_block_rev_body, [90 -90 0], [0 0 0])

set_param(cartezian_block, 'PxMotionActuationMode', 'InputMotion')
set_param(cartezian_block, 'PyMotionActuationMode', 'InputMotion')
set_param(cartezian_block, 'PzMotionActuationMode', 'InputMotion')
set_param(cartezian_block, 'PxTorqueActuationMode', 'ComputedTorque')
set_param(cartezian_block, 'PyTorqueActuationMode', 'ComputedTorque')
set_param(cartezian_block, 'PzTorqueActuationMode', 'ComputedTorque')

body_ports = get_param(transform_block_body, 'PortHandles');
output_ports = get_param(transform_block_body_port, 'PortHandles');
ref_coord_ports = get_param([top_view_block, '/ReferenceFrame'], 'PortHandles');
top_view_block_ports = get_param(top_view_block, 'PortHandles');
sixdof_block_ports = get_param(sixdof_block, 'PortHandles');
sixdof_block_con = get_param(sixdof_block, 'PortConnectivity');
transform_block_ports = get_param(transform_block, 'PortHandles');
transform_block_psi_theta_ports = get_param(transform_block_psi_theta, 'PortHandles');
transform_block_theta_phi_ports = get_param(transform_block_theta_phi, 'PortHandles');
transform_block_rev_body_ports = get_param(transform_block_rev_body, 'PortHandles');
cartezian_block_ports = get_param(cartezian_block, 'PortHandles');
psi_block_ports = get_param(psi_block, 'PortHandles');
theta_block_ports = get_param(theta_block, 'PortHandles');
phi_block_ports = get_param(phi_block, 'PortHandles');

delete_line(gcs, sixdof_block_ports.RConn, sixdof_block_con(2).DstPort)
delete_line(gcs, sixdof_block_ports.LConn, sixdof_block_con(1).DstPort)
delete_block(sixdof_block);

add_line(gcs, transform_block_ports.RConn, cartezian_block_ports.LConn(1))
add_line(gcs, cartezian_block_ports.RConn, psi_block_ports.LConn(1))
add_line(gcs, psi_block_ports.RConn, transform_block_psi_theta_ports.LConn)
add_line(gcs, transform_block_psi_theta_ports.RConn, theta_block_ports.LConn(1))
add_line(gcs, theta_block_ports.RConn, transform_block_theta_phi_ports.LConn)
add_line(gcs, transform_block_theta_phi_ports.RConn, phi_block_ports.LConn(1))
add_line(gcs, phi_block_ports.RConn, transform_block_rev_body_ports.LConn)
add_line(gcs, transform_block_rev_body_ports.RConn, top_view_block_ports.LConn(end))
add_line(top_view_block, body_ports.LConn, ref_coord_ports.RConn)
add_line(top_view_block, body_ports.RConn, output_ports.RConn)

set_up_ps_and_input('X', cartezian_block_ports.LConn(2))
set_up_ps_and_input('Y', cartezian_block_ports.LConn(3))
set_up_ps_and_input('Z', cartezian_block_ports.LConn(4))

set_up_ps_and_input('Psi', psi_block_ports.LConn(2))
set_up_ps_and_input('Theta', theta_block_ports.LConn(2))
set_up_ps_and_input('Phi', phi_block_ports.LConn(2))

if ~config_servos

end

autoSortSimulinkModel(gcs)

convertModelToSubsystem(gcs)
autoSortSimulinkModel(gcs)

% Save the modified model
save_system(gcs, outputFile);
close_system(gcs);

fprintf('\n\n\nDone...\n%d Joint blocks have been Renamed.\n', renamedCount);
end

function [isMatch, iVal] = isTmotorSubsystem(blockName)
% Check if the block name matches Tmotor_MN505S_Skin_i_RIGID pattern
pattern = '^Tmotor_MN505S_Skin_(\d+)_RIGID$';
tokens = regexp(blockName, pattern, 'tokens');

if ~isempty(tokens)
    isMatch = true;
    iVal = str2double(tokens{1}{1});
else
    isMatch = false;
    iVal = NaN;
end
end

function [isMatch, rotation] = isPropSubsystem(blockName)
% Check if the block name matches Prop_22_66_CW_j_RIGID or Prop_22_66_CCW_j_RIGID pattern
pattern = '^Prop_22_66_(CW|CCW)_(\d+)_RIGID$';
tokens = regexp(blockName, pattern, 'tokens');

if ~isempty(tokens)
    isMatch = true;
    rotation = tokens{1}{1}; % CW or CCW
else
    isMatch = false;
    rotation = '';
end
end

function configureTransferFunction(modelName, tfParams, inputBlock, outputBlock)
% Load or create model
if ~bdIsLoaded(modelName)
    try
        load_system(modelName);
    catch
        new_system(modelName);
        open_system(modelName);
    end
end

% Create unique transfer function block name
tfBlockName = [modelName '/TF_' mat2str(round(rand(1)*1000))];

% Add transfer function block
add_block('simulink/Continuous/Transfer Fcn', tfBlockName, ...
    'Numerator', mat2str(tfParams.num), ...
    'Denominator', mat2str(tfParams.den));

% Position the block (optional)
% set_param(tfBlockName, 'Position', [200, 100, 250, 150]);

% Connect input
if ~isempty(inputBlock)
    srcPort = get_param(inputBlock, 'PortHandles').Outport(1);
    tfPorts = get_param(tfBlockName, 'PortHandles');
    add_line(modelName, srcPort, tfPorts.Inport(1));
end

% Connect output
if ~isempty(outputBlock)
    tfPorts = get_param(tfBlockName, 'PortHandles');
    dstPort = get_param(outputBlock, 'PortHandles').Inport(1);
    add_line(modelName, tfPorts.Outport(1), dstPort);
end
end

function convertModelToSubsystem(modelName)
% Load the model if not already loaded
if ~bdIsLoaded(modelName)
    load_system(modelName);
end

% Get all blocks EXCEPT automatically created ports
allBlocks = find_system(modelName, 'SearchDepth', 1, 'Type', 'Block');

% Filter out default input/output ports
blocksToInclude = {};
for i = 1:length(allBlocks)
    blockType = get_param(allBlocks{i}, 'BlockType');
    % if ~strcmp(blockType, 'Inport') && ~strcmp(blockType, 'Outport')
    blocksToInclude{end+1} = allBlocks{i};
    % end
end

% Convert to a cell array of handles (not paths)
blockHandles = get_param(blocksToInclude, 'Handle');
blockHandles = cell2mat(blockHandles);
% Create the subsystem (using handles instead of paths)
Simulink.BlockDiagram.createSubsystem(blockHandles);
end

function set_up_ps_and_input(ps_short_name, ps_output_port)
sim_to_ps_block = [gcs, '/Sim-PS-', ps_short_name];
input_block = [gcs, '/In_', ps_short_name];
add_block('nesl_utility/Simulink-PS Converter', sim_to_ps_block);
add_block('simulink/Sources/In1', input_block);

set_param(sim_to_ps_block, "FilteringAndDerivatives", "filter")
set_param(sim_to_ps_block, "SimscapeFilterOrder", "2")
set_param(sim_to_ps_block, "InputFilterTimeConstant", "0.01")

input_ports = get_param(input_block, "PortHandles");
sim_to_ps_ports = get_param(sim_to_ps_block, "PortHandles");
add_line(gcs, input_ports.Outport, sim_to_ps_ports.Inport);
add_line(gcs, sim_to_ps_ports.RConn, ps_output_port);
end

function config_rigid_transform_block(block, atti, pos)
set_param(block, 'RotationMethod', 'RotationSequence')
set_param(block, 'RotationSequenceAngles', mat2str(atti))
set_param(block, 'RotationSequenceAnglesUnits', 'deg')
set_param(block, 'RotationSequenceAngles_conf', 'compiletime')
set_param(block, 'RotationSequenceAxes', 'FollowerAxes')
set_param(block, 'RotationSequence', 'ZYX')
set_param(block, 'TranslationMethod', 'Cartesian')
set_param(block, 'TranslationCartesianOffset', mat2str(pos))
set_param(block, 'TranslationCartesianOffsetUnits', 'mm')
end