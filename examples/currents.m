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
% Often, one may want to define a current which's intensity is a fractional
% amount of another current defined earlier on. For example, one might to
% have a coil producing a strong magnetic field, and another current (or set
% of currents) with lower intensity to shape the magnetic field in certain
% regions.
% In this case, it can be handy to introduce a relationship between the two
% handles. Note this mechanism also allows the user to update the intensity
% of the primary current such that this modification is propagated to the
% coils that depend on it!
%
% This relationship is implemented in the current class as a Parent-Child
% model, a structure that is already found in <matlab:web(fullfile(docroot,'matlab/ref/axes-properties.html')) Axes Properties> and
% other graphical objects in MATLAB(R).
%
% To create a current that depends on the previously instantiated |wire|
% current, one passes it as a supplementary parameter to the constructor.
%
%   child = currentWire( x, y, c, wire );
%
% Now, |c| will behave as a proportionality factor between the two
% currents, that is, the current in |child| is half the current running
% through |wire|. To access this current outside the class, one uses the
% <matlab:doc('current/curr') curr> property.
%
%   child_current = child.curr;
%
% This property is a <matlab:web(fullfile(docroot,'matlab/matlab_oop/access-methods-for-dependent-properties.html')) dependent property>
% , meaning that it will be computed at the time it is requested by the
% class's associated |get| method.
%
% If a Parent current's intensity is changed, this change will be
% propagated to its children. However, if the child's current (or more
% exactly, its proportionality factor) is modified, only the child's
% current is affected, as illustrated below.

child = currentWire( 1, 1, 0.5, wire ); % Declare a child current with parent 'wire'

% Print the system's currents
fprintf('\nA primary current (wire) and its child:\n')
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

% Increasing the current in 'wire' affects the current in 'child'
fprintf('\nMultiplying the current of ''wire'' by two:\n')
wire.curr = 2;
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

% Lowering the child's current by two fold, only the child is affected
fprintf('\nReducing the current of ''child'' by a factor two:\n')
child.curr = 0.25;
disp(['wire.curr = ',num2str(wire.curr)])
disp(['child.curr= ',num2str(child.curr)])

%% Create a Gaussian wire
% We illustrate another type of current distribution,
% <matlab:doc('currentGaussian') currentGaussian>, which generates a
% Gaussian current distribution around the desired location. The extension
% of this distribution is controlled by providing the standard deviation,
% $\sigma$, to the constructor:
%
%   gauss = currentGaussian( x, y, c, sigma );
%
% The current distribution is given by
%
% $$j(\vec{x}) = c\exp{\frac{-(\vec{x}-\vec{x}_0)^2}{2\sigma^2}}$$
%
% Below, we instantiate such a current and plot the intensity of the
% magnetic field around the origin.

% Define a Gaussian current
sigma = 0.5;
gauss = currentGaussian(0,0,1,sigma);

% Provide a grid on which the norm of the magnetic field is computed
x     = linspace(-4,4,50);
[X,Y] = meshgrid(x,x);
b = hypot(gauss.magFieldX(X,Y), gauss.magFieldY(X,Y));

% Plot the norm of the magnetic field
figure
contourf(X,Y,b,40,'EdgeColor','none')
xlabel('$x$','Interpreter','latex','Fontsize',14)
ylabel('$y$','Interpreter','latex','Fontsize',14)
title('$\left|\vec{\boldmath{B}}\right|$ \textbf{for a Gaussian current}','Interpreter','latex')
colormap hot
colorbar
axis image
box on

%% Arrays of currents
% The current class also inherits from the <matlab:doc('matlab.mixin.Heterogeneous') matlab.mixin.Heterogeneous>
% class. This allows building arrays of current of different classes. In
% our case, for example, it allows building arrays of
%
% * Exclusively currentWire objects
% * Exclusively currentGaussian objects
% * A mix of currentWire and currentGaussian objects
%
% In the last case, MATLAB(R) looks for the last concrete class, call it
% |base|, from which both array classes inherit. If it finds one, the array
% will appear to be holding a collection |base| objects.
% In our project, the last common ancestor of both the currentWire and
% currentGaussian classes is an abstract current class. MATLAB(R) will thus
% construct an _heterogeneous array_ of both classes.
% Note that some syntax that might be taken for granted, such as calling a
% method over a whole array, like in |theArray(:).someMethod(...)|, might
% be disabled (see in particular <matlab:web(fullfile(docroot,'matlab/ref/matlab.mixin.heterogeneous-class.html#heterog_method_dispatching')) method dispatching>).

%% Delete related currents
% Since current behave as handles, the contents they point to might be
% deleted (again, much like figures). Remaining handles of this current
% will be reported as invalid by MATLAB(R).
% For independent currents, the operation is straightforward unless the
% handle is being used by some other component of the code (but this
% responsability falls on the user's shoulders).
% For currents that belong to a Parent-Children structure, the following
% convention is adopted:
%
% * If the current being deleted has children, the children become
% independent. Their current intensity before and after deletion of the
% parent remains unchanged.
% * If the current being deleted has no children but a parent, no special
% action is taken.
%
% In both cases, the Parent and Children handles of affected currents are
% updated, such that no invalid handle is left behind.
%
% In the example below, we delete the |wire| object, with only child
% current |child|, such that it becomes independent. We show that the
% parent reference has been deleted for the child variable, and that
% |child| now behaves like an independent current.

% Delete the primary current
delete(wire)
% Check that the current of the child is unaffected.
disp(['wire is deleted. Child''s current: ',num2str(child.curr)])
% Check that child's Parent has been removed
disp('child.Parent=')
disp(child.Parent)
% Try changing child's current. It behaves independently now.
child.curr = 10;
disp(['After update: ',num2str(child.curr)])