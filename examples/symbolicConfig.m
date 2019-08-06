%% SYMBOLICCONFIG Work on Magnetic Configurations with Symbolic Variables
% In order to implement a configuration's magnetic structure equations
% elsewhere (GBS for example), it might be handy to obtain equations where
% system parameters are displayed as variables. Such parameters could be
% coils locations and currents, etc.
%
% We go through the creation and retrieval of such expressions using the
% <matlab:doc('current') current> and <matlab:doc('mConf') mConf> classes.

%% Create a Symbolic System
% Some blabla

% Define symbolic variables
xc  = sym('xc',[1,2],'real');   % Current locations (x)
yc  = sym('yc',[1,2],'real');   % Current locations (y)
cI  = sym('cI',[1,2],'real');   % Current intensities (I)
sgm = sym('sgm','real');        % Gaussian extension of the plasma current
R   = sym('R','real');          % Tokamak major radius

% Create currents
plasma = currentGaussian(xc(1),yc(1),cI(1),sgm);
plasma.isPlasma = true;
divertor = currentWire(xc(2),yc(2),cI(2),plasma);

% Create configuration
clear config % Make sure workspace is clean
config = mConf(R, [plasma,divertor]);

%% Obtain Field Equations from Currents
% Other blabla

% Define symbolic "query" variables
x = sym('x','real');
y = sym('y','real');

% Obtain field equations
bx = divertor.magFieldX(x,y);
by = divertor.magFieldY(x,y);
fx = divertor.fluxFx(x,y);

% Display these
disp(['Bx = ',char(bx)])
disp(['By = ',char(by)])
disp(['Fx = ',char(fx)])

%% Obtain Field Equations from the Magnetic Configuration
% Other blabla

% Define symbolic "query" variables
x = sym('x','real');
y = sym('y','real');

% Obtain field equations
bx = config.magFieldX(x,y);
by = config.magFieldY(x,y);
fx = config.fluxFx(x,y);

% Display these
disp(['Bx = ',char(bx)])
disp(['By = ',char(by)])
disp(['Fx = ',char(fx)])