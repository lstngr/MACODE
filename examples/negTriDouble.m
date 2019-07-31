%% NEGTRIDOUBLE     Full double x-point negative triangular configuration
% YEAYEAYEA

%% Define domain, currents, configuration and plot
% Like previously

Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

xplasma = 0.4;
divertx = 0.375 + xplasma;

iPlasma = 100;
sgmPlasma = 15;
propDiv = 1.2;

plasma   = currentGaussian(xplasma*Lx,1/2*Ly,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire(divertx*Lx,-1/5*Ly,propDiv,plasma);
divertor2= currentWire(divertx*Lx,Ly+1/5*Ly,propDiv,plasma);

clear config
config = mConf(R, [plasma,divertor,divertor2]);
config.simArea = [0,Lx;0,Ly];
config.commit(2);

figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image

%% Compute safety factor
[q,p,qavg,pavg] = config.safetyFactor([500,400],30);
figure
hold on
ax = plot(p,q);
line(repmat(config.separatrixPsi(1),1,2),ylim,'LineStyle','--','Color','k')
line(repmat(config.psi95,1,2),ylim,'LineStyle','--','Color','r')
hold off
figure
hold on
plot(pavg,qavg)
line(repmat(config.separatrixPsi(1),1,2),ylim,'LineStyle','--','Color','k')
line(repmat(config.psi95,1,2),ylim,'LineStyle','--','Color','r')
hold off