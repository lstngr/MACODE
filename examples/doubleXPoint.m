%% Magnetic Configuration with Many X-Points
% The mConf class is able to handle magnetic configurations displaying many
% x-points if the user requires it. We show how different parameters of a
% commit can influence their detection.

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
plasma.isPlasma = true;
divertor = currentWire(Lx/2,-1/5*Ly,propDiv,plasma);
divertor2= currentWire(Lx/2,Ly+1/5*Ly,propDiv,plasma);

%%
% A magnetic configuration is instanciated with these currents.
clear config
config = mConf(R, [plasma,divertor,divertor2]);
config.simArea = [0,Lx;0,Ly];

%% Default Behavior
% By default, when commiting a configuration, the mConf class will pick 10
% random starting locations from which a numerical solver starts to find an
% x-point. Such a point is defined as a zero-magnetic field point located
% on a saddle point of the flux function.
%
% If the x-point is prominent enough, fewer trials are usually sufficient.

commit(config);
figure
hold on
contourf(X,Y,config.fluxFx(X,Y),40,'EdgeColor','none')
contour(X,Y,config.fluxFx(X,Y),'-k','LevelList',config.separatrixPsi)
scatter(config.xpoints(:,1),config.xpoints(:,2),40,'ro','filled')
scatter(config.corePosition(1),config.corePosition(2),40,'go','filled')
hold off
axis image

%% Common problems
% *Bad Simulation Limits* The configuration's |simArea| is badly set, which
% happens most of the time when the default settings are used. In the
% example below, the default behavior from mConf selects only a thin slice
% of the domain surrounding the currents.

% mConf falls back to default behavior when simArea is empty.
config.simArea = [];
fprintf('xlim = [%f %f]\nylim = [%f %f]\n',config.simArea')
try 
    % Need to force commit since no current changes
    commit(config,'Force',true);
catch ME
    % Print error and continue running
    fprintf('\nA weird (expected) error occured:\n')
    disp(getReport(ME,'basic'))
end

config.simArea = [0,Lx;0,Ly]; % Set area correctly for following code

%%
% *Bad Commit Parameters* You may have requested incompatible parameters.
% If you do not specify enough trials or x-points number, the mConf class
% won't detect them and cannot warn you about this issue.

commit(config,1,3,'Force',true) % Commit with many trials but return one x-point!
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

commit(config,2,1,'Force',true) % Enough x-point storage, too few tries
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
% domain (lies close to the |simArea| limits for example), the solver might
% need a large number of tries to spot it. Currently, no mechanism is
% implemented such that this problem might increase the commit time by a
% large amount!
%
% (Note: No example plots are generated since this part is too unreliable
% for the example's publication.)
