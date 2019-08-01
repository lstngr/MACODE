function varargout = safetyFactor(obj,npts,target,varargin)
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
[varargout{1:2}] = localSafetyFactor(obj,npts,targ,nrmd,skpf,validUnits);
if nargout>2
    [varargout{3:4}] = avgSafetyFactor(obj,npts,targ,nrmd,skpf,validUnits);
end
end

function [q,p] = localSafetyFactor(obj,npts,target,nrmd,skpf,units)
% TODO - Fix ugly signature in mConf.safetyFactor
assert(~isempty(obj.corePosition))
assert(~isequal(target,obj.corePosition))
target = [linspace(obj.corePosition(1),target(1),npts);...
    linspace(obj.corePosition(2),target(2),npts)];
r = hypot(target(1,:)-target(1,1),target(2,:)-target(2,1));
bPol = hypot(obj.magFieldX(target(1,:),target(2,:)),...
    obj.magFieldY(target(1,:),target(2,:)));
q = (r/obj.R)./bPol;
if skpf
    target = target(:,2:end);
    r = r(2:end); q = q(2:end);
end
if strcmp(units,'dist')
    p = r;
    if nrmd
        assert(~isempty(obj.magR));
        p = p / obj.a;
    end
elseif strcmp(units,'psi')
    p = obj.fluxFx(target(1,:),target(2,:));
    if nrmd
        psiCore = obj.fluxFx(obj.corePosition(1), obj.corePosition(2));
        p = sqrt( (p-psiCore)/(obj.lcfsPsi-psiCore) );
    end
end
end

function [q,p] = avgSafetyFactor(obj,npts,target,nrmd,skpf,units)
% TODO - Fix ugly signature in mConf.safetyFactor
assert(~isempty(obj.corePosition))
target = [linspace(obj.corePosition(1),target(1),npts);...
    linspace(obj.corePosition(2),target(2),npts)];
% Get closed contours on target points
contour_resolution = 0.75;
Lx = obj.simArea(1,2) - obj.simArea(1,1);
Ly = obj.simArea(2,2) - obj.simArea(2,1);
cx = linspace(obj.simArea(1,1), obj.simArea(1,2), ceil(Lx*contour_resolution));
cy = linspace(obj.simArea(2,1), obj.simArea(2,2), ceil(Ly*contour_resolution));
[CX,CY] = meshgrid(cx,cy);
p = obj.fluxFx(target(1,:),target(2,:));
C = contourc(cx,cy,obj.fluxFx(CX,CY),p);
S = extract_contourc(C);
S = removeOpenContours(S);
% Remove core contour if needed
psiCore = obj.fluxFx(obj.corePosition(1),obj.corePosition(2));
if S(1).level==psiCore && skpf
    S = S(2:end);
end
% Compute average q on all these contours
q = zeros(size(S));
ravg = q;
p = [S.level];
for i=1:numel(S)
    ss = S(i);
    r = hypot(ss.x-target(1,1), ss.y-target(2,1));
    bPol = hypot(obj.magFieldX(ss.x,ss.y),obj.magFieldY(ss.x,ss.y));
    q(i) = mean(r./bPol)/obj.R;
    ravg(i) = mean(r);
end
if strcmp(units,'dist')
    p = ravg;
    if nrmd
        assert(~isempty(obj.magR));
        p = p / obj.a;
    end
elseif strcmp(units,'psi') && nrmd
    p = sqrt( (p-psiCore) / (obj.lcfsPsi-psiCore) );
end
end