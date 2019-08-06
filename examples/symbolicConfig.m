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

%% Obtain Field Equations from the Divertor
% Other blabla

% Define symbolic "query" variables
x = sym('x','real');
y = sym('y','real');

% Obtain field equations
bx = divertor.magFieldX(x,y);
by = divertor.magFieldY(x,y);
fx = divertor.fluxFx(x,y,R);

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

%% Substitute Real Values in Symbolic Expressions
% Final blabla. Discourage using subs for performance.
% Warn for expint definition etcetc.

% Perform substitutions
subOld = [xc,yc,cI,sgm,R];
%subOld = mat2cell(subOld,1,numel(subOld));
subNew = [0,0,60,-10,1,0.5,4,150];
bx = subs(bx,subOld,subNew);
by = subs(by,subOld,subNew);
fx = subs(fx,subOld,subNew);

% Create meshgrid
step = 6;
nx = linspace(-50,50,100);
ny = linspace(-20,120,120);
[X,Y] = meshgrid(nx,ny);
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

% Create function handles to plot the configurations
hbx = matlabFunction(bx,'Vars',[x,y]);
hby = matlabFunction(by,'Vars',[x,y]);
% Create meshgrided flux function
nfx = subs(vpa(fx),{x,y},{X,Y});

figure('Position',[10 10 968 420])
subplot(1,2,1)
quiver(lX,lY,hbx(lX,lY),hby(lX,lY),2)
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Magnetic Field','Interpreter','latex')
axis image
ax = subplot(1,2,2);
contourf(X,Y,nfx,40,'EdgeColor','none')
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Poloidal Flux, $\psi$','Interpreter','latex')
colorbar
axis image

%%
% Note that symbolic configurations cannot be commit.
config.commit;