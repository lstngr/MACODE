% TODO - Could implement domain scaling
% TODO - Support multiple x-points

classdef mConf < matlab.mixin.SetGet & handle
    
    properties
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
                    warning('magnetic structure unchanged since last commit.')
                    return;
                end
            end
            obj.xPointDetec(varargin{:});
            % Psi Separatrix
            obj.separatrixPsi = obj.fluxFx(obj.xpoints(1),...
                obj.xpoints(2));
            % Remember last commit's magnetic structure
            obj.old_bx  = symBx;
            obj.old_by  = symBy;
        end
        
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
            syms x y
            symBx = obj.symMagFieldX;
            symBy = obj.symMagFieldY;
            xmin = min( [obj.currents(:).x] );
            xmax = max( [obj.currents(:).x] );
            ymin = min( [obj.currents(:).y] );
            ymax = max( [obj.currents(:).y] );
            pts = vpasolve( [symBx==0,symBy==0], [x,y], [xmin,xmax;ymin,ymax],...
                'random',true);
            obj.xpoints = double(horzcat(pts.x,pts.y));
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
                f = f + cur.FluxFx(x,y,obj.R);
            end
        end
    end
    
end