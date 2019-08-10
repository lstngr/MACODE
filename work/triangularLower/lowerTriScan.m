%% Define domain, currents, configuration and plot

Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

% Browse three possible configurations. Full negative, zero, full positive
% triangularity.
scanp = -1:1;
confs = mConf.empty(numel(scanp),0);

for ip=1:numel(scanp)

xplasma = 0.5+0.1*scanp(ip);
divertx = 0.5-0.25*scanp(ip);
divertx2= 1.25-0.05*scanp(ip);
divertx3= -0.25-0.05*scanp(ip);
diverty2= 5/8+1/8*scanp(ip);
diverty3= 5/8-1/8*scanp(ip);
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1-0.15*abs(scanp(ip));
propDiv2= (-0.3-0.1*double(scanp(ip)<0))*abs(scanp(ip));
propDiv3= (-0.4+0.1*double(scanp(ip)<0))*abs(scanp(ip));

plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,plasma);
divertor2= currentWire(divertx2*Lx,diverty2*Ly,propDiv2,plasma);
divertor3= currentWire(divertx3*Lx,diverty3*Ly,propDiv3,plasma);

confs(ip) = mConf(R, [plasma,divertor,divertor2,divertor3]);
confs(ip).simArea = [0,Lx;0,Ly];

end

%% Browse configurations
config = configBrowser(confs,scanp,2);
clear confs

% Properties of the displayed configuration can be queried from the
% 'config' variable. The configBrowser function modifies the config1
% handle.