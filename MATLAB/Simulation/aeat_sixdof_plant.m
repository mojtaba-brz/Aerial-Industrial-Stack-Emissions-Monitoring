function aeat_sixdof_plant(block)
%AEAT_SIXDOF_PLANT Editable rigid-body, rotor-lag, and energy plant.
%   This no-wind, no-contact model is an analysis scaffold. It exposes
%   independently evolving states so that reference-to-actual metrics can be
%   computed only after the signal provenance check passes.

setup(block);
end

function setup(block)
% Dialog parameters are resolved by the model from the existing mission
% workspace: initial position [m] and initial yaw [rad].
block.NumDialogPrms = 2;
block.NumContStates = 21; % p(3), v(3), Euler(3), omega(3), rotor thrust(8), Wh
block.NumInputPorts = 1;
block.InputPort(1).Dimensions = 8;
block.InputPort(1).DatatypeID = 0;
block.InputPort(1).Complexity = 'Real';
% Outputs are functions of continuous states only; derivatives consume the
% motor command. Declaring this false removes a spurious controller/plant
% algebraic loop while retaining causal motor dynamics.
block.InputPort(1).DirectFeedthrough = false;
block.InputPort(1).SamplingMode = 'Sample';
block.NumOutputPorts = 7;
dimensions = [3 3 3 3 8 1 1];
for k = 1:7
    block.OutputPort(k).Dimensions = dimensions(k);
    block.OutputPort(k).DatatypeID = 0;
    block.OutputPort(k).Complexity = 'Real';
    block.OutputPort(k).SamplingMode = 'Sample';
end
block.SampleTimes = [0 0];
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('InitializeConditions', @InitializeConditions);
block.RegBlockMethod('Derivatives', @Derivatives);
block.RegBlockMethod('Outputs', @Outputs);
end

function InitializeConditions(block)
mass = 21.13;
g = 9.80665;
initialState = zeros(21, 1);
% Align the independent plant with the existing mission's initial waypoint.
initialState(1:3) = block.DialogPrm(1).Data(:);
initialState(9) = block.DialogPrm(2).Data;
initialState(13:20) = mass * g / 8;
block.ContStates.Data = initialState;
end

function Derivatives(block)
mass = 21.13;
g = 9.80665;
inertia = diag([1.55, 1.65, 2.85]); % kg m^2; stated analysis assumption
armRadius = 0.60;                  % m; generic octo allocation geometry
yawMomentCoefficient = 0.020;      % N m per N
motorTimeConstant = 0.060;         % s
linearDrag = 1.4;                  % N s/m
angularDamping = [1.00; 1.00; 0.80]; % N m s/rad

state = block.ContStates.Data;
velocity = state(4:6);
euler = state(7:9);
bodyRates = state(10:12);
rotorThrust = max(state(13:20), 0);
commandedThrust = max(block.InputPort(1).Data(:), 0);

phi = min(max(euler(1), -deg2rad(60)), deg2rad(60));
theta = min(max(euler(2), -deg2rad(60)), deg2rad(60));
psi = euler(3);
rotation = [cos(psi) * cos(theta), cos(psi) * sin(theta) * sin(phi) - sin(psi) * cos(phi), cos(psi) * sin(theta) * cos(phi) + sin(psi) * sin(phi); ...
            sin(psi) * cos(theta), sin(psi) * sin(theta) * sin(phi) + cos(psi) * cos(phi), sin(psi) * sin(theta) * cos(phi) - cos(psi) * sin(phi); ...
            -sin(theta),            cos(theta) * sin(phi),                                      cos(theta) * cos(phi)];
acceleration = rotation(:, 3) * (sum(rotorThrust) / mass) - [0; 0; g] - linearDrag * velocity / mass;

angles = (0:7)' * pi / 4;
x = armRadius * cos(angles);
y = armRadius * sin(angles);
spin = [1; -1; 1; -1; 1; -1; 1; -1];
moments = [sum(y .* rotorThrust); -sum(x .* rotorThrust); yawMomentCoefficient * sum(spin .* rotorThrust)];
bodyRateDerivative = inertia \ (moments - cross(bodyRates, inertia * bodyRates) - angularDamping .* bodyRates);

safeCosTheta = sign(cos(theta)) * max(abs(cos(theta)), 0.15);
eulerRateMap = [1, sin(phi) * tan(theta), cos(phi) * tan(theta); ...
                0, cos(phi),             -sin(phi); ...
                0, sin(phi) / safeCosTheta, cos(phi) / safeCosTheta];
eulerDerivative = eulerRateMap * bodyRates;
powerW = 110 + 1.75 * sum(rotorThrust .^ 1.5);

derivative = zeros(21, 1);
derivative(1:3) = velocity;
derivative(4:6) = acceleration;
derivative(7:9) = eulerDerivative;
derivative(10:12) = bodyRateDerivative;
derivative(13:20) = (commandedThrust - rotorThrust) / motorTimeConstant;
derivative(21) = powerW / 3600;
block.Derivatives.Data = derivative;
end

function Outputs(block)
state = block.ContStates.Data;
rotorThrust = max(state(13:20), 0);
powerW = 110 + 1.75 * sum(rotorThrust .^ 1.5);
block.OutputPort(1).Data = state(1:3);
block.OutputPort(2).Data = state(4:6);
block.OutputPort(3).Data = state(7:9);
block.OutputPort(4).Data = state(10:12);
block.OutputPort(5).Data = rotorThrust;
block.OutputPort(6).Data = powerW;
block.OutputPort(7).Data = state(21);
end
