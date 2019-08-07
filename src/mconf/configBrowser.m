function configBrowser(obj,varargin)

narginchk(1,3);
assert(isa(obj,'mConf'))
nobj = numel(obj);
assert(nobj>1);

pval = linspace(-1,1,nobj);
if nargin>1
    pval = varargin{1};
    validateattributes(pval,{'double'},{'numel',nobj,'>=',-1,'<=',1,'increasing'})
    assert(pval(1)==-1&&pval(end)==1)
end
ntry = 1;
if nargin==3
    validateattributes(varargin{2},{'double'},{'positive','scalar'})
    ntry = varargin{2};
end

% Configurations should have same major radius and simulated area
assert(isequal(obj.R))
simArea = arrayfun(@(x)reshape(x{1},1,[]),{obj.simArea},'UniformOutput',false);
assert(isequal(simArea{:}))

% Configurations should all be commitable
states = arrayfun(@checkCommit,obj,'UniformOutput',false);
states = [states{:}];
assert(all(states~=commitState.NotAvail))

% Configurations should have same amount of currents
ncur = arrayfun(@(x)numel(x{1}),{obj.currents});
assert(numel(unique(ncur))==1)
ncur = unique(ncur);

% Gather current locations and intensities
x = zeros(ncur,nobj);
y = x; c = x;
warning off MATLAB:structOnObject
for iconf=1:nobj
    x(:,iconf) = [obj(iconf).currents.x];
    y(:,iconf) = [obj(iconf).currents.y];
    for icur=1:ncur
        scur = struct(obj(iconf).currents(icur));
        c(icur,iconf) = scur.c;
    end
end
warning on MATLAB:structOnObject

% Keep working with first configuration that was passed
obj = obj(1);

% Initial scan parameter
scanp = 0;

% Initialize command panel
panelF = figure('Position',[30,50,250,450]);
statetxt = uicontrol('Style','text','String','Ready',...
    'Position',[50,410,150,30],'Fontsize',16,'Parent',panelF);
pslider = uicontrol('Style','slider','SliderStep',[0.05,0.2],...
    'Position',[50,360,150,30],'Min',-1,'Max',1,'Enable','off',...
    'Callback',@setScanp,'Parent',panelF);
retryBt = uicontrol('Style','pushbutton','String','Re-commit',...
    'Position',[50,310,150,30],'Enable','off','Parent',panelF,'Callback',@retryCommit);
resetBt = uicontrol('Style','pushbutton','String','Reset','Value',0,'Min',0,'Max',0,...
    'Position',[50,260,150,30],'Enable','off','Parent',panelF,'Callback',@setScanp);
updateBt =uicontrol('Style','pushbutton','String','Update','Value',0,'Min',0,'Max',0,...
    'Position',[50,210,150,30],'Enable','off','Parent',panelF,'Callback',@updateConfig);
pvaltxt = uicontrol('Style','text','String',['p=',num2str(scanp)],...
    'Position',[50,160,150,30],'Fontsize',16,'Parent',panelF);

% Initialize plot figure
plotF = figure('Position',[290,50,250,600]);
ax = axes('Parent',plotF);
axis(ax,'image');
xlabel(ax,'x');
ylabel(ax,'y');
nx = 300; ny = 400;
gx  = linspace(obj.simArea(1),obj.simArea(3),nx);
gy  = linspace(obj.simArea(2),obj.simArea(4),ny);
[X,Y] = meshgrid(gx,gy);

% Commit beautiful object
updateConfig;
drawnow;

    function lockPanel(toggle)
        if toggle
            statetxt.String = 'WAIT';
            pslider.Enable = 'off';
            retryBt.Enable = 'off';
            resetBt.Enable = 'off';
            updateBt.Enable= 'off';
        else
            statetxt.String = 'Ready';
            pslider.Enable = 'on';
            retryBt.Enable = 'on';
            resetBt.Enable = 'on';
            updateBt.Enable= 'on';
            pslider.Value = scanp;
        end
        drawnow;
    end

    function updateConfig(~,~)
        lockPanel(true);
        for iicur=1:ncur
            xr = interp1(pval,x(iicur,:),scanp);
            yr = interp1(pval,y(iicur,:),scanp);
            cr = interp1(pval,c(iicur,:),scanp);
            obj.currents(iicur).x = xr;
            obj.currents(iicur).y = yr;
            obj.currents(iicur).curr = cr;
        end
        try
            obj.commit(ntry,ntry,'Force',true);
        catch ME
            lockPanel(false);
            rethrow(ME)
        end
        drawConfig;
        lockPanel(false);
    end

    function retryCommit(~,~)
        lockPanel(true);
        try
            obj.commit(ntry,ntry,'Force',true);
        catch ME
            lockPanel(false);
            rethrow(ME)
        end
        drawConfig;
        lockPanel(false);
    end

    function drawConfig
        cla(ax);
        hold(ax,'on')
        cols = lines(ncur);
        sa = obj.simArea;
        rectangle('Parent',ax,'Position',[sa(1),sa(2),sa(3)-sa(1),sa(4)-sa(2)],'LineStyle','--')
        for iicur=1:ncur
            scatter(ax,obj.currents(iicur).x,obj.currents(iicur).y,75,...
                'o','filled','MarkerFaceColor',cols(iicur,:))
        end
        contour(ax,X,Y,obj.fluxFx(X,Y),'-k','LevelList',obj.separatrixPsi)
        contour(ax,X,Y,obj.fluxFx(X,Y),10,'--k')
        hold(ax,'off')
        axis(ax,'image')
        title(ax,['scanp=',num2str(scanp)])
        hold(ax,'off')
        drawnow;
    end

    function setScanp(src,~)
        scanp = src.Value;
        pslider.Value = scanp;
        pvaltxt.String = ['p=',num2str(scanp)];
        drawnow;
    end

end