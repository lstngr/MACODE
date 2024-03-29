classdef mConf < matlab.mixin.SetGet & matlab.mixin.Copyable
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
        % configuration. Although the mConf handle array cannot be modified
        % after construction, one may modify currents directly using their
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
        % See also MCONF/LCFSPSI
        psi95
        
        % SEPARATRIXPSITOL - Filtered values of the flux function at x-points
        % For perfectly symmetrical configurations displaying two or more
        % x-points, it might happen that the property separatrixPsi holds
        % two values, although the x-points are supposed to lie on the same
        % flux surface. This is a consequence of the achievable precision
        % of the numerical solving routines employed during a commit.
        %
        % In cases where having duplicate values of the flux function at
        % the separatrix is problematic, SEPARATRIXPSITOL can be requested
        % to filter out duplicate entries in separatrixPsi.
        %
        % See also MCONF/SEPARATRIXPSI
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
            %   currents, or if any current handle is invalid. An error
            %   will be issued if a current's parent is missing from the
            %   input array.
            %
            %   See also CURRENT
            obj.R = R;
            obj.currents = c;
        end
        
        function set.R(obj,R)
            if isnumeric(R)
                validateattributes(R,{'double'},{'scalar','positive'})
            else
                validateattributes(R,{'sym'},{'scalar'})
                assume(R>0);
            end
            obj.R = R;
        end
        
        function set.currents(obj,curs)
            assert(~isempty(curs),'MACODE:mConf:emptyCurrent',...
                'Currents array must not be empty.')
            assert(all(arrayfun(@(x)isa(x,'current'),curs) & isvalid(curs)),...
                'MACODE:mConf:invalidCurrents',...
                'Expected argument to be a valid array of current handles.');
            for icur=1:numel(curs)
                cur = curs(icur);
                if ~isempty(cur.Parent)
                    % If parent provided, expect to find it in the
                    % configuration. Else, warn user.
                    assert(any(ismember(cur.Parent,curs)),...
                        'MACODE:mConf:missingParent',...
                        ['Parent of current in position %u was not found ',...
                        'in the input currents array.'],icur);
                end
            end
            obj.currents = curs;
        end
        
        function [state,reason,msgid] = checkCommit(obj)
            % CHECKCOMMIT Checks if mConf/commit can be called
            %   s = CHECKCOMMIT(obj) checks if a magnetic configuration can
            %   be committed, and, in the subsequent case, if a commit is
            %   needed. The function returns a commitState enumeration
            %   (which can also be mapped to single precision variables).
            %
            %   See also MCONF/COMMIT, COMMITSTATE, SINGLE
            
            % By default, forbid commit
            state = commitState.NotAvail;
            reason = [];
            msgid  = [];
            % Check no symbolic expressions are found
            xr = num2cell(rand(1,2));
            if isa(obj.magFieldX(xr{:}),'sym') || isa(obj.magFieldY(xr{:}),'sym') || isa(obj.fluxFx(xr{:}),'sym')
                msgid  = 'MACODE:mConf:commitSym';
                reason = ['Magnetic structure depends on symbolic variables. ',...
                    'You cannot commit such a configuration.'];
                return;
            end
            % Check if exactly on plasma current is set, and its sign is
            % positive
            curs = obj.currents;
            if sum([curs(:).isPlasma])~=1
                reason = 'Expected exactly one plasma current.';
                msgid  = 'MACODE:mConf:numPlasma';
                return;
            elseif curs([curs(:).isPlasma]).curr<=0
                reason = 'The plasma current is required to be positive.';
                msgid = 'MACODE:mConf:negPlasmaCurrent';
                return;
            end
            % Check if previous commit was done
            symBx = obj.symMagFieldX;
            symBy = obj.symMagFieldY;
            if( ~isempty(obj.old_bx) && ~isempty(obj.old_by) )
                if( isequal(obj.old_bx,symBx) && isequal(obj.old_by,symBy) )
                    state = commitState.Done;
                    msgid = 'MACODE:mConf:commitExists';
                    reason = 'Magnetic structure unchanged since last commit.';
                    return;
                end
            end
            % If reaching this line, commit can be done
            state = commitState.Avail;
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
            %   COMMIT(...,'OffsetScale',s) can be used when LCFS detection
            %   fails. Internal routines of a commit will attempt to retrieve
            %   contour suefaces right next to the LCFS, and try to
            %   automatically determine a relevant offset. Sometimes, this
            %   offset is too small and needs to be increased by setting s
            %   to values larger than 1. Default: 1.
            %
            %   COMMIT(...,'Force',true) performs a full commit even when
            %   the magnetic structure hasn't been changed. This might be
            %   useful if the previous commit finished without errors, but
            %   failed to perform accurately (missing x-point for example).
            %   Default: false.
            %
            %   See also MCONF/SIMAREA
            
            % Define default parameters
            defaultNXPoint = +Inf;
            defaultNTrials = 10;
            defaultLimits = obj.simArea;
            defaultOffScale = 1.0;
            defaultForce = false;
            % Parse inputs
            p = inputParser;
            addOptional(p,'nxpt',defaultNXPoint,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'},...
                'mConf/commit','nxpt',1));
            addOptional(p,'ntri',defaultNTrials,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'},...
                'mConf/commit','ntri',2));
            addParameter(p,'Limits',defaultLimits,...
                @(x)validateattributes(x,{'numeric'},{'2d','square','ncols',2}));
            addParameter(p,'OffsetScale',defaultOffScale,...
                @(x)validateattributes(x,{'numeric'},{'positive','scalar','integer'}));
            addParameter(p,'Force',defaultForce,...
                @(x)validateattributes(x,{'logical'},{'scalar'}));
            parse(p,varargin{:})
            
            
            % Commit configuration as it is loaded and compute stuff
            symBx = obj.symMagFieldX;
            symBy = obj.symMagFieldY;
            [state,reason,msgid] = obj.checkCommit;
            if state == commitState.Done && ~p.Results.Force
                warning(msgid, [reason,'\nYou can force the commit with ''Force'' set to true.'])
                return;
            elseif state == commitState.NotAvail
                error(msgid,reason)
            end
            % Attempt to commit and catch errors
            try
                % X-Point detection
                obj.xPointDetec(p.Results.nxpt, p.Results.ntri, p.Results.Limits);
                % Psi Separatrix and LCFS
                obj.separatrixPsi = obj.fluxFx(obj.xpoints(:,1),...
                    obj.xpoints(:,2));
                obj.lcfsDetec(p.Results.OffsetScale);
                % Find core location
                obj.coreDetec;
                % Compute geometrical properties
                obj.computeMagR(p.Results.OffsetScale);
            catch ME
                % Caught an error, must terminate commit
                % If error is recognized, add a suggestion on how to solve
                % the issue where possible.
                errMsg = 'Commit was aborted (see cause).';
                if strcmp(ME.identifier,'MACODE:mConf:noSeparatrix')
                    errMsg = [errMsg,...
                        '\nSuggested Action: Check simArea and commit again with more tries.'];
                elseif strcmp(ME.identifier,'MACODE:mConf:noContourLCFS')
                    errMsg = [errMsg,...
                        '\nSuggested Action: Check simArea. ',...
                        'If repeated commits fail, try to adjust OffsetScale.'];
                elseif strcmp(ME.identifier,'MACODE:mConf:manyLCFS')
                    errMsg = [errMsg,'\nSuggested Action: ',...
                        'Crop the considered domain using simArea.'];
                end
                commitME = MException('MACODE:mConf:failCommit',errMsg);
                commitME = addCause(commitME,ME);
                throw(commitME);
            end
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
            validateattributes(x,{'double'},{'real'},'mConf/magFieldX','x')
            validateattributes(y,{'double'},{'real'},'mConf/magFieldX','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            bx = zeros(size(x));
            for cur=obj.currents
                bx = bx + cur.magFieldX(x,y);
            end
        end
        
        function by = magFieldY(obj,x,y)
            % MAGFIELDY Y-Component of the magnetic field
            %   by = MAGFIELDY(x,y) returns the y-component of the magnetic
            %   field of the current configuration. x and y are same sized
            %   numerical variables. The ouput variable, by, has the same
            %   size as x and y.
            validateattributes(x,{'double'},{'real'},'mConf/magFieldY','x')
            validateattributes(y,{'double'},{'real'},'mConf/magFieldY','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
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
            validateattributes(x,{'double'},{'real'},'mConf/gradXFluxFx','x')
            validateattributes(y,{'double'},{'real'},'mConf/gradXFluxFx','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
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
            validateattributes(x,{'double'},{'real'},'mConf/gradYFluxFx','x')
            validateattributes(y,{'double'},{'real'},'mConf/gradYFluxFx','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            gy =  obj.R * obj.magFieldX(x,y);
        end
        
        function p = fluxFx(obj,x,y)
            % FLUXFX Poloidal flux function of the configuration
            %   flx = FLUXFX(x,y) returns the poloidal magnetic flux
            %   function of the current configuration. x and y are same
            %   sized numerical variables. The ouput variable, p, has the
            %   same size as x and y.
            validateattributes(x,{'double'},{'real'},'mConf/fluxFx','x')
            validateattributes(y,{'double'},{'real'},'mConf/fluxFx','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            p = zeros(size(x));
            for cur=obj.currents
                p = p + cur.fluxFx(x,y,obj.R);
            end
        end
        
        function f = symMagFieldX(obj)
            % SYMMAGFIELDX Symbolic expression of the magnetic field
            %   fx = SYMMAGFIELDX(obj) returns a symbolic expression of the
            %   x-component of the magnetic field for mConf handle obj,
            %   with symbolic variables x and y.
            f = sym(0);
            for cur=obj.currents
                f = f + cur.symMagFieldX;
            end
        end
        
        function f = symMagFieldY(obj)
            % SYMMAGFIELDY Symbolic expression of the magnetic field
            %   fy = SYMMAGFIELDY(obj) returns a symbolic expression of the
            %   y-component of the magnetic field for mConf handle obj,
            %   with symbolic variables x and y.
            f = sym(0);
            for cur=obj.currents
                f = f + cur.symMagFieldY;
            end
        end
        
        function f = symFluxFx(obj)
            % SYMFLUXFX Symbolic expression of the poloidal flux function
            %   fx = SYMFLUXFX(obj) returns a symbolic expression of the
            %   poloidal magnetic flux function for mConf handle obj, with
            %   symbolic variables x and y.
            f = sym(0);
            for cur=obj.currents
                f = f + cur.symFluxFx(obj.R);
            end
        end
        
        function area = get.simArea(obj)
            if isempty(obj.simArea) && obj.checkCommit ~= commitState.NotAvail
                % User is dumb and did not provide good limits...
                warning('MACODE:mConf:autoLimits',...
                    ['No simArea limits were provided in mConf/commit. ',...
                    'Using automatic ones.\n',...
                    'If this behavior is expected, consider disabling ',...
                    'this warning: <a href="matlab:warning(''off'',''MACODE:mConf:autoLimits'')">',...
                    'warning(''off'',''MACODE:mConf:autoLimits'')</a>'])
                area = [min( [obj.currents(:).x] ), ...
                             max( [obj.currents(:).x]);...
                             min( [obj.currents(:).y] ),...
                             max( [obj.currents(:).y] ) ];
                % Check if things get sketchy
                if any(area(:,2)-area(:,1)<=0)
                    [largeSide,idxLarge] = max(area(:,2)-area(:,1));
                    if largeSide==0
                        error('MACODE:mConf:badLimits',...
                            ['Could not find suitable limits.\n',...
                            'This is likely because all currents occupy the same point in space.'])
                    end
                    warning('MACODE:mConf:badAutoLimits',...
                        ['Your coils are likely aligned on an axis. ',...
                        'Automatic limits might not be suitable.\n',...
                        'If this behavior is expected, consider disabling this warning: ',...
                        '<a href="matlab:warning(''off'',''MACODE:mConf:badAutoLimits'')">',...
                        'warning(''off'',''MACODE:mConf:badAutoLimits'')</a>'])
                    meanSmall = mean(area(3-idxLarge,:));
                    area(3-idxLarge,1) = meanSmall - largeSide/2;
                    area(3-idxLarge,2) = meanSmall + largeSide/2;
                end
                obj.simArea = area;
                return;
            end
            area = obj.simArea;
        end
        
        function p = get.psi95(obj)
            assert(~isempty(obj.separatrixPsi),'MACODE:mConf:noSeparatrix',...
                'Could not find separatrix. Were x-points correctly detected?');
            assert(~isempty(obj.corePosition),'MACODE:mConf:noMagneticAxis',...
                'Could not find magnetic axis. Was the center correctly detected?',...
                'Suggested action: Commit the configuration again.');
            sp = obj.lcfsPsi;
            cp = obj.fluxFx(obj.corePosition(1),obj.corePosition(2));
            % If cp is not defined, try harder
            if ~isfinite(cp)
                xsym = sym('x'); ysym = sym('y');
                cp = double(...
                    limit(subs(obj.symFluxFx,ysym,obj.corePosition(2))),...
                    xsym,obj.corePosition(1));
            end
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
            assert(~isempty(obj.magR),'MACODE:mConf:noMagR',...
                ['Could not find configuration''s radiuses. Was the LCFS detected?\n',...
                'Suggested action: Commit the configuration again.']);
            a = (obj.magR.Rmax - obj.magR.Rmin)/2;
        end
        
    end
    
    methods(Access=private)
        
        function lcfsDetec(obj,offsetScale)
            % Detects the LCFS, so that the user can differentiate with the
            % separatrixPsi when necessary. 
            % Called during commit, once x-points and separatrixPsi are
            % available.
            
            % When querying contours at separatrix, MATLAB returns
            % (usually) two open contours. Shift those psi by an arbitrary
            % amount to get closed contours
            
            % TODO - Get rid of the "arbitrary" amount, or provide user
            % with adjustable parameter.
            
            % Get target psi's, but need a psi offset which we compute
            assert(~isempty(obj.separatrixPsi),'MACODE:mConf:noSeparatrix',...
                'Could not find separatrix. Were x-points correctly detected?');
            baseScale = 5e-5 * offsetScale; % Arbitrary shift to select contour
            Points(1) = 100; % # of sample points on grid
            w = obj.simArea(3)-obj.simArea(1);
            h= obj.simArea(4)-obj.simArea(2);
            Points(2) = Points(1) * min([w,h]) / max([w,h]);
            [~,I] = sort([h,w]);
            Points = Points(I);
            [X,Y] = meshgrid(linspace(obj.simArea(1),obj.simArea(3),Points(1)),...
                linspace(obj.simArea(2),obj.simArea(4),Points(2)));
            allFlux = obj.fluxFx(X(:),Y(:));
            rangeFluxFx(1) = min(allFlux);
            rangeFluxFx(2) = max(allFlux);
            rangeFluxFx = diff(rangeFluxFx);
            psiOffset = baseScale * rangeFluxFx;
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
            assert(~isempty(S),'MACODE:mConf:noContourLCFS',...
                'Detection of a LCFS surface contour failed.');
            % Maximum available value of Psi must be LCFS
            obj.lcfsPsi = max(S.level)+psiOffset;
        end
        
        function computeMagR(obj,offsetScale)
            % Finds a contour close to the LCFS and gathers
            % R_max,min,upper,lower,geo and a.
            assert(~isempty(obj.lcfsPsi),'MACODE:unexpected',...
                'Unexpected Behavior: Could not find LCFS.\n',...
                'Previously called method from mConf/commit should have thrown.');
            % Compute psi offset
            baseScale = 5e-5 * offsetScale;
            allFlux = [obj.lcfsPsi, obj.fluxFx(obj.corePosition(1),obj.corePosition(2))];
            rangeFluxFx(1) = min(allFlux);
            rangeFluxFx(2) = max(allFlux);
            rangeFluxFx = diff(rangeFluxFx);
            psiOffset = baseScale * rangeFluxFx;
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
            assert(~isempty(S),'MACODE:unexpected',...
                ['Unexpected Behavior: Detection of a LCFS surface contour failed.\n',...
                'This is likely caused by non-consistent behavior of contourc.']);
            % NOTE - Following check is required since lcfsDetec could not
            % reason about the core, and might have exited with 2+ closed
            % contours that were detected
            if(numel(S)>1)
                % Multiple closed contours, find one enclosing core
                corein = false(1,numel(S));
                for is=1:numel(S)
                    corein(is) = inpolygon(obj.corePosition(1),obj.corePosition(2),...
                        S(is).x,S(is).y);
                end
                S = S(corein);
                % TODO - Could compute which enclosing surface has a
                % point closest to the magnetic axis...
                assert(numel(S)==1,'MACODE:mConf:manyLCFS',...
                    ['Many LCFS level contours enclosing the magnetic center were found.\n',...
                    'This is likely due to your simulation area being too large.']);
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
            x = sym('x','real');
            y = sym('y','real');
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
                    error('MACODE:unexpected',...
                        'Unexpected Behavior: Two null points were returned by vpasolve.')
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
            x = sym('x','real');
            y = sym('y','real');
            bx = obj.symMagFieldX;
            by = obj.symMagFieldY;
            sol = vpasolve([bx==0,by==0],[x,y],[plasma.x, plasma.y]+rand(1,2));
            assert(numel(sol.x)==1,'MACODE:unexpected',...
                'Unexpected Behavior: Two null points were returned by vpasolve.')
            obj.corePosition = double([sol.x,sol.y]);
        end
        
    end
    
    methods( Access = protected )
        function cp = copyElement(obj)
            % COPYELEMENT Deep copy of an mConf object
            %   cp = COPYELEMENT(obj) copies the mConf object obj into a
            %   new handle, cp. The memory contents of obj and cp are
            %   different.
            %
            %   COPYELEMENT ensures the following rules are satisfied:
            %       - All properties are copied by value, except currents.
            %       - Among obj's current array, only the parent currents
            %       are copied. Due to current class' copy behavior, all
            %       child currents also get copied.
            %       - The current arrays of obj and cp hold similar
            %       currents at the end of the copy (although the handles
            %       refer to different memory regions). It is possible that
            %       "supplemental" children, not required by the
            %       configurations, have been copied, but these won't be
            %       included in cp.
            %
            %   See also CURRENT/COPYELEMENT
            
            % Start by shallow copy of every property.
            cp = copyElement@matlab.mixin.Copyable(obj);
            % Then, find all independent currents of the class. Dependent
            % current must reference them (per constructor behavior).
            
            % All Root Currents lead to different trees
            isRoot = false(1,numel(obj.currents));
            for ic=1:numel(obj.currents)
                isRoot(ic) = isempty(obj.currents(ic).Parent);
            end
            
            % Copy root currents (and all descendants)
            rootCp = currentWire.empty(sum(isRoot),0);
            rootCur= obj.currents(isRoot);
            for ir=1:sum(isRoot)
                rootCp(ir) = copy(rootCur(ir));
            end
            
            % Iterate on mConf object being copied, and detect which
            % children currents need to be included (and which not!)
            newCurs = currentWire.empty(numel(obj.currents),0);
            for ic=1:numel(obj.currents)
                if isRoot(ic)
                    % If object is supposed to be a root, easy, we have it
                    % ready.
                    newCurs(ic) = rootCp(sum(isRoot(1:ic)));
                else
                    % Need to browse rootCp to find children
                    % From original child, ask for its index among parent's
                    % Children, and go up until reached root
                    idxc = [];
                    curPtr = obj.currents(ic);
                    while ~isempty(curPtr.Parent)
                        idxc(end+1) = find(obj.currents(ic).Parent.Children==obj.currents(ic)); %#ok<AGROW>
                        curPtr = curPtr.Parent; % Move up in hierarchy
                    end
                    % Here, curPtr is a root. Find which, and set pointer
                    % on new object
                    curPtr = rootCp(rootCur==curPtr);
                    % Reverse index sequence to go down hieararchy
                    idxc = fliplr(idxc);
                    for inc=1:numel(idxc)
                        curPtr = curPtr.Children(idxc(inc));
                    end
                    % Found requested child current! Set it and go to next
                    % child.
                    newCurs(ic) = curPtr;
                end
            end
            cp.currents = newCurs;
        end
    end
end