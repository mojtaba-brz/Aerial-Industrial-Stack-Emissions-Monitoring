clc;clear;close all
modifyGeometryFilePath("SolidworksOutput/AerialPlatformTotal.xml")
closeAllSimulinkModels()
remove_previous_files()
smimport("SolidworksOutput\AerialPlatformTotal.xml")
%%
pause(1)
currentModel = saveCurrentSimulinkModel();
modifyGeneratedSLXFile(currentModel, true)

function modifyGeometryFilePath(xmlFilePath)

% MODIFYGEOMETRYFILEPATH Adds 'SolidworksOutput/' to GeometryFile name attribute if not present
%
% Input:
%   xmlFilePath - Path to the XML file to modify

% Read the file content
fileID = fopen(xmlFilePath, 'r');
if fileID == -1
    error('Could not open file: %s', xmlFilePath);
end

% Read all lines into a cell array
fileContent = textscan(fileID, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fileID);
lines = fileContent{1};

% Pattern to find
pattern = '<GeometryFile name="(?!SolidworksOutput/)';
replacement = '<GeometryFile name="SolidworksOutput/';

% Modify lines that match the pattern
modified = false;
for i = 1:numel(lines)
    if ~isempty(regexp(lines{i}, pattern, 'once'))
        lines{i} = regexprep(lines{i}, pattern, replacement);
        modified = true;
    end
end

if ~modified
    fprintf('No modifications were needed in file: %s\n', xmlFilePath);
    return;
end

% Write the modified content back to the file
fileID = fopen(xmlFilePath, 'w');
if fileID == -1
    error('Could not open file for writing: %s', xmlFilePath);
end

for i = 1:numel(lines)
    fprintf(fileID, '%s\n', lines{i});
end

fclose(fileID);
fprintf('%s Modified\n', xmlFilePath);
end

function closeAllSimulinkModels()
% CLOSEALLSIMULINKMODELS Closes all open Simulink models without saving
%   This function will close all Simulink models that are currently open,
%   including any referenced models or libraries. The user will be prompted
%   to confirm before closing any unsaved models.

% Get list of all open models
openModels = find_system('SearchDepth', 0, 'Type', 'block_diagram');

% Check if any models are open
if isempty(openModels)
    disp('No Simulink models are currently open.');
    return;
end

for i = 1:length(openModels)
    try
        % Close without saving
        close_system(openModels{i}, 0);
        fprintf('Closed: %s\n', openModels{i});
    catch ME
        fprintf('Error closing %s: %s\n', openModels{i}, ME.message);
    end
end
end

function remove_previous_files()
files = dir('AerialPlatformTotal*');

for i = 1:length(files)
    delete(files(i).name);
end

files = dir('modified_model*');
for i = 1:length(files)
    delete(files(i).name);
end

files = dir('*_Modified*');
for i = 1:length(files)
    delete(files(i).name);
end
end

function currentModel = saveCurrentSimulinkModel()
% SAVECURRENTSIMULINKMODEL Saves the currently open unsaved Simulink model

% Get all open models
openModels = find_system('SearchDepth', 0, 'type', 'block_diagram');

% Check if any models are open
if isempty(openModels)
    disp('No Simulink models are currently open.');
    return;
end

% Get the current (top-level) model
currentModel = bdroot;

% Check if the model is new/unsaved
modelPath = which(currentModel);
if isempty(modelPath)
    % Model has never been saved
    disp(['Model "', currentModel, '" has not been saved before.']);
    
    % Prompt user for save location and filename
    [filename, pathname] = uiputfile('*.slx', 'Save Simulink Model As', currentModel);
    
    if isequal(filename, 0) || isequal(pathname, 0)
        disp('Save operation cancelled by user.');
        return;
    else
        % Save the model with the specified name
        save_system(currentModel, fullfile(pathname, filename));
    end
else
    % Model exists on disk - just save it
    save_system(currentModel);
end
close_system(currentModel);
end
