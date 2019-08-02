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
plasma.isPlasma = true;
divertor = currentWire(0,-10,0.5,plasma);

%% Create a magnetic configuration
% Group currents and blabla
clear config
config = mConf(R, [plasma,divertor]);
config.simArea = [-50,50;-20,120];

%% Plots the resulting configuration
% Same as with currents, watch
step = 6;
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

figure
subplot(1,2,1)
quiver(lX,lY,config.magFieldX(lX,lY),config.magFieldY(lX,lY),2)
axis image
ax = subplot(1,2,2);
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
axis image

%% Commit the configuration
% Commiting runs a computation of x-point locations etc.
config.commit(1)
disp('X-Point location:')
disp(config.xpoints)

hold(ax,'on')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi,...
    'Parent',ax)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'or','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold(ax,'off')