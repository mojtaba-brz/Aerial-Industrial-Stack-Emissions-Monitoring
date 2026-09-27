function aeat_closed_loop_controller(block)
%AEAT_CLOSED_LOOP_CONTROLLER Editable virtual-control allocator for the AEAT copy.
%   Inputs: reference position, reference Euler angles, actual position,
%   velocity, Euler angles, and body rates. Output: eight commanded rotor
%   thrusts in N.  Constants are deliberately collected in Outputs so a later
%   controller replacement does not require rewiring the analysis model.

setup(block);
end

function setup(block)
block.NumDialogPrms = 0;
block.NumInputPorts = 6;
for k = 1:6
    block.InputPort(k).Dimensions = 3;
    block.InputPort(k).DatatypeID = 0;
    block.InputPort(k).Complexity = 'Real';
    block.InputPort(k).DirectFeedthrough = true;
    block.InputPort(k).SamplingMode = 'Sample';
end
block.NumOutputPorts = 1;
block.OutputPort(1).Dimensions = 8;
block.OutputPort(1).DatatypeID = 0;
block.OutputPort(1).Complexity = 'Real';
block.OutputPort(1).SamplingMode = 'Sample';
block.SampleTimes = [0 0];
block.SimStateCompliance = 'DefaultSimState';
block.RegBlockMethod('Outputs', @Outputs);
end

function Outputs(block)
mass = 21.13;                 % kg; manuscript reference configuration
g = 9.80665;                  % m/s^2
armRadius = 0.60;             % m; transparent generic octo allocation radius
yawMomentCoefficient = 0.020; % N m per N, assumed rotor drag-torque factor
maxRotorThrust = 65.5308;     % N; retained static component-limit value

referencePosition = block.InputPort(1).Data(:);
referenceEuler = block.InputPort(2).Data(:);
position = block.InputPort(3).Data(:);
velocity = block.InputPort(4).Data(:);
euler = block.InputPort(5).Data(:);
bodyRates = block.InputPort(6).Data(:);

% Translational loop produces a bounded inertial acceleration request.
positionError = referencePosition - position;
accelerationCommand = 0.85 .* positionError - 1.20 .* velocity;
accelerationCommand = min(max(accelerationCommand, -3.0), 3.0);

% Small-angle attitude references provide lateral acceleration while the
% reference yaw remains supplied by the existing path planner.
rollCommand = min(max(-accelerationCommand(2) / g, -deg2rad(20)), deg2rad(20));
pitchCommand = min(max(accelerationCommand(1) / g, -deg2rad(20)), deg2rad(20));
eulerCommand = [rollCommand; pitchCommand; referenceEuler(3)];

% Collective thrust is corrected for the commanded tilt and bounded by the
% eight retained motor limits.
collective = mass * (g + accelerationCommand(3)) / ...
    max(cos(rollCommand) * cos(pitchCommand), 0.75);
collective = min(max(collective, 0), 8 * maxRotorThrust);

attitudeError = eulerCommand - euler;
attitudeError(3) = atan2(sin(attitudeError(3)), cos(attitudeError(3)));
momentCommand = [4.0; 4.0; 1.5] .* attitudeError - [1.8; 1.8; 0.8] .* bodyRates;
momentCommand = min(max(momentCommand, [-3; -3; -1.5]), [3; 3; 1.5]);

% Generic alternating-spin octo allocation. This is intentionally modular:
% replace this matrix with a CAD-verified allocation before reporting any
% actuator-feasibility result.
angles = (0:7)' * pi / 4;
x = armRadius * cos(angles);
y = armRadius * sin(angles);
spin = [1; -1; 1; -1; 1; -1; 1; -1];
allocation = [ones(1, 8); y'; -x'; yawMomentCoefficient * spin'];
rotorThrust = pinv(allocation) * [collective; momentCommand];
block.OutputPort(1).Data = min(max(rotorThrust, 0), maxRotorThrust);
end
