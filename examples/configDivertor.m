%% Create a Sample Magnetic Configuration Object
% This demonsration script shows the intialization process of a simple
% magnetic divertor configuration using the <matlab:doc('mConf') mConf>
% class. Currents are first created, from which the configuration object is
% instanciated. The resulting object is then processed automatically.

%% Create Currents
% Before creating a configuration object, instanciated currents are needed.
% We also create a meshgrid delimiting the part of the domain we're
% interested in.

% Setup meshgrid and define major radius
x = linspace(-50,50,100);
y = linspace(-20,120,120);
[X,Y] = meshgrid(x,y);
R = 150;

% Create related set of currents.
plasma = currentGaussian(0,60,1,4);
divertor = currentWire(0,-10,0.5,plasma);

%% Create a Magnetic Configuration
% Now that currents are available, we may proceed by initializing a
% magnetic configuration object of the class <matlab:doc('mConf') mConf>
% with the following syntax,

c = [plasma, divertor];
config = mConf(R, [plasma,divertor]);

%%
% where |R| is the Tokamak's major radius, and |c| is an array of currents.
% The resulting variable, |config|, is a handle. If invalid current handles
% are being provided, the constructor will issue an error. When providing a
% set of related currents, the constructor also checks whether their
% parents have been included.
%
% At this point, the class already provides several handles to the magnetic
% field and poloidal flux function of the configuration (sum of the
% properties held in the provided currents).

%% Plots the Configuration
% Similarly to what was done with the simpleDivertor demonstration script,
% we plot the magnetic structure of the configuration using the class's
% function handles.
%
% * <matlab:doc('mConf/magFieldX') magFieldX> and
% <matlab:doc('mConf/magFieldY') magFieldY> provide components of the total
% magnetic field
% * <matlab:doc('mConf/fluxFx') fluxFx> provides the total poloidal flux
% function. Unlike the current's implementation, it only takes two input
% arguments since the major radius is already set in <matlab:doc('mConf/R')
% mConf/R>.

step = 6;
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

figure('Position',[10 10 968 420])
subplot(1,2,1)
quiver(lX,lY,config.magFieldX(lX,lY),config.magFieldY(lX,lY),2)
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Magnetic Field','Interpreter','latex')
axis image
ax = subplot(1,2,2);
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Poloidal Flux, $\psi$','Interpreter','latex')
colorbar
axis image

%% Commiting a Configuration
% At that point, working with a mConf object offers barely more comfort
% than using separate currents. Useful informations can be obtained through
% "commiting" a configuration. This commit step involves
%
% * detecting x-points, sepratrixes and the last closed flux surface (LCFS)
% and the core's center. All steps involve using numerical solvers which
% work with analytical field expressions,
% * computing geometrical properties (for example, $a$).
%
% If you try to commit the same configuration twice, a warning will be
% issued, and the computation will be aborted.
%
% In order to perform correctly, the solvers need to be provided with an
% interval in which the solution is expected. This *requirement* is
% fullfilled by providing mConf with an area of interest,
% <matlab:doc('mConf/simArea') mConf/simArea>, as a 2x2 matrix, defining
% the limits of the domain to be simulated. If none is provided, the class
% uses a default that will, in most cases fail.

config.simArea = [-50,50;-20,120];

%%
% Another requirement is that a single positive plasma current is stored in
% the mConf object at the time of a commit. A plasma current is defined by
% assigning the <matlab:doc('current/isPlasma') current/isPlasma> property
% to be true for the plasma current.

% As we still have a handle, we need not access directly config/Children,
% although we could have!
plasma.isPlasma = true;

%%
% The commit method takes, amongst others, two arguments regulating the
% search of x-points. The first, |nx|, caps the maximal number of solutions
% that are found, while the second, |nt|, indicates how many times the
% solver should be run (with random initial conditions).
%
%   config.commit(nx,nt)
%
% Additional options can be used and are found in the <matlab:doc('mConf/commit') mConf documentation>.
% Once commited, several properties of the mConf class are assigned,
%
% * <matlab:doc('mConf/xpoints') mConf/xpoints>, array containing x-point
% positions
% * <matlab:doc('mConf/separatrixPsi') mConf/separatrixPsi>, value of the
% poloidal flux function at the different separatrixes
% * <matlab:doc('mConf/lcfsPsi') mConf/lcfsPsi>, value of the poloidal flux
% function at the LCFS
% * <matlab:doc('mConf/corePosition') mConf/corePosition>, position of the
% core center
% * <matlab:doc('mConf/magR') mConf/magR>, structure with multiple
% (geometrical) radiuses
% * <matlab:doc('mConf/a') mConf/a>, radius of the core region
% * <matlab:doc('mConf/separatrixPsiTol') mConf/separatrixPsiTol>, in the
% event that multiple separatrix $\psi$ values are available when only one
% LCFS is present (mostly due to the numerical precision of the solvers),
% this parameter returns all individual values of $\psi$ it manages to
% indentify.
%
% Below, those properties are used to plot the previous configuration in
% more details.

% Compute configuration properties, return one x-point
config.commit(1)
disp('X-Point location:')
disp(config.xpoints)

% Continue plotting on the last figure, add
% - separatrix contours of the poloidal flux,
% - x-point and core positions.
hold(ax,'on')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi,...
    'Parent',ax)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'or','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold(ax,'off')

displayEndOfDemoMessage(mfilename)