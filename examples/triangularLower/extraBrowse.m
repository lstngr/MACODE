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

%% Negative triangular
scanp = -1;

xplasma = 0.5+0.1*scanp;
divertx = 0.5-0.25*scanp;
divertx2= 1.25-0.05*scanp;
divertx3= -0.25-0.05*scanp;
diverty2= 5/8+1/8*scanp;
diverty3= 5/8-1/8*scanp;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1-0.15*abs(scanp);
propDiv2= (-0.3-0.1*double(scanp<0))*abs(scanp);
propDiv3= (-0.4+0.1*double(scanp<0))*abs(scanp);

c1plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c1plasma.isPlasma = true;
c1divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c1plasma);
c1divertor2= currentWire(divertx2*Lx,diverty2*Ly,propDiv2,c1plasma);
c1divertor3= currentWire(divertx3*Lx,diverty3*Ly,propDiv3,c1plasma);

clear config1
config1 = mConf(R, [c1plasma,c1divertor,c1divertor2,c1divertor3]);
config1.simArea = [0,Lx;0,Ly];

%% SN
scanp = 0;

xplasma = 0.5+0.1*scanp;
divertx = 0.5-0.25*scanp;
divertx2= 1.25-0.05*scanp;
divertx3= -0.25-0.05*scanp;
diverty2= 5/8+1/8*scanp;
diverty3= 5/8-1/8*scanp;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1-0.15*abs(scanp);
propDiv2= (-0.3-0.1*double(scanp<0))*abs(scanp);
propDiv3= (-0.4+0.1*double(scanp<0))*abs(scanp);

c2plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c2plasma.isPlasma = true;
c2divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c2plasma);
c2divertor2= currentWire(divertx2*Lx,diverty2*Ly,propDiv2,c2plasma);
c2divertor3= currentWire(divertx3*Lx,diverty3*Ly,propDiv3,c2plasma);

clear config2
config2 = mConf(R, [c2plasma,c2divertor,c2divertor2,c2divertor3]);
config2.simArea = [0,Lx;0,Ly];

%% Positive triangular
scanp = 1;

xplasma = 0.5+0.1*scanp;
divertx = 0.5-0.25*scanp;
divertx2= 1.25-0.05*scanp;
divertx3= -0.25-0.05*scanp;
diverty2= 5/8+1/8*scanp;
diverty3= 5/8-1/8*scanp;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1-0.15*abs(scanp);
propDiv2= (-0.3-0.1*double(scanp<0))*abs(scanp);
propDiv3= (-0.4+0.1*double(scanp<0))*abs(scanp);

c3plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c3plasma.isPlasma = true;
c3divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c3plasma);
c3divertor2= currentWire(divertx2*Lx,diverty2*Ly,propDiv2,c3plasma);
c3divertor3= currentWire(divertx3*Lx,diverty3*Ly,propDiv3,c3plasma);

clear config3
config3 = mConf(R, [c3plasma,c3divertor,c3divertor2,c3divertor3]);
config3.simArea = [0,Lx;0,Ly];

%% Browse configurations
configBrowser([config1,config2,config3],-1:1,2);
clear config2 config3

% Properties of the displayed configuration can be queried from the
% 'config' variable. The configBrowser function modifies the config1
% handle.