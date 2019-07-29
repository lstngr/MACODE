%% SIMPLEDIVERTOR    Work with current flux functions
% The flux function is blabla, defined as $B=\nabla\times\psi$,
%
% $$B_x = \frac{1}{R}\frac{\partial\psi}{\partial y}$$
% $$B_y =-\frac{1}{R}\frac{\partial\psi}{\partial x}$$
%
% where $R$ the tokamak major radius

%% Define domain and place currents
% Prepare coordinates, setup plasma current and divertor coil.

x = linspace(-50,50,100);
y = linspace(-20,120,120);
[X,Y] = meshgrid(x,y);
R = 150;

plasma = currentGaussian(0,60,1,4);
divertor = currentWire(0,-10,0.5,plasma);

%% Compute the total magnetic field and psi
% Prepare total magnetic field and flux function
bx = @(x,y) plasma.magFieldX(x,y) + divertor.magFieldX(x,y);
by = @(x,y) plasma.magFieldY(x,y) + divertor.magFieldY(x,y);
b  = @(x,y) hypot(bx(x,y),by(x,y));
flx= @(x,y,r) plasma.FluxFx(x,y,r) + divertor.FluxFx(x,y,r);

%% Plots the configuration
% Use a lighter grid for convenience

step = 6;
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

figure
subplot(1,2,1)
quiver(lX,lY,bx(lX,lY),by(lX,lY),2)
axis image
subplot(1,2,2)
contourf(X,Y,flx(X,Y,R),40,'EdgeColor','none')
axis image