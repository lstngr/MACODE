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

scanp = 1.0;

xplasma = 0.5 + 0.05*scanp; %0.4
divertx = 0.5 - 0.25*scanp;% 0.3 + xplasma;
divertx2= 1.2; %0.75 + xplasma;
divertx3= divertx;
divertx4= -0.2; %xplasma-0.65;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1.0;
propDiv2= double(scanp<0)*-0.55+double(scanp>0)*0.1;
propDiv3= 0.55*abs(scanp);
propDiv4= double(scanp<0)*0.1-double(scanp>0)*0.55;

plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,plasma);
divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,plasma);
divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,plasma);
divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,plasma);

clear config
config = mConf(R, [plasma,divertor,divertor2,divertor3,divertor4]);
config.simArea = [0,Lx;0,Ly];
config.commit(2);

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
[q,p,qavg,pavg] = safetyFactor(config,30,[500,400],sftyOptions{:});
figure('Name',['Safety Factor (p=',num2str(scanp),')'],'NumberTitle','off',...
    'FileName',['SF',num2str(scanp),'.fig'],'Position',[10 10 1000 420])
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
[q,p,qavg,pavg] = magShear(config,30,[500,400],sftyOptions{:});
figure('Name',['Magnetic Shear (p=',num2str(scanp),')'],'NumberTitle','off',...
    'FileName',['MS',num2str(scanp),'.fig'],'Position',[10 10 1000 420])
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