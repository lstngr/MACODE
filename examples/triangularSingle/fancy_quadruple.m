function fancy_quadruple

Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

scanp = 0.0;

xplasma = 0.5 + 0.05*scanp; %0.4
divertx = 0.5 - 0.25*scanp;% 0.3 + xplasma;
divertx2= 1.2; %0.75 + xplasma;
divertx3= divertx;
divertx4= -0.2; %xplasma-0.65;
hxpt = 180;

iPlasma = 14.2857;
sgmPlasma = 70.71;
propDiv = 1.0;
propDiv2= double(scanp<0)*abs(scanp)*-0.55+double(scanp>0)*abs(scanp)*0.1;
propDiv3= 0.55*abs(scanp);
propDiv4= double(scanp<0)*abs(scanp)*0.1-double(scanp>0)*abs(scanp)*0.55;

plasma   = currentGaussian(xplasma*Lx,5/8*Ly,iPlasma,sgmPlasma);
plasma.isPlasma = true;
divertor = currentWire(divertx*Lx,2*hxpt-5/8*Ly,propDiv,plasma);
divertor2= currentWire(divertx2*Lx,5/8*Ly,propDiv2,plasma);
divertor3= currentWire(divertx3*Lx,Ly-(2*hxpt-5/8*Ly),propDiv3,plasma);
divertor4= currentWire(divertx4*Lx,5/8*Ly,propDiv4,plasma);

config = mConf(R, [plasma,divertor,divertor2,divertor3,divertor4]);
config.simArea = [0,Lx;0,Ly];
config.commit(1,1)

F = figure;
set(F,'Position',[50 50 560 693])
resetButton = uicontrol('Parent',F,'String','scanp=0','Max',0,'Min',0,...
    'Callback',@configUpdate);
retryButton = uicontrol('Parent',F,'String','Re-commit','Max',0,'Min',0,...
    'Position',[200 20 160 20],'Callback',@retryCommit);
sld = uicontrol('Parent',F,'Style', 'slider',...
        'Min',-1,'Max',1,'Value',0,...
        'Position', [400 20 120 20],...
        'SliderStep',[0.1,0.25],...
        'Callback', @configUpdate);
ax = axes;
drawPlot;

    function drawPlot
        sa = config.simArea;
        cla(ax)
        rectangle('Position',[sa(1),sa(2),sa(3)-sa(1),sa(4)-sa(2)],...
            'LineStyle','-','EdgeColor','b','Parent',ax)
        hold(ax,'on')
        cols = lines(length(config.currents)); idx = 1;
        for cur=config.currents
            scatter(ax,cur.x,cur.y,75,'o','filled','MarkerFaceColor',cols(idx,:))
            idx = idx + 1;
        end
        contour(ax,X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
        contour(ax,X,Y,config.fluxFx(X,Y),10,'--k')
        hold(ax,'off')
        axis(ax,'image')
        title(ax,['scanp=',num2str(scanp)])
    end

    function configUpdate(source,~)
        scanp = source.Value;
        sld.Value = scanp;
        
        xplasma = 0.5 + 0.05*scanp; %0.4
        divertx = 0.5 - 0.25*scanp;% 0.3 + xplasma;
        divertx2= 1.2; %0.75 + xplasma;
        divertx3= divertx;
        divertx4= -0.2; %xplasma-0.65;
        hxpt = 180;
        
        iPlasma = 14.2857;
        sgmPlasma = 70.71;
        propDiv = 1.0;
        propDiv2= double(scanp<0)*abs(scanp)*-0.55+double(scanp>0)*abs(scanp)*0.1;
        propDiv3= 0.55*abs(scanp);
        propDiv4= double(scanp<0)*abs(scanp)*0.1-double(scanp>0)*abs(scanp)*0.55;
        
        % Plasma update
        plasma.x = xplasma*Lx;
        plasma.y = 5/8*Ly;
        plasma.curr = iPlasma;
        plasma.sigma = sgmPlasma;
        % Divertor Update
        divertor.x = divertx*Lx;
        divertor.y = 2*hxpt-5/8*Ly;
        divertor.curr = propDiv;
        % Divertor2 update
        divertor2.x = divertx2*Lx;
        divertor2.y = 5/8*Ly;
        divertor2.curr = propDiv2;
        % Divertor3 update
        divertor3.x = divertx3*Lx;
        divertor3.y = Ly-(2*hxpt-5/8*Ly);
        divertor3.curr = propDiv3;
        % Divertor4 update
        divertor4.x = divertx4*Lx;
        divertor4.y = 5/8*Ly;
        divertor4.curr = propDiv4;
        % Commit new config
        title(ax,'WAIT')
        retryButton.Enable = 'off';
        resetButton.Enable = 'off';
        sld.Enable = 'off';
        drawnow;
        try
            config.commit(1,1)
        catch ME
            retryButton.Enable = 'on';
            resetButton.Enable = 'on';
            sld.Enable = 'on';
            drawPlot
            rethrow(ME);
        end
        retryButton.Enable = 'on';
        resetButton.Enable = 'on';
        sld.Enable = 'on';
        drawPlot
    end

    function retryCommit(~,~)
        % Commit config again
        title(ax,'WAIT')
        retryButton.Enable = 'off';
        resetButton.Enable = 'off';
        sld.Enable = 'off';
        drawnow;
        try
            config.commit(1,1,'Force',true)
        catch ME
            retryButton.Enable = 'on';
            resetButton.Enable = 'on';
            sld.Enable = 'on';
            drawPlot
            rethrow(ME);
        end
        retryButton.Enable = 'on';
        resetButton.Enable = 'on';
        sld.Enable = 'on';
        drawPlot
    end

end