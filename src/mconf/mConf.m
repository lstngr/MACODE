% TODO - Could implement domain scaling
classdef mConf < matlab.mixin.SetGet
    % MCONF     Tokamak Magnetic Configuration
    %   MCONF is a class describing a "magnetic configuration" of a
    %   Tokamak. A set of currents is provided, as well as an area of
    %   interest. The class then runs a computation of properties of this
    %   configuration, such as x-point and core detection or computation of
    %   geometrical properties.
    
    properties(GetAccess=public,SetAccess=private)
        R
        currents = currentWire.empty()
        xpoints
        separatrixPsi
        lcfsPsi
        corePosition
        magR
    end
    
    properties
        simArea = []
    end
    
    properties(Dependent)
        a
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
            for cur=curs
                if ~isempty(cur.Parent)
                    % If parent provided, expect to find it in the
                    % configuration. Else, warn user.
                    if ~(any(ismember(cur.Parent,curs)))
                        warning('Parent was not found.')
                    end
                end
            end
            assert(sum([curs(:).isPlasma])==1,'Expected at exactly one plasma current.')
            obj.currents = curs;
        end
        
        function commit(obj,varargin)
            
            % Define default parameters
            defaultNXPoint = +Inf;
            defaultNTrials = 10;
            defaultLimits = obj.simArea;
            % Parse inputs
            p = inputParser;
            addOptional(p,'nxpt',defaultNXPoint,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addOptional(p,'ntri',defaultNTrials,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addParameter(p,'Limits',defaultLimits,...
                @(x)validateattributes(x,{'numeric'},{'2d','square','ncols',2}));
            parse(p,varargin{:})
            
            
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
            obj.xPointDetec(p.Results.nxpt, p.Results.ntri, p.Results.Limits);
            % Psi Separatrix and LCFS
            obj.separatrixPsi = obj.fluxFx(obj.xpoints(:,1),...
                obj.xpoints(:,2));
            obj.lcfsDetec;
            % Compute geometrical properties
            obj.computeMagR;
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
            sp = obj.lcfsPsi;
            cp = obj.fluxFx(obj.corePosition(1),obj.corePosition(2));
            p = cp + 0.95*(sp-cp);
        end
        
        function p = get.separatrixPsiTol(obj)
            % Return separatrix with numerical tolerance
            % TODO - Eventually add a custom tolerance parameter?
            % NOTE - Relative tolerance is being computed. Use 'DataScale'
            % to provide absolute difference.
            p = uniquetol(obj.separatrixPsi,1e-8);
        end
        
        function a = get.a(obj)
            assert(~isempty(obj.magR));
            a = (obj.magR.Rmax - obj.magR.Rmin)/2;
        end
        
    end
    
    methods(Access=private)
        
        function lcfsDetec(obj)
            % Detects the LCFS, so that the user can differentiate with the
            % separatrixPsi when necessary. 
            % Called during commit, once x-points and separatrixPsi are
            % available.
            
            % When querying contours at separatrix, MATLAB returns
            % (usually) two open contours. Shift those psi by an arbitrary
            % amount to get closed contours
            
            % TODO - Get rid of the "arbitrary" amount, or provide user
            % with adjustable parameter.
            
            % Get target psi's
            assert(~isempty(obj.separatrixPsi))
            psiOffset = 1;
            targetPsi = obj.separatrixPsiTol - psiOffset;
            if numel(targetPsi)==1
                % Else, contourc will returns targetPsi different contours!
                targetPsi = repmat(targetPsi,1,2);
            end
            % Grab associated _closed_ contours
            contour_resolution = 0.75;
            Lx = obj.simArea(1,2) - obj.simArea(1,1);
            Ly = obj.simArea(2,2) - obj.simArea(2,1);
            cx = linspace(obj.simArea(1,1), obj.simArea(1,2), ceil(Lx*contour_resolution));
            cy = linspace(obj.simArea(2,1), obj.simArea(2,2), ceil(Ly*contour_resolution));
            [CX,CY] = meshgrid(cx,cy);
            C = contourc(cx,cy,obj.fluxFx(CX,CY),targetPsi);
            S = extract_contourc(C);
            S = removeOpenContours(S);
            % Maximum available value of Psi must be LCFS
            obj.lcfsPsi = max(S.level)+psiOffset;
        end
        
        function computeMagR(obj)
            % Finds a contour close to the LCFS and gathers
            % R_max,min,upper,lower,geo and a.
            assert(~isempty(obj.lcfsPsi));
            psiOffset = 1e-2;
            targetPsi = repmat(obj.lcfsPsi-psiOffset,1,2);
            contour_resolution = 0.75;
            Lx = obj.simArea(1,2) - obj.simArea(1,1);
            Ly = obj.simArea(2,2) - obj.simArea(2,1);
            cx = linspace(obj.simArea(1,1), obj.simArea(1,2), ceil(Lx*contour_resolution));
            cy = linspace(obj.simArea(2,1), obj.simArea(2,2), ceil(Ly*contour_resolution));
            [CX,CY] = meshgrid(cx,cy);
            C = contourc(cx,cy,obj.fluxFx(CX,CY),targetPsi);
            S = extract_contourc(C);
            S = removeOpenContours(S);
            assert(numel(S)==1);
            xmax = max(S(1).x); [~,iymax] = max(S(1).y);
            xmin = min(S(1).x); [~,iymin] = min(S(1).y);
            ymax = S(1).x(iymax);
            ymin = S(1).x(iymin);
            Rmax = obj.R + xmax - Lx/2;
            Rmin = obj.R + xmin - Lx/2;
            Rupper = obj.R + ymax - Lx/2;
            Rlower = obj.R + ymin - Lx/2;
            Rgeo   = (Rmax + Rmin)/2;
            obj.magR = struct('Rmax',Rmax,'Rmin',Rmin,'Rupper',Rupper,...
                'Rlower',Rlower,'Rgeo',Rgeo);
        end
        
        function xPointDetec(obj,nxpt,ntri,solve_lims)
            % Load symbolic field functions
            syms x y
            % Trials to find x-points
            pts = zeros(ntri,2);
            diffxx =  diff(obj.symMagFieldX,y);
            diffyy = -diff(obj.symMagFieldY,x);
            diffxy = diff(obj.symMagFieldX,x); % d2psidxdy
            for i=1:ntri
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
            pts = uniquetol(pts,eps(10),'ByRows',true,'DataScale',1); % Remove duplicate solutions
            maxxpt = min(nxpt,size(pts,1));
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
        
    end
end
