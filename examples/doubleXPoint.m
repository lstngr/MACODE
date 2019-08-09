%% Magnetic Configuration with Many X-Points
% The <matlab:doc('mConf') mConf> class is able to handle magnetic
% configurations displaying many x-points if the user requires it. We show
% how different parameters of a commit can influence their detection.

%% Geometry Setup
% We start by defining a region of interest and choose a major radius, |R|.
Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

%%
% A plasma current is placed at the center of the domain, and two divertor
% coils are positionned vertically above and below the plasma.
iPlasma = 100;
sgmPlasma = 15;
propDiv = 1.2;

plasma   = currentGaussian(Lx/2,Ly/2,iPlasma,sgmPlasma);
divertor = currentWire(Lx/2,-1/5*Ly,propDiv,plasma);
divertor2= currentWire(Lx/2,Ly+1/5*Ly,propDiv,plasma);

% We flag the plasma current for the upcoming commit
plasma.isPlasma = true;

%%
% A magnetic configuration is instanciated with these currents.
config = mConf( R, [plasma,divertor,divertor2] );
config.simArea = [0,Lx;0,Ly];

%% Default Behavior
% By default, when commiting a configuration, the mConf class will pick 10
% random starting locations from which a numerical solver starts to find an
% x-point. Such a point is defined as a zero-magnetic field point located
% on a saddle point of the flux function.
%
% If the x-point is prominent enough, fewer trials are usually sufficient.
% Here, for example, we can speed up the process by limiting oursleves to
% three trials per null points.

commit(config,2,6);

figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image

%% Common problems
% *Bad Simulation Limits* The configuration's <matlab:doc('mConf/simArea')
% mConf/simArea> is badly set, which happens most of the time when the
% default settings are used. In the example below, the default behavior
% from mConf selects only a thin slice of the domain surrounding the
% currents.
%
% Multiple warnings are issued to the user when problematic boundaries are
% found.

% mConf falls back to default behavior when simArea is empty.
config.simArea = [];
% Warnings are issued when accessing config.simArea
fprintf('xlim = [%f %f]\nylim = [%f %f]\n',config.simArea')

%%
% In the above case, the limits will be set automatically to plausible
% values. Your configurations might however not be so forgiving. The code
% below may produce an error depending on its mood.
try 
    % Need to force commit since no magnetic structure changes occured
    commit(config,2,2,'Force',true);
catch ME
    % Print error and continue running
    fprintf('\nAn (expected) error occured:\n')
    disp(getReport(ME,'basic'))
    if ~isempty(ME.cause)
        disp(getReport(ME.cause{1},'basic'))
    end
end

config.simArea = [0,Lx;0,Ly]; % Set area correctly for following code

%%
% *Bad Commit Parameters* You may have requested incompatible parameters.
% If you do not specify enough trials or x-points number, the mConf class
% won't detect them and cannot warn you about this issue.

% Commit with many trials but return one x-point!
commit(config,1,3,'Force',true)

figure
subplot(1,2,1)
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image
title('Too few X asked')

% Enough x-point storage, but too few tries
commit(config,2,1,'Force',true)
subplot(1,2,2)
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image
title('Too few solver tries')

%%
% *Weak X-Points* When an x-point is "excluded" compared to the rest of the
% domain (lies close to the <matlab:doc('mConf/simArea') mConf/simArea>
% limits for example), the solver might need a large number of tries to
% spot it. Currently, no mechanism is implemented such that this problem
% might increase the commit time by a large amount!
%
% (Note: No example plots are generated since this part is too unreliable
% for the example's publication.)

displayEndOfDemoMessage(mfilename)