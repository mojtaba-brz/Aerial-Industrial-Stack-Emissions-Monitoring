function autoSortSimulinkModel(model)
% AUTOSORTSIMULINKMODEL Automatically sorts the current Simulink model layout
%   This function organizes blocks and lines in the current Simulink model
%   using built-in layout tools and custom sorting algorithms.

if isempty(model)
    error('No Simulink model is open');
end

% Start sorting process
fprintf('Sorting model: %s\n', model);

% 1. First auto-arrange using Simulink's built-in function
try
    Simulink.BlockDiagram.arrangeSystem(model, ...
        'FullLayout', 'true');
    fprintf(' - Performed initial auto-arrange\n');
catch
    fprintf(' - Basic auto-arrange failed, continuing with custom sort\n');
end

% 2. Custom sorting by block type
fprintf(' - Organizing blocks by type...\n');
organizeBlocksByType(model);

% 3. Straighten signal lines
% fprintf(' - Straightening signal lines...\n');
% straightenAllLines(model);

% 4. Final alignment pass
fprintf(' - Performing final alignment...\n');
alignAllBlocks(model);

fprintf('Model sorting complete for: %s\n', model);
end

%% Helper Functions
function organizeBlocksByType(model)
% Group blocks by type and arrange in columns
blockTypes = {'Gain', 'Sum', 'Integrator', 'TransferFcn', 'Scope', 'Constant'};
positionX = 100;
positionY = 100;
ySpacing = 120;
xSpacing = 200;

for i = 1:length(blockTypes)
    blocks = find_system(model, 'BlockType', blockTypes{i});
    if ~isempty(blocks)
        for j = 1:length(blocks)
            if ~strcmp(get_param(blocks{j},'Parent'), model)
                continue; % Skip blocks in subsystems
            end
            pos = get_param(blocks{j}, 'Position');
            width = pos(3)-pos(1);
            height = pos(4)-pos(2);
            newPos = [positionX, positionY, positionX+width, positionY+height];
            set_param(blocks{j}, 'Position', newPos);
            positionY = positionY + height + ySpacing;
        end
        positionX = positionX + xSpacing;
        positionY = 100;
    end
end
end

function straightenAllLines(model)
% Straighten all signal lines in the model
lines = find_system(model, 'FindAll', 'on', 'Type', 'line');
for i = 1:length(lines)
    try
        % Skip lines that are already straight
        points = get_param(lines(i), 'Points');
        if size(points, 1) > 2
            % Simplify to start and end points only
            newPoints = [points(1,:); points(end,:)];
            set_param(lines(i), 'Points', newPoints);
        end
    catch
        continue;
    end
end
end

function alignAllBlocks(model)
% Align blocks with their connected neighbors
blocks = find_system(model, 'SearchDepth', 1, 'Type', 'block');
for i = 1:length(blocks)
    if strcmp(get_param(blocks{i},'Parent'), model)
        alignBlockWithNeighbors(blocks{i});
    end
end
end

function alignBlockWithNeighbors(block)
% Align a block with its connected neighbors
try
    ports = get_param(block, 'PortHandles');
    
    % Align with source blocks
    for i = 1:length(ports.Inport)
        line = get_param(ports.Inport(i), 'Line');
        if line ~= -1
            srcBlock = get_param(get_param(line, 'SrcBlockHandle'), 'Position');
            myPos = get_param(block, 'Position');
            newY = srcBlock(2) + (srcBlock(4)-srcBlock(2))/2 - (myPos(4)-myPos(2))/2;
            set_param(block, 'Position', [myPos(1) newY myPos(3) newY+(myPos(4)-myPos(2))]);
        end
    end
    
    % Align with destination blocks
    for i = 1:length(ports.Outport)
        line = get_param(ports.Outport(i), 'Line');
        if line ~= -1
            dstBlock = get_param(get_param(line, 'DstBlockHandle'), 'Position');
            myPos = get_param(block, 'Position');
            newY = dstBlock(2) + (dstBlock(4)-dstBlock(2))/2 - (myPos(4)-myPos(2))/2;
            set_param(block, 'Position', [myPos(1) newY myPos(3) newY+(myPos(4)-myPos(2))]);
        end
    end
catch
    % Skip if alignment fails
end
end