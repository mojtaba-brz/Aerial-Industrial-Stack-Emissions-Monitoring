clc;clear;close all

% Mass [Kg]
Mass = 31334.5 * 1e-3; 

% Center of mass with respect to solidWorks Coordinate system: ( millimeters )
X = 625.11;
Y = 320.22;
Z = 1103.58;

% Moment Inertia in solidWorks Coordinate system [Kg*m^2]
I = [3991234628.10  -2849924.97   6313965.33;
	 -2849924.97    4174935460.32 401441209.61;
	  6313965.33    401441209.61  1638016863.76]*1e-6*1e-3;

% Transfer Function between SolidWorks Coordinat system and 'b'  
T = [0 0 -1;1 0 0;0 -1 0];

% Moment Inertia in 'b' Coordinate system [Kg*m^2]
I = T*I*(T');

% Center of mass with respect to solidWorks Coordinate system
% in 'b' Coordinate system [m]
cg = (T*[X;Y;Z]*1e-3)';

% Motors Position ith respect to solidWorks Coordinate system
% in 'b' Coordinate system [m]
d_motor_1_b = (T * [1029.99; 442.84; 796.81]*1e-3)';
d_motor_2_b = (T * [1054.99; 442.84; 1434.81]*1e-3)'; 
d_motor_3_b = (T * [194.99;  442.84; 1434.81]*1e-3)';
d_motor_4_b = (T * [219.99;  442.84; 796.81 ]*1e-3)';
d_motor_5_b = (T * [1029.99; 402.84; 796.81]*1e-3)';
d_motor_6_b = (T * [1054.99; 402.84; 1434.81]*1e-3)';
d_motor_7_b = (T * [194.99;  402.84; 1434.81]*1e-3)';
d_motor_8_b = (T * [219.99;  402.84; 796.81 ]*1e-3)';



% Center Point of Motors : 'b' ----------------
a1 = (d_motor_1_b(2) - d_motor_3_b(2))/(d_motor_1_b(1) - d_motor_3_b(1));
a2 = (d_motor_2_b(2) - d_motor_4_b(2))/(d_motor_2_b(1) - d_motor_4_b(1));
b1 = d_motor_1_b(2) - a1*d_motor_1_b(1); 
b2 = d_motor_2_b(2) - a2*d_motor_2_b(1); 


b = ([(b2 - b1)/(a1 - a2)
      a2 * (b2 - b1)/(a1 - a2) + b2
      (d_motor_1_b(3) + d_motor_5_b(3))/2])';

% ---------------------------------------------

% Motors and CG Position with respect to b
d_motor_1_b = d_motor_1_b - b;
d_motor_2_b = d_motor_2_b - b;
d_motor_3_b = d_motor_3_b - b;
d_motor_4_b = d_motor_4_b - b;
d_motor_5_b = d_motor_5_b - b;
d_motor_6_b = d_motor_6_b - b;
d_motor_7_b = d_motor_7_b - b;
d_motor_8_b = d_motor_8_b - b;

cg = cg - b;
% ----------------------------------------



% Robotic Arm params

% a0 with recpect to 'b' in 'b' [m]
d_a0_b  = 1e-3*(T * [625.99; 260.84; 494.41])' - b;

% a1 with recpect to 'a0' in 'a0' [m]
d_a1_a0 = 1e-3*(T * [626.025; 217.84; 494.37])'- b - d_a0_b;

% a2 with recpect to 'a1' in 'a1' [m]
d_a2_a1 = 1e-3* [364.9984 0 0];

% w1 with recpect to 'a2' in 'a2' [m]
d_w1_a2 = 1e-3* [430 10.94 0];

% w2 with recpect to 'w1' in 'w1' [m]
d_w2_w1 = 1e-3* [0 0 57.5];

% w3 with recpect to 'w2' in 'w2' [m]
d_w3_w2 = 1e-3* [32.83 0 0];

% prob with recpect to 'w3' in 'w3' [m]
d_probe_w3 = 1e-3* [40.03 0 170.21];













