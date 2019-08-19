%% Define domain, currents, configuration and plot

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

latexParam = {'Interpreter','latex','Fontsize',16};

figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image

figure
hold on
sa = config.simArea;
rectangle('Position',[sa(1),sa(2),sa(3)-sa(1),sa(4)-sa(2)],'LineStyle','--')
cols = lines(length(config.currents)); idx = 1;
for cur=config.currents
    scatter(cur.x,cur.y,75,'o','filled','MarkerFaceColor',cols(idx,:))
    idx = idx + 1;
end
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image

%% Compute safety factor
sftyOptions = {'Normalize',true,'Units','psi','SkipFirst',true};
[q,p,qavg,pavg] = safetyFactor(config,30,[550,517],sftyOptions{:});
figure('Position',[10 10 1000 420])
subplot(1,2,1)
plot(p,q,'DisplayName',['\delta=',num2str(triangularity(config))]);
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$q=\frac{r}{RB_\theta}$',latexParam{:})
title('Local Safety Factor')
subplot(1,2,2)
plot(pavg,qavg,'DisplayName',['\delta=',num2str(triangularity(config))])
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$\langle q\rangle=\langle\frac{r}{RB_\theta}\rangle$',latexParam{:})
title('Average Safety Factor')

%% Compute magnetic shear
[q,p,qavg,pavg] = magShear(config,30,[550,517],sftyOptions{:});
figure('Position',[10 10 1000 420])
subplot(1,2,1)
plot(p,q,'DisplayName',['\delta=',num2str(triangularity(config))]);
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$s=\frac{r}{q}\frac{\mathrm{d}q}{\mathrm{d}r}$',latexParam{:})
title('Local Magnetic Shear')
subplot(1,2,2)
plot(pavg,qavg,'DisplayName',['\delta=',num2str(triangularity(config))])
xlabel('$\rho=\sqrt{\frac{\psi-\psi_0}{\psi_{\mathrm{LCFS}}-\psi_0}}$',latexParam{:})
ylabel('$\langle s\rangle=\langle\frac{r}{q}\frac{\mathrm{d}q}{\mathrm{d}r}\rangle$',latexParam{:})
title('Average Magnetic Shear')