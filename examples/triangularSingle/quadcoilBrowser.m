%% Define domain, currents, configuration and plot
% Like previously

Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

% Holds negative->zero->positive triangular configurations.
scanp = -1:1;
confs = mConf.empty(numel(scanp),0);

for ip=1:numel(scanp)
    xplasma = 0.5 + 0.05*scanp(ip);
    divertx = 0.5 - 0.25*scanp(ip);
    divertx2= 1.2;
    divertx3= divertx;
    divertx4= -0.2;
    hxpt = 180;
    
    iPlasma = 14.2857;
    sgmPlasma = 70.71;
    propDiv = 1.0+0.2*abs(scanp(ip));
    propDiv2= double(scanp(ip)<0)*abs(scanp(ip))*-0.65+double(scanp(ip)>0)*abs(scanp(ip))*0.1;
    propDiv3= 0.65*abs(scanp(ip));
    propDiv4= double(scanp(ip)<0)*abs(scanp(ip))*0.1-double(scanp(ip)>0)*abs(scanp(ip))*0.65;
    
    plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
    plasma.isPlasma = true;
    divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,plasma);
    divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,plasma);
    divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,plasma);
    divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,plasma);
    
    confs(ip) = mConf(R, [plasma,divertor,divertor2,divertor3,divertor4]);
    confs(ip).simArea = [0,Lx;0,Ly];
end


%% Browse configurations
config = configBrowser(confs,scanp,2);
clear confs

% Properties of the displayed configuration can be queried from the
% 'config' variable. The configBrowser function modifies the config1
% handle.