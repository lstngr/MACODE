% TODO - Could implement domain scaling
classdef mConf < matlab.mixin.SetGet
    % MCONF     Tokamak Magnetic Configuration
    %   MCONF is a class describing a "magnetic configuration" of a
    %   Tokamak. A set of currents is provided, as well as an area of
    %   interest. The class then runs a computation of properties of this
    %   configuration, such as x-point and core detection or computation of
    %   geometrical properties.
    
    properties(GetAccess=public,SetAccess=private)
        R % Tokamak major radius
        
        % CURRENTS - Array of current handles
        % This array contains the currents generating the magnetic
        % configuration. Although the handle cannot be modified after
        % construction, one may modify currents directly using their
        % handles, thus changing the configuration.
        currents = currentWire.empty()
        
        % XPOINTS - Coordinates of the x-point(s)
        % N by 2 array containing the configuration's N x-points
        % coordinates.
        xpoints
        
        separatrixPsi % Values of the flux function evaluated at the x-points
        lcfsPsi % Values of the flux function at the last closed flux surface
        corePosition % Position of the center (of the core region)
        
        % MAGR - Structure describing the configuration's geometry
        % This structure holds the fields
        %
        % * Rmax: Maximum major radius along the LCFS
        % * Rmin: Minimum major radius along the LCFS
        % * Rupper: Major radius at the highest vertical point of the LCFS
        % * Rlower: Major radius at the lowest  vertical point of the LCFS
        % * Rgeo: Defined by (Rmin+Rmax)/2
        magR
    end
    
    properties
        % SIMAREA - Region of interest of the configuration
        % This region is relevant when a configuration is commit. The
        % commit process involves calling numerical solving routines to
        % estimate various quantities (x-point and center locations for
        % example). If this area isn't adjusted correctly, these routines
        % will often fail.
        simArea = []
    end
    
    properties(Dependent)
        % A - Minor radius of the plasma
        % This parameter is dependent on <a href="matlab:doc('mConf/magR')">mConf/magR</a>
        %  and computed as (Rmax-Rmin)/2.
        a
        
        % PSI95 - Returns 95% of lcfsPsi.
        % See also lcfsPsi
        psi95
        
        % SEPARATRIXPSITOL - Filtered values of the flux function at
        % x-points For perfectly symmetrical configurations displaying two
        % or more x-points, it might happen that the property separatrixPsi
        % holds two values, although the x-points are supposed to lie on
        % the same flux surface. This is a consequence of the achievable
        % precision of the numerical solving routines employed during a
        % commit.
        %
        % In cases where having duplicate values of the flux function at
        % the separatrix is problematic, SEPARATRIXPSITOL can be requested
        % to filter out duplicate entries in separatrixPsi.
        %
        % See also SEPARATRIXPSI
        separatrixPsiTol
    end
    
    properties(Access=private)
        old_bx, old_by % Compared when commit is called. Avoid commiting twice uselessely.
    end
    
    methods
        function obj = mConf(R,c)
            % MCONF Create a magnetic configuration handle
            %   h = MCONF(R,c) initializes a magnetic configuration handle
            %   with major radius R, containing currents c. c is expected
            %   to be an array of valid current handles.
            %
            %   The constructor will throw an error if c doesn't hold
            %   currents, or if any current handle is invalid. A warning
            %   will be issued if a current's parent is missing from the
            %   input array.
            %
            %   See also CURRENT
            obj.R = R;
            obj.currents = c;
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
            % COMMIT Computes properties of a magnetic configuration
            %   COMMIT(obj) commits the magnetic configuration of mConf
            %   class instance obj. This method first detects the
            %   configuration's x-points, computes the flux function at
            %   those points, identifies which separatrix (if any) is the
            %   LCFS, finds the center and computes the mConf/magR
            %   structure. If a previous commit was run, but the magnetic
            %   configuration hasn't been changed, a warning is issued and
            %   the computation is stopped.
            %
            %   COMMIT(obj,nxpt) does the same as above, but returns at
            %   most nxpt null points. This option might be useful if the
            %   detection of duplicate x-points fails, or if the method
            %   misclassifies some points. Default: +Inf.
            %
            %   COMMIT(obj,nxpt,ntri) solves for x-point ntri times with
            %   random initial conditions. If secondary x-points fail to be
            %   detected, increasing this parameter may help. Default: 10.
            %
            %   COMMIT(...,'Limits',lims) runs the commit method with
            %   custom boundaries. By default, the object's mConf/simArea
            %   limits are used.
            %
            %   COMMIT(...,'Force',true) performs a full commit even when
            %   the magnetic structure hasn't been changed. This might be
            %   useful if the previous commit finished without errors, but
            %   failed to perform accurately (missing x-point for example).
            %   Default: false.
            %
            %   See also SIMAREA
            
            % Define default parameters
            defaultNXPoint = +Inf;
            defaultNTrials = 10;
            defaultLimits = obj.simArea;
            defaultForce = false;
            % Parse inputs
            p = inputParser;
            addOptional(p,'nxpt',defaultNXPoint,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addOptional(p,'ntri',defaultNTrials,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addParameter(p,'Limits',defaultLimits,...
                @(x)validateattributes(x,{'numeric'},{'2d','square','ncols',2}));
            addParameter(p,'Force',defaultForce,...
                @(x)validateattributes(x,{'logical'},{'scalar'}));
            parse(p,varargin{:})
            
            
            % Commit configuration as it is loaded and compute stuff
            syms x y
            symBx = obj.symMagFieldX;
            symBy = obj.symMagFieldY;
            if( ~isempty(obj.old_bx) && ~isempty(obj.old_by) )
                if( isequal(obj.old_bx,symBx) && isequal(obj.old_by,symBy) ) && ~p.Results.Force
                    warning('magnetic structure unchanged since last commit. You can force the commit with ''Force'',true.')
                    return;
                end
            end
            obj.xPointDetec(p.Results.nxpt, p.Results.ntri, p.Results.Limits);
            % Psi Separatrix and LCFS
            obj.separatrixPsi = obj.fluxFx(obj.xpoints(:,1),...
                obj.xpoints(:,2));
            obj.lcfsDetec;
            % Find core location
            obj.coreDetec;
            % Compute geometrical properties
            obj.computeMagR;
            % Remember last commit's magnetic structure
            obj.old_bx  = symBx;
            obj.old_by  = symBy;
        end
        
        function bx = magFieldX(obj,x,y)
            % MAGFIELDX X-Component of the magnetic field
            %   bx = MAGFIELDX(x,y) returns the x-component of the magnetic
            %   field of the current configuration. x and y are same sized
            %   numerical variables. The ouput variable, bx, has the same
            %   size as x and y.
            bx = zeros(size(x));
            for cur=obj.currents
                bx = bx + cur.magFieldX(x,y);
            end
        end
        
        function by = magFieldY(obj,x,y)
            % MAGFIELDX Y-Component of the magnetic field
            %   by = MAGFIELDY(x,y) returns the y-component of the magnetic
            %   field of the current configuration. x and y are same sized
            %   numerical variables. The ouput variable, by, has the same
            %   size as x and y.
            by = zeros(size(x));
            for cur=obj.currents
                by = by + cur.magFieldY(x,y);
            end
        end
        
        function gx = gradXFluxFx(obj,x,y)
            % GRADXFLUXFX X-Component of the flux function's gradient
            %   gx = GRADXFLUXFX(x,y) returns the x-component of the
            %   gradient of the poloidal magnetic flux function. x and y
            %   are same sized numerical variables. The ouput variable, gx,
            %   has the same size as x and y.
            %
            %   Note this method is just a wrapper of the magnetic field's
            %   y-component since both quantities are proportional by a
            %   factor -R (major radius).
            %
            %   See also mConf/magFieldY
            gx = -obj.R * obj.magFieldY(x,y);
        end
        
        function gy = gradYFluxFx(obj,x,y)
            % GRADYFLUXFX Y-Component of the flux function's gradient
            %   gy = GRADYFLUXFX(x,y) returns the y-component of the
            %   gradient of the poloidal magnetic flux function. x and y
            %   are same sized numerical variables. The ouput variable, gy,
            %   has the same size as x and y.
            %
            %   Note this method is just a wrapper of the magnetic field's
            %   x-component since both quantities are proportional by a
            %   factor R (major radius).
            %
            %   See also mConf/magFieldX
            gy =  obj.R * obj.magFieldX(x,y);
        end
        
        function p = fluxFx(obj,x,y)
            % FLUXFX Poloidal flux function of the configuration
            %   flx = FLUXFX(x,y) returns the poloidal magnetic flux
            %   function of the current configuration. x and y are same
            %   sized numerical variables. The ouput variable, p, has the
            %   same size as x and y.
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
            psiOffset = 1e-1;
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
            assert(numel(S)>=1);
            if(numel(S)>1)
                % Multiple closed contours, find one enclosing core
                corein = false(1,numel(S));
                for is=1:numel(S)
                    corein(is) = inpolygon(obj.corePosition(1),obj.corePosition(2),...
                        S(is).x,S(is).y);
                end
                S = S(corein);
            assert(numel(S)==1);
            end
            xmax = max(S.x); [~,iymax] = max(S.y);
            xmin = min(S.x); [~,iymin] = min(S.y);
            ymax = S.x(iymax);
            ymin = S.x(iymin);
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
