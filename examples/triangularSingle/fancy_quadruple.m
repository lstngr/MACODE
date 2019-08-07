%% NEGTRIDOUBLE     Full double x-point negative triangular configuration
% YEAYEAYEA

%% Define domain, currents, configuration and plot
% Like previously

Lx = 800; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

%% Negative triangular
scanp = -1.0;

% Coefficients have been converted for larger domain
% if 0.5+0.1*scanp, then dist diff was 0.1*600=60, but now 60/800=0.075
% if -0.25-0.05*scanp, then dist to center was 0.75*600 = 450, but now
% 450/800=0.5675.
% Current need not change

xplasma = 0.5 + 0.0375*scanp;
divertx = 0.5 - 0.1875*scanp;
divertx2= 1.0250;
divertx3= divertx;
divertx4= -0.0250;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1.0;
propDiv2= double(scanp<0)*abs(scanp)*-0.55+double(scanp>0)*abs(scanp)*0.1;
propDiv3= 0.55*abs(scanp);
propDiv4= double(scanp<0)*abs(scanp)*0.1-double(scanp>0)*abs(scanp)*0.55;

c1plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c1plasma.isPlasma = true;
c1divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c1plasma);
c1divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,c1plasma);
c1divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,c1plasma);
c1divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,c1plasma);

clear config1
config1 = mConf(R, [c1plasma,c1divertor,c1divertor2,c1divertor3,c1divertor4]);
config1.simArea = [0,Lx;0,Ly];

%% SN
scanp = 0.0;

xplasma = 0.5 + 0.0375*scanp;
divertx = 0.5 - 0.1875*scanp;
divertx2= 1.0250;
divertx3= divertx;
divertx4= -0.0250;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1.0;
propDiv2= double(scanp<0)*abs(scanp)*-0.55+double(scanp>0)*abs(scanp)*0.1;
propDiv3= 0.55*abs(scanp);
propDiv4= double(scanp<0)*abs(scanp)*0.1-double(scanp>0)*abs(scanp)*0.55;

c2plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c2plasma.isPlasma = true;
c2divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c2plasma);
c2divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,c2plasma);
c2divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,c2plasma);
c2divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,c2plasma);

clear config2
config2 = mConf(R, [c2plasma,c2divertor,c2divertor2,c2divertor3,c2divertor4]);
config2.simArea = [0,Lx;0,Ly];

%% Positive triangular
scanp = 1.0;

xplasma = 0.5 + 0.0375*scanp;
divertx = 0.5 - 0.1875*scanp;
divertx2= 1.0250;
divertx3= divertx;
divertx4= -0.0250;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1.0;
propDiv2= double(scanp<0)*abs(scanp)*-0.55+double(scanp>0)*abs(scanp)*0.1;
propDiv3= 0.55*abs(scanp);
propDiv4= double(scanp<0)*abs(scanp)*0.1-double(scanp>0)*abs(scanp)*0.55;

c3plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
c3plasma.isPlasma = true;
c3divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,c3plasma);
c3divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,c3plasma);
c3divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,c3plasma);
c3divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,c3plasma);

clear config3
config3 = mConf(R, [c3plasma,c3divertor,c3divertor2,c3divertor3,c3divertor4]);
config3.simArea = [0,Lx;0,Ly];

%% Browse configurations
config = configBrowser([config1,config2,config3],-1:1,2);
clear config1 config2 config3

% Properties of the displayed configuration can be queried from the
% 'config' variable. The configBrowser function modifies the config1
% handle.