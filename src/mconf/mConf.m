% TODO - Could implement domain scaling
% TODO - Support multiple x-points

classdef mConf < matlab.mixin.SetGet & handle
    
    properties(GetAccess=public,SetAccess=private)
        R
        currents = currentWire.empty()
        xpoints
        separatrixPsi
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
            assert(sum([curs(:).plasma])<2,'Expected at most one plasma current.')
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
        
        function gx = gradXPolAngle(obj,x,y)
            % TODO - Check direction of gradient of chi (taken clockwise so
            % that gradPsi^gradChi point in the direction of positive z in
            % the version below).
            gx = obj.gradYFluxFx(x,y);
        end
        
        function gy = gradYPolAngle(obj,x,y)
            % TODO - Check direction of gradient of chi (taken clockwise so
            % that gradPsi^gradChi point in the direction of positive z in
            % the version below).
            gy = -obj.gradXFluxFx(x,y);
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
            defaultLimits = [min( [obj.currents(:).x] ), ...
                             max( [obj.currents(:).x]);...
                             min( [obj.currents(:).y] ),...
                             max( [obj.currents(:).y] ) ];
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
            for i=1:p.Results.ntri
                sol = vpasolve( [obj.symMagFieldX==0,obj.symMagFieldY==0],...
                                [x,y], solve_lims,'random',true);
                if numel(sol)==1
                    % Solution found
                    pts(i,:) = double([sol.x,sol.y]);
                elseif numel(sol)>1
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
        
    end
end