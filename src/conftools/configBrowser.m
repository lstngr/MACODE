function activeConf = configBrowser(obj,varargin)

assert(isa(obj,'mConf'))
nobj = numel(obj);
assert(nobj>1);

defaultScanP = linspace(-1,1,nobj);
defaultNTry = 1;
defaultDelete = true;

p = inputParser;
addOptional(p,'ScanP',defaultScanP,@(x)validateattributes(x,{'double'},{'vector','increasing','numel',nobj}))
addOptional(p,'Retries',defaultNTry,@(x)validateattributes(x,{'double'},{'positive','scalar','integer'}))
addParameter(p,'DeleteSample',defaultDelete,@(x)validateattributes(x,{'logical'},{'scalar'}))
parse(p,varargin{:})

pval = p.Results.ScanP;
ntry = p.Results.Retries;
deleteSamples = p.Results.DeleteSample;

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

% Need dirty trick to access current.c, explained at:
% https://undocumentedmatlab.com/blog/accessing-private-object-properties
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
% Delete sampled configurations that were passed.
oldObj = obj;
obj = copy(obj(1));
if deleteSamples
    delete(oldObj);
end
clear oldObj;

% Initial scan parameter
scanp = 0;
oldScanp = 0;

% Initialize command panel
panelF = figure('Position',[30,50,250,400]);
statetxt = uicontrol('Style','text','String','Ready',...
    'Position',[50,350,150,30],'Fontsize',16,'Parent',panelF);
pslider = uicontrol('Style','slider','SliderStep',[0.05,0.2],...
    'Position',[50,300,150,30],'Min',min(pval),'Max',max(pval),'Enable','off',...
    'Callback',@setScanp,'Parent',panelF);
addlistener(pslider, 'Value', 'PostSet', @(src,evnt)setScanp(pslider));
retryBt = uicontrol('Style','pushbutton','String','Re-commit',...
    'Position',[50,250,150,30],'Enable','off','Parent',panelF,'Callback',@retryCommit);
resetBt = uicontrol('Style','pushbutton','String','Reset','Max',0.5*(min(pval)+max(pval)),...
    'Position',[50,200,150,30],'Enable','off','Parent',panelF,'Callback',@setScanp);
updateBt =uicontrol('Style','pushbutton','String','Update','Value',0,'Min',0,'Max',0,...
    'Position',[50,150,150,30],'Enable','off','Parent',panelF,'Callback',@updateConfig);
pvaltxt = uicontrol('Style','text','String',['p=',num2str(scanp)],...
    'Position',[50,100,150,30],'Fontsize',16,'Parent',panelF);
trigtxt = annotation(gcf,'textbox','String',...
    {'$\delta_{\phantom{upper}}=$','$\delta_{upper}=$','$\delta_{lower}=$'},...
    'Units','pixels','Position',[50,30,150,60],'Fontsize',12,'Interpreter','latex');

% Initialize plot figure
plotF = figure('Position',[290,50,650,600],'DeleteFcn',@removeTV);
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
activeConf = obj;

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
            if obj.checkCommit==commitState.Done
                [m,u,l] = triangularity(obj);
                trigtxt.String = {['$\delta_{\phantom{upper}}=',num2str(m),'$'],...
                    ['$\delta_{upper}=',num2str(u),'$'],...
                    ['$\delta_{lower}=',num2str(l),'$']};
            end
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
        oldScanp = scanp;
    end

    function retryCommit(~,~)
        pslider.Value = oldScanp;
        setScanp(pslider);
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
        contourf(ax,X,Y,obj.fluxFx(X,Y),40,'EdgeColor','none')
        rectangle('Parent',ax,'Position',[sa(1),sa(2),sa(3)-sa(1),sa(4)-sa(2)],'LineStyle','--')
        for iicur=1:ncur
            scatter(ax,obj.currents(iicur).x,obj.currents(iicur).y,75,...
                'o','filled','MarkerFaceColor',cols(iicur,:))
        end
        scatter(ax,obj.xpoints(:,1),obj.xpoints(:,2),40,...
                'o','filled','MarkerFaceColor','w')
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

    function removeTV(src,~)
        lockPanel(true);
        statetxt.String = 'DELETED';
        delete(src);
    end

end