% TODO - Could implement domain scaling
% TODO - Support multiple x-points

classdef mConf < matlab.mixin.SetGet & handle
    
    properties(GetAccess=public,SetAccess=private)
        R
        currents = currentWire.empty()
        xpoints
        separatrixPsi
        corePosition
    end
    
    properties
        simArea = []
    end
    
    properties(Dependent)
        psi95
        separatrixPsiTol
    end
    
    properties(Access=private)
        old_bx, old_by
    end
    
    methods
        function obj = mConf(R,varargin)
            narginchk(1,2);
            obj.R = R;
            if nargin==2
                obj.currents = varargin{1};
            end
        end
        
        function set.currents(obj,curs)
            assert(all(arrayfun(@(x)isa(x,'current'),curs) & isvalid(curs)),...
                'Expected argument to be a valid array of current handles.');
            % TODO - Check parent and children for non included currents in
            % curs!
            % TODO - Check if this line is really needed. Would also need
            % to consider ALL currents...
            assert(sum([curs(:).isPlasma])<2,'Expected at most one plasma current.')
            obj.currents = curs;
        end
        
        function commit(obj,varargin)
            % Commit configuration as it is loaded and compute stuff
            syms x y
            symBx = obj.symMagFieldX;
            symBy = obj.symMagFieldY;
            if( ~isempty(obj.old_bx) && ~isempty(obj.old_by) )
                if( isequal(obj.old_bx,symBx) && isequal(obj.old_by,symBy) )
                    % TODO - Allow user to force a commit
                    warning('magnetic structure unchanged since last commit.')
                    return;
                end
            end
            obj.xPointDetec(varargin{:});
            % Psi Separatrix
            obj.separatrixPsi = obj.fluxFx(obj.xpoints(:,1),...
                obj.xpoints(:,2));
            % Find core location
            obj.coreDetec;
            % Remember last commit's magnetic structure
            obj.old_bx  = symBx;
            obj.old_by  = symBy;
        end
        
        function bx = magFieldX(obj,x,y)
            bx = zeros(size(x));
            for cur=obj.currents
                bx = bx + cur.magFieldX(x,y);
            end
        end
        
        function by = magFieldY(obj,x,y)
            by = zeros(size(x));
            for cur=obj.currents
                by = by + cur.magFieldY(x,y);
            end
        end
        
        function gx = gradXFluxFx(obj,x,y)
            gx = -obj.R * obj.magFieldY(x,y);
        end
        
        function gy = gradYFluxFx(obj,x,y)
            gy =  obj.R * obj.magFieldX(x,y);
        end
        
        function p = fluxFx(obj,x,y)
            p = zeros(size(x));
            for cur=obj.currents
                p = p + cur.fluxFx(x,y,obj.R);
            end
        end
        
        function varargout = safetyFactor(obj,varargin)            
            % Check plasma is found
            assert(~isempty(obj.corePosition))
            % Parser defaults
            defaultNPts = 100;
            defaultTarget = obj.corePosition + [100,0]; % TODO, intelligent limit
            defaultNormalize = true;
            defaultSkipFirst = true;
            allowedUnits = {'psi','dist'};
            defaultUnits = allowedUnits{1};
            % Input parser setup
            p = inputParser;
            addOptional(p,'npts',defaultNPts,@(x)validateattributes(x,{'numeric'},{'integer','positive','scalar'}))
            addOptional(p,'target',defaultTarget,@(x)validateattributes(x,{'numeric'},{'row','numel',2}))
            addParameter(p,'Normalize',defaultNormalize,@(x)validateattributes(x,{'logical'},{'scalar'}))
            addParameter(p,'SkipFirst',defaultSkipFirst,@(x)validateattributes(x,{'logical'},{'scalar'}))
            addParameter(p,'Units',defaultUnits)
            % Parse arguments
            parse(p,varargin{:})
            npts = p.Results.npts;
            targ = p.Results.target;
            nrmd = p.Results.Normalize;
            skpf = p.Results.SkipFirst;
            % Validate remaining arguments
            validUnits = validatestring(p.Results.Units,allowedUnits);
            
            % Average and local safety factors are computed by two
            % different (private) methods
            narginchk(1,3)
            nargoutchk(1,4)
            [varargout{1:2}] = obj.localSafetyFactor(npts,targ,nrmd,skpf,validUnits);
            if nargout>2
                [varargout{3:4}] = obj.avgSafetyFactor(npts,targ,nrmd,skpf,validUnits);
            end
        end
        
        function f = symMagFieldX(obj)
            syms x y
            f = sym(0);
            for cur=obj.currents
                f = f + cur.magFieldX(x,y);
            end
        end
        
        function f = symMagFieldY(obj)
            syms x y
            f = sym(0);
            for cur=obj.currents
                f = f + cur.magFieldY(x,y);
            end
        end
        
        function f = symFluxFx(obj)
            syms x y
            f = sym(0);
            for cur=obj.currents
                f = f + cur.fluxFx(x,y,obj.R);
            end
        end
        
        function area = get.simArea(obj)
            if isempty(obj.simArea)
                area = [min( [obj.currents(:).x] ), ...
                             max( [obj.currents(:).x]);...
                             min( [obj.currents(:).y] ),...
                             max( [obj.currents(:).y] ) ];
                return;
            end
            area = obj.simArea;
        end
        
        function p = get.psi95(obj)
            assert(~isempty(obj.separatrixPsi));
            assert(~isempty(obj.corePosition));
            sp = unique(obj.separatrixPsi);
            cp = obj.fluxFx(obj.corePosition(1),obj.corePosition(2));
            p = cp + 0.95*(sp-cp);
        end
        
        function p = get.separatrixPsiTol(obj)
            % Return separatrix with numerical tolerance
            % TODO - Eventually add a custom tolerance parameter?
            p = uniquetol(obj.separatrixPsi,1e-10);
        end
        
    end
    
    methods(Access=private)
        
        function xPointDetec(obj,varargin)
            % Detect x points
            
            % Call signature
            %   xPointDetec, xpoints detected within the coils only
            %   xPointDetec(nxpt), returns at most nxpt (found within 10
            %   trials)
            %   xPointDetec(nxpt,ntrials), returns at most nxpt (found
            %   within ntrials trials)
            %   xPointDetec(guesses), finds x-points with initial guesses
            %   xPointDetec(...,'Limits',lims), 2x2 matrix with limits to
            %   consider.
            % In all cases, returned x-points are unique, and found via
            % vpasolve using randomized behavior.
            
            % Define default parameters
            defaultNXPoint = +Inf;
            defaultNTrials = 10;
            defaultGuesses = [];
            defaultLimits = obj.simArea;
            % Parse inputs
            p = inputParser;
            addOptional(p,'nxpt',defaultNXPoint,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addOptional(p,'ntri',defaultNTrials,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addOptional(p,'guesses',defaultGuesses,...
                @(x)validateattributes(x,{'numeric'},{'2d','ncols',2}));
            addParameter(p,'Limits',defaultLimits,...
                @(x)validateattributes(x,{'numeric'},{'2d','square','ncols',2}));
            parse(p,varargin{:})
            
            % Make sure limits are compatible
            solve_lims = p.Results.Limits;
            if ~isempty(p.Results.guesses)
                guess_lims = [ min(p.Results.guesses(:,1)),...
                    max(p.Results.guesses(:,1)),...
                    min(p.Results.guesses(:,2)),...
                    max(p.Results.guesses(:,2)) ];
                lim_diff = solve_lims - guess_lims;
                lim_diff(:,1) = -lim_diff(:,1); % Minimum column difference reversed
                lim_outside = lim_diff < 0;
                if any(lim_outside)
                    warning('guess found outside solving area. Extending domain.')
                    solve_lims(lim_outside) = guess_lims(lim_outside);
                end
            end
            
            % Load symbolic field functions
            syms x y
            % Trials to find x-points
            pts = zeros(p.Results.ntri,2);
            diffxx =  diff(obj.symMagFieldX,y);
            diffyy = -diff(obj.symMagFieldY,x);
            diffxy = diff(obj.symMagFieldX,x); % d2psidxdy
            for i=1:p.Results.ntri
                sol = vpasolve( [obj.symMagFieldX==0,obj.symMagFieldY==0],...
                                [x,y], solve_lims,'random',true);
                if numel(sol.x)==1
                    % Solution found
                    if subs(diffxx*diffyy-diffxy^2,...
                            {'x','y'},{double(sol.x),double(sol.y)}) < 0
                        % Found a saddle point.
                        pts(i,:) = double([sol.x,sol.y]);
                    else
                        pts(i,:) = NaN;
                    end
                elseif numel(sol.x)>1
                    error('wouldn''t expect 2 solutions. What''s happening??')
                else
                    % If no solutions, fill with NaN
                    pts(i,:) = NaN;
                end
            end
            % Might have found minimum of Psi, not good
            pts(~isfinite(obj.fluxFx(pts(:,1),pts(:,2))),:) = NaN;
            pts(isnan(pts(:,1)),:) = []; % Remove NaN point
            pts = unique(pts,'rows'); % Remove duplicate solutions
            maxxpt = min(p.Results.nxpt,size(pts,1));
            obj.xpoints = pts(1:maxxpt,:);
        end
        
        function coreDetec(obj)
            % TODO - Add parameters controlling the rand addition to
            % initial guess.
            % NOTE - Get rid of the symbolic toolbox with fminsearch?
            
            % Detect configuration's core (minimum flux function)
            plasma = obj.currents([obj.currents(:).isPlasma]);
            assert(numel(plasma)==1)
            syms x y
            bx = obj.symMagFieldX;
            by = obj.symMagFieldY;
            sol = vpasolve([bx==0,by==0],[x,y],[plasma.x, plasma.y]+rand(1,2));
            assert(numel(sol.x)==1)
            obj.corePosition = double([sol.x,sol.y]);
        end
        
        function [q,p] = localSafetyFactor(obj,npts,target,~,~,~)
            % TODO - Fix ugly signature in mConf.safetyFactor
            assert(~isempty(obj.corePosition))
            assert(~isequal(target,obj.corePosition))
            target = [linspace(obj.corePosition(1),target(1),npts);...
                      linspace(obj.corePosition(2),target(2),npts)];
            r = hypot(target(1,:)-target(1,1),target(2,:)-target(2,1));
            bPol = hypot(obj.magFieldX(target(1,:),target(2,:)),...
                         obj.magFieldY(target(1,:),target(2,:)));
            q = (r/obj.R)./bPol;
            p = obj.fluxFx(target(1,:),target(2,:));
        end
        
        function [q,p] = avgSafetyFactor(obj,npts,target,~,~,~)
            % TODO - Fix ugly signature in mConf.safetyFactor
            assert(~isempty(obj.corePosition))
            target = [linspace(obj.corePosition(1),target(1),npts+1);...
                      linspace(obj.corePosition(2),target(2),npts+1)];
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
            % Compute average q on all these contours
            q = zeros(size(S));
            p = [S.level];
            for i=1:numel(S)
                ss = S(i);
                r = hypot(ss.x-target(1,1), ss.y-target(2,1));
                bPol = hypot(obj.magFieldX(ss.x,ss.y),obj.magFieldY(ss.x,ss.y));
                q(i) = mean(r./bPol)/obj.R;
            end
        end
    end
end
