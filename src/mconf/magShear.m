function varargout = magShear(obj,npts,target,varargin)
% Check plasma is found
assert(~isempty(obj.corePosition))
% Parser defaults
defaultNormalize = true;
defaultSkipFirst = true;
allowedUnits = {'psi','dist'};
defaultUnits = allowedUnits{1};
% Input parser setup
p = inputParser;
addRequired(p,'npts',@(x)validateattributes(x,{'numeric'},{'integer','positive','scalar'}))
addRequired(p,'target',@(x)validateattributes(x,{'numeric'},{'row','numel',2}))
addParameter(p,'Normalize',defaultNormalize,@(x)validateattributes(x,{'logical'},{'scalar'}))
addParameter(p,'SkipFirst',defaultSkipFirst,@(x)validateattributes(x,{'logical'},{'scalar'}))
addParameter(p,'Units',defaultUnits,@ischar)
% Parse arguments
parse(p,npts,target,varargin{:})
npts = p.Results.npts;
targ = p.Results.target;
nrmd = p.Results.Normalize;
skpf = p.Results.SkipFirst;
% Validate remaining arguments
validUnits = validatestring(p.Results.Units,allowedUnits);
% Add a point if first one skipped
if skpf
    npts = npts + 1;
end
% Average and local safety factors are computed by two
% different (private) methods
nargoutchk(1,4)
[varargout{1:2}] = localMagShear(obj,npts,targ,nrmd,skpf,validUnits);
if nargout>2
    [varargout{3:4}] = avgMagShear(obj,npts,targ,nrmd,skpf,validUnits);
end
end

function [q,p] = localMagShear(obj,npts,target,nrmd,skpf,units)
assert(~isempty(obj.corePosition))
[s,p] = localSafetyFactor(obj,npts,target,nrmd,skpf,units);
theta  = atan((target(2)-obj.corePosition(2)) / ...
    (target(1)-obj.corePosition(1)));
target = [linspace(obj.corePosition(1),target(1),npts);...
    linspace(obj.corePosition(2),target(2),npts)];
r = hypot(target(1,:)-target(1,1),target(2,:)-target(2,1));
bPol = hypot(obj.magFieldX(target(1,:),target(2,:)),...
    obj.magFieldY(target(1,:),target(2,:)));
syms x y
symBPol = sqrt((obj.symMagFieldX)^2 + (obj.symMagFieldY)^2);
symdBPol= cos(theta)*diff(symBPol,'x') + sin(theta)*diff(symBPol,'y');
dbPoldr = double(subs(symdBPol,{'x','y'},{target(1,:),target(2,:)}));
dqdr = 1./(obj.R*bPol) - r./(obj.R*bPol.^2).*dbPoldr;
if skpf
    r = r(2:end);
    dqdr = dqdr(2:end);
end
q = r./s.*dqdr;
end

function [q,p] = avgMagShear(obj,npts,target,nrmd,skpf,units)
% TODO - Fix ugly signature in mConf.safetyFactor
assert(~isempty(obj.corePosition))
[~,p] = avgSafetyFactor(obj,npts,target,nrmd,skpf,units);
target = [linspace(obj.corePosition(1),target(1),npts);...
    linspace(obj.corePosition(2),target(2),npts)];
% Get closed contours on target points
contour_resolution = 0.75;
Lx = obj.simArea(1,2) - obj.simArea(1,1);
Ly = obj.simArea(2,2) - obj.simArea(2,1);
cx = linspace(obj.simArea(1,1), obj.simArea(1,2), ceil(Lx*contour_resolution));
cy = linspace(obj.simArea(2,1), obj.simArea(2,2), ceil(Ly*contour_resolution));
[CX,CY] = meshgrid(cx,cy);
targetPsi = obj.fluxFx(target(1,:),target(2,:));
C = contourc(cx,cy,obj.fluxFx(CX,CY),targetPsi);
S = extract_contourc(C);
S = removeOpenContours(S);
% Remove core contour if needed
psiCore = obj.fluxFx(obj.corePosition(1),obj.corePosition(2));
if S(1).level==psiCore && skpf
    S = S(2:end);
end
syms x y dx dy
symBPol = sqrt((obj.symMagFieldX)^2 + (obj.symMagFieldY)^2);
symdBPol= dx*diff(symBPol,'x') + dy*diff(symBPol,'y'); %#ok<NODEF>
fdBPol = matlabFunction(symdBPol,'Vars',{x,y,dx,dy});
% Compute average dqdr on all these contours
q = zeros(size(S));
for i=1:numel(S)
    ss = S(i);
    r = hypot(ss.x-target(1,1), ss.y-target(2,1));
    dx = ss.x-target(1,1);
    dy = ss.y-target(2,1);
    dd = hypot(dx,dy);
    dx = dx ./ dd; dy = dy ./ dd;
    bPol = hypot(obj.magFieldX(ss.x,ss.y),obj.magFieldY(ss.x,ss.y));
    dbPoldr = fdBPol(ss.x,ss.y,dx,dy);
    dqdr = 1./(obj.R*bPol)-r./(obj.R*bPol.^2).*dbPoldr;
    q(i) = mean( obj.R*bPol.*dqdr );
end
end