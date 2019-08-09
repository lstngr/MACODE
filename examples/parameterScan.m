%% Creating mConf Parameter Scans
% The creation of individual configurations was covered in TODO(link). We
% now present a tool allowing one to progressively transition from a
% configuration to the other.
%
% This might be interesting in order study how different properties of a
% configuration respond to change in the divertor current configuration.

%% Creating Samples
% In order to easily create the aforementioned transitions, the
% <matlab:help('configBrowser') configBrowser> function may be used. This
% function takes an array of configurations as input, and maps it to a
% one-dimensional parameter, called |p|.
%
% Consider the simple scenario of the simple divertor configuration
% TODO(link), and assume we progressively want to increase the current running
% through the divertor coil

% Current values we want to browse
cmin = 0.1; cmax = 1.0;

% Limits for the plot
simLims = [-50,50;-35,120];

% Currents
plasma = currentGaussian(0,60,1,4);
plasma.isPlasma = true;
divertor1 = currentWire(0,-10,cmin,plasma);
divertor2 = currentWire(0,-10,cmax,plasma);

% Configuration objects
R = 150; % Major radius
conf1 = mConf(R,[plasma,divertor1]); conf1.simArea = simLims;
conf2 = mConf(R,[plasma,divertor2]); conf2.simArea = simLims;

%% Plotting a Simple Scan
% These two configurations can then be passed to |configBrowser|. This
% results in two windows opening, which allow browsing intermediate values
% of the plasma current. These intermediate values are computed by _linear
% interpolation_.
%
% You may want to query the properties of the displayed configuration,
% which can be achieved by using the handle returned by the function, in
% the case below, the |config| variable.
%
% Note that by default, all sample configurations you provide to
% |configBrowser| are _deleted_. We disabled this behavior by properly
% setting the |DeleteSample| to false.
%
% To control the output configuration, use the slider to select a decent
% parameter value, and press the 'Update' button. If your commit fails, you
% can retry it by pressing either the 'Re-commit' or 'Update' buttons.
% 'Re-commit' discards the slider value if it was changed since the last
% try to update the figure. The 'Reset' button resets the slider to it's
% median position without updating the configuration.
%
% Upon a commit, you can also see triangularitis of your configuration are
% computed on the control window. If you close the display window, the
% configuration panel will be locked.

config = configBrowser([conf1,conf2],'DeleteSample',false);

%% Controlling the Parameter Space
% You may want to have more control over how the parameter space is chosen.
% Right now, the default range is used, and |p| (or |scanp|) ranges from -1
% to 1. A second argument can be provided. In our case, we might find more
% relevant to simply use the current running through the divertor.
scanp  = [cmin,cmax];
% Yet another parameter could be given be passed after |scanp|, documented
% as |r| for "retries" in the |configBrowser|'s help. It simply controls
% the number of attempts to find x-points at every commit (this is no
% different than the |ntri| parameter of |mConf/commit|).
% The default being 5 tries, we might want to lower it to, say 3, to obtain
% quicker commits.
tries = 3;
config = configBrowser([conf1,conf2],scanp,tries);

%%
% As mentionned above, |config| can be used to query the properties of the
% configuration being drawn, where as the sample configurations passed to
% |configBrowser| as primary parameter are deleted.

disp('Plotted configuration''s x-point:')
disp(config.xpoints)
fprintf('\n')
disp('Sampled configurations were deleted:')
disp('conf1 = ')
disp(conf1)
disp('conf2 = ')
disp(conf2)

%% Application: Scanning Triangularity in a Double Null Configuration
% A configuration browser can go through as many configurations as desired,
% as long as the linear interpolation between those produces a "reasonable"
% magnetic structure.
%
% In the code below, we explore how a double null configuration's
% triangularity can be scanned using two divertor coils. Instead of
% modifying the coil's current, we move them (and the plasma current)
% horizontally to demonstrate how the |configBrowser| handles such setups.
%
% Note the use of a for-loop to build a configuration array. It is
% initialized using the handle's class |empty| method,
%
%   confs = mConf.empty(numel(scanp),0);
%
% which must be passed (at least) on zero valued dimension.

% Define scanp values associated with various current displacements
scanp = [-1,-0.57,0,0.57,1];
% Current displacements (in units of Lx)
xdiv  = [0.2,0.3,0.5,0.7,0.8];
xplsm = [0.75,0.56,0.5,0.44,0.25];

% Domain definition
Lx = 600; Ly = 800;
nx = 300; ny = 400;
x  = linspace(0,Lx,nx);
y  = linspace(0,Ly,ny);
[X,Y] = meshgrid(x,y);
R = 700;

% Fixed currents for plasma and coils
iPlasma = 21.25;
sgmPlasma = 85;
propDiv = 1.2;

% Declare an empty configuration array
confs = mConf.empty(numel(scanp),0);

% Initialize all configurations
for iconf=1:numel(scanp)
    xplasma = xplsm(iconf);
    divertx = xdiv(iconf);
    
    plasma   = currentGaussian(xplasma*Lx,1/2*Ly,iPlasma,sgmPlasma);
    plasma.isPlasma = true;
    divertor = currentWire(divertx*Lx,-1/5*Ly,propDiv,plasma);
    % Note that one divertor has slightly higher current than the other.
    divertor2= currentWire(1.05*divertx*Lx,Ly+1/5*Ly,propDiv,plasma);
    
    confs(iconf) = mConf(R, [plasma,divertor,divertor2]);
    confs(iconf).simArea = [0,Lx;0,Ly];
end

% Plots configurations, we use a margin of 10 tries to detect x-points
config = configBrowser(confs,scanp,10);