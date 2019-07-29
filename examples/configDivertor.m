%% MAGNCONFIGURATION     Create a sample magnetic configuration object
%   MAGNCONFIGURATION can be used to create a sample MCONF object, and
%   demonstrate its basic capabilities.

%% Create currents
% Place currents
x = linspace(-50,50,100);
y = linspace(-20,120,120);
[X,Y] = meshgrid(x,y);
R = 150;

plasma = currentGaussian(0,60,1,4);
divertor = currentWire(0,-10,0.5,plasma);

%% Create a magnetic configuration
% Group currents and blabla
config = mConf(R, [plasma,divertor]);

%% Plots the resulting configuration
% Same as with currents, watch
step = 6;
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

figure
subplot(1,2,1)
quiver(lX,lY,config.magFieldX(lX,lY),config.magFieldY(lX,lY),2)
axis image
subplot(1,2,2)
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
axis image