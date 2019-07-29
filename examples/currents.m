%% CURRENTS    Create sample currents
%   CURRENTS runs a little demo if you will

%% Creating a wire
% Hey, let's create a wire

position = [0,0];
currentVal = 1.0;

wire = currentWire( position(1), position(2), currentVal );

x = linspace(-2,2,8);
[X,Y] = meshgrid(x,x);

bx = wire.magFieldX(X,Y);
by = wire.magFieldY(X,Y);

figure
hold on
squiver(X,Y,bx,by,1.5,'Style',{'w','l'})
scatter(position(1), position(2), 200, 'r.')
hold off
axis image

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