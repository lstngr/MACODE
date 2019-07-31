%% NEGTRIDOUBLE     Full double x-point negative triangular configuration
% YEAYEAYEA

%% Define domain, currents, configuration and plot
% Like previously

Lx = 660; Ly = 880;
nx = 330; ny = 440;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

iPlasma = 11.42857142857143;
sgmPlasma = 90/sqrt(2);
propDiv = 3.91723956295538;
propSha = -7.0;

plasma   = currentGaussian(Lx/2,530,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire(Lx/2-119.79332102066471,-160,propDiv,plasma);
divertor2= currentWire(Lx/2+119.79332102066471,-160,propDiv,plasma);
divertor3= currentWire(Lx/2,-210,propSha,plasma);

clear config
config = mConf(R, [plasma,divertor,divertor2,divertor3]);
config.simArea = [0,Lx;0,Ly];
config.commit(1);

figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image