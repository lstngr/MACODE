%% LARGECONFIGURATION   Yeah
% Cool stuff here

%% Define domain
% Blabla
Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

%% Create currents
% Place currents
iPlasma = 100;
sgmPlasma = 15;
propDiv = 1.2;

plasma   = currentGaussian(Lx/2,1/2*Ly,iPlasma,sgmPlasma);
divertor = currentWire(Lx/2,-1/5*Ly,propDiv,plasma);
divertor2= currentWire(Lx/2,Ly+1/5*Ly,propDiv,plasma);

%% Create a magnetic configuration
% Group currents and blabla
clear config
config = mConf(R, [plasma,divertor,divertor2]);
config.commit(2,6);

figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
hold off
axis image