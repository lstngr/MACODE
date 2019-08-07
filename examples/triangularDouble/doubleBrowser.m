% Coefficients have been converted for larger domain
% if 0.5+0.1*scanp, then dist diff was 0.1*600=60, but now 60/800=0.075
% if -0.25-0.05*scanp, then dist to center was 0.75*600 = 450, but now
% 450/800=0.5675.
% Current need not change

scanp = [-1,-0.57,0,0.57,1];
xdiv  = [0.2750,0.3500,0.5,0.6500,0.7250];
xplsm = [0.6875,0.5450,0.5,0.4550,0.3125];

Lx = 800; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

iPlasma = 21.25;
sgmPlasma = 85;
propDiv = 1.2;

confs = mConf.empty(numel(scanp),0);

for iconf=1:numel(scanp)
    xplasma = xplsm(iconf);
    divertx = xdiv(iconf);
    
    plasma   = currentGaussian(xplasma*Lx,1/2*Ly,iPlasma,sgmPlasma);
    plasma.isPlasma = true;
    divertor = currentWire(divertx*Lx,-1/5*Ly,propDiv,plasma);
    divertor2= currentWire(1.05*divertx*Lx,Ly+1/5*Ly,propDiv,plasma);
    
    confs(iconf) = mConf(R, [plasma,divertor,divertor2]);
    confs(iconf).simArea = [0,Lx;0,Ly];
end
clear tmpConfig

config = configBrowser(confs,scanp,4);