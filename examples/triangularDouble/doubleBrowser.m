scanp = [-1,-0.57,0,0.57,1];
xdiv  = [0.2,0.3,0.5,0.7,0.8];
xplsm = [0.75,0.56,0.5,0.44,0.25];

Lx = 600; Ly = 800;
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