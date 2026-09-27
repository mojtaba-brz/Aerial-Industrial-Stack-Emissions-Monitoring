function aeat_analysis_init_script()
%AEAT_ANALYSIS_INIT_SCRIPT Copy-only replacement for the legacy InitScript.
%   It evaluates the existing read_params.m content without its first
%   `clc;clear;close all` statement. That preserves all original parameters
%   while allowing batch and function-scope simulation outputs to survive.

simulationDir = fileparts(mfilename('fullpath'));
previousDirectory = pwd;
restoreDirectory = onCleanup(@() cd(previousDirectory)); %#ok<NASGU>
cd(simulationDir);

readParamsPath = fullfile(simulationDir, 'read_params.m');
assert(isfile(readParamsPath), 'The original read_params.m was not found.');
readParamsText = fileread(readParamsPath);
readParamsText = regexprep(readParamsText, '^\s*clc;clear;close all\s*(\r?\n)?', '', 'once');
evalin('base', readParamsText);

evalin('base', 'AerialPlatformTotal_DataFile');
addpath(fullfile(simulationDir, 'SolidworksOutput', 'Flange'));
evalin('base', 'StandardizedFlangeAndCover2_DataFile');
addpath(fullfile(simulationDir, '..', 'mr'));
assignin('base', 'arm_start', 0);
end
