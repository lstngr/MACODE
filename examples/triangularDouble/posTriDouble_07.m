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

xplasma = 0.25;
divertx = 0.55 + xplasma;

iPlasma = 20;
sgmPlasma = 80;
propDiv = 1.2;

plasma   = currentGaussian((1-xplasma)*Lx,1/2*Ly,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire((1-divertx)*Lx,-1/5*Ly,propDiv,plasma);
divertor2= currentWire((1-divertx)*Lx,Ly+1/5*Ly,propDiv,plasma);

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
sftyOptions = {'Normalize',true,'Units','psi','SkipFirst',true};
[q,p,qavg,pavg] = safetyFactor(config,30,[600,400],sftyOptions{:});
figure('Name','Safety Factor (+0.7)','NumberTitle','off',...
    'FileName','SF+0.7.fig','Position',[10 10 1000 420])
subplot(1,2,1)
plot(p,q,'DisplayName','\delta=+0.7');
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$q=\frac{r}{RB_\theta}$',latexParam{:})
title('Local Safety Factor')
subplot(1,2,2)
plot(pavg,qavg,'DisplayName','\delta=+0.7')
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$\langle q\rangle=\langle\frac{r}{RB_\theta}\rangle$',latexParam{:})
title('Average Safety Factor')

%% Compute magnetic shear
[q,p,qavg,pavg] = magShear(config,30,[600,400],sftyOptions{:});
figure('Name','Magnetic Shear (+0.7)','NumberTitle','off',...
    'FileName','MS+0.7.fig','Position',[10 10 1000 420])
subplot(1,2,1)
plot(p,q,'DisplayName','\delta=+0.7');
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$s=\frac{r}{q}\frac{\mathrm{d}q}{\mathrm{d}r}$',latexParam{:})
title('Local Magnetic Shear')
subplot(1,2,2)
plot(pavg,qavg,'DisplayName','\delta=+0.7')
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$\langle s\rangle=\langle\frac{r}{q}\frac{\mathrm{d}q}{\mathrm{d}r}\rangle$',latexParam{:})
title('Average Magnetic Shear')