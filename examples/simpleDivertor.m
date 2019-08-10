%% Working with Multiple Currents
% In this script, two currents are created. One, Gaussian, will act as the
% plasma current, while the other one will act as a filament creating a
% basic magnetic divertor.

%% Domain and Current Definition
% While currents can be initialized without having to care about a valid
% domain on which their properties (say, magnetic field) can be computed,
% we define a meshgrid domain in cartesian coordinates to plot our
% configuration afterwards.
%
% We also suppose a Tokamak geometry with major radius $R=150$. This
% parameter will be necessary to compute the currents' poloidal flux
% functions.
%
% The plasma current is first initialized, and its handle is then passed to
% the filament current so that the two become dependent. For more detailed
% explanations, the reader might want to refer to the <currents.html currents>
% reference page.

x = linspace(-50,50,100);
y = linspace(-20,120,120);
[X,Y] = meshgrid(x,y); % Define a meshgrided domain
R = 150; % Tokamak's major radius

plasma = currentGaussian(0,60,1,4);
divertor = currentWire(0,-10,0.5,plasma); % Divertor current depends on plasma

%% Aggregate Field Expressions
% Each of the defined current holds three function handles: the two
% components of the magnetic field they generate, and the associated
% poloidal magnetic flux function, often refered to as $\psi$. To get an
% overview of the configuration, we build function handles that are the sum
% of these properties for both currents. We also build a handle returning
% the intensity of the magnetic field. Note that the handle computing the
% flux function requires a major radius as input parameter, such that
% currents themselves are independent of this geometrical parameter.

% Components of the total magnetic field
bx = @(x,y) plasma.magFieldX(x,y) + divertor.magFieldX(x,y);
by = @(x,y) plasma.magFieldY(x,y) + divertor.magFieldY(x,y);
% Intensity of the total magnetic field
b  = @(x,y) hypot(bx(x,y),by(x,y));
% Total flux function. Note the requirement for a major radius, r.
flx= @(x,y,r) plasma.fluxFx(x,y,r) + divertor.fluxFx(x,y,r);

%% Plot the Divertor
% Plots of the magnetic field and flux function can be performed using the
% new function handles. A lighter grid is defined so that the quiver plot
% isn't too hard to read.

% Define a "light" meshgrid
step = 6;
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

figure('Position',[10 10 968 420])
subplot(1,2,1)
quiver(lX,lY,bx(lX,lY),by(lX,lY),2)
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Magnetic Field','Interpreter','latex')
axis image
subplot(1,2,2)
contourf(X,Y,flx(X,Y,R),40,'EdgeColor','none')
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Poloidal Flux, $\psi$','Interpreter','latex')
colorbar
axis image

%% Going Further
% The previous example showed how magnetic configurations could be
% generated easily. However, one might be interested in computing specific
% properties of such a configuration (for example, x-point locations,
% triangularity, and so on), which isn't a functionality that is easily
% provided by limiting ouselves to the use of currents. In the
% <configDivertor.html next demonstration>, we introduce a magnetic
% configuration class, |mConf|, which provides such basic functionalities.

displayEndOfDemoMessage(mfilename)