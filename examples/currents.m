%% CURRENTS    Create sample currents
% CURRENTS is a demonstration script showing how to intialize, use and
% delete objects deriving from the current class.

%% Creating a wire
% All wire objects inherit from the <matlab:doc('current') current> class,
% which is an <matlab:web(fullfile(docroot,'matlab/matlab_oop/abstract-classes-and-interfaces.html')) abstract class>
% (meaning you cannot create such an object directly). There is a simple
% reason for this: the distribution of such a current is not described by
% this object, and thus, its magnetic field expressions for example are
% undefined.
%
% A current, itself, inherits from a _handle_ class, meaning that a copy of
% a current instance will point to the same data, much like figure handles.
% The interested reader may refer to the MATLAB(R) documentation on
% <matlab:web(fullfile(docroot,'matlab/ref/handle-class.html')) handle classes>.
% Two classes implementing a concrete current distribution are available,
%
% * <matlab:doc('currentWire') currentWire>: A $\delta$ distributed
% current, on which we will first focus below.
% * <matlab:doc('currentGaussian') currentGaussian>: A current density
% following a 2D normal distribution.
%
% A wire current is described by its position and current intensity. Thus,
% it is initialized using the following signature,
%
%   wire = currentWire(x,y,c);
%
% where |x| and |y| are two scalars describing a 2D position, and |c| a
% current intensity.
% Once created, the |wire| variable provides the three relevant functions,
%
% * <matlab:doc('current/magFieldX') magFieldX>: $x$ component of the
% magnetic field.
% * <matlab:doc('current/magFieldY') magFieldY>: $y$ component of the
% magnetic field.
% * <matlab:doc('current/fluxFx') fluxFx>: Poloidal flux function
%
% With the code below, we create a current wire at the origin, with current
% unity, and plot generated magnetic field on a grid centered around the
% origin. Note that a positive current _enters the plane of the plot_.

position = [0,0]; % Current is located at the origin
currentVal = 1.0; % Current intensity is unity

% Call the currentWire constructor
wire = currentWire( position(1), position(2), currentVal );

% Create a meshgrid around the origin
x = linspace(-2,2,8);
[X,Y] = meshgrid(x,x);

% Compute the magnetic field components on this meshgrid
bx = wire.magFieldX(X,Y);
by = wire.magFieldY(X,Y);

% Plot the resulting magnetic field and the wire's position
figure
hold on
squiver(X,Y,bx,by,1.5,'Style',{'w','l'})
scatter(position(1), position(2), 200, 'r.')
hold off
xlabel('$x$','Interpreter','latex','Fontsize',14)
ylabel('$y$','Interpreter','latex','Fontsize',14)
title('Current wire''s magnetic field')
axis image
box on

%% Creating related wires
% Let's create a wire with bound current to 'wire'

child = currentWire( 1, 1, 0.5, wire );
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

fprintf('\nChanging the current of ''wire'':\n')
wire.curr = 2;
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

fprintf('\nChanging the current of ''child'':\n')
child.curr = 0.25;
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

%% Create a Gaussian wire
% We try a gaussian wire with small extension, and plot the magnitude of
% the magnetic field

sigma = 0.5;
gauss = currentGaussian(0,0,1,sigma);

x     = linspace(-4,4,50);
[X,Y] = meshgrid(x,x);
b = hypot(gauss.magFieldX(X,Y), gauss.magFieldY(X,Y));

figure
contourf(X,Y,b,40,'EdgeColor','none')
colormap hot
colorbar
axis image

%% Delete related currents
% Currents are handle classes (much like figures). They can thus be deleted
% by the user or any function/script told to do so.
% If a current is deleted, the parent-children relationships are updated,
% and the relative current of a child becomes absolute.

% Try delete wire
delete(wire)
disp(['wire is deleted. Child''s current: ',num2str(child.curr)])
disp('Child''s parent:')
child.Parent
% Changing child's current
child.curr = 10;
disp(['After update: ',num2str(child.curr)])