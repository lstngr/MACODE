classdef mConf < matlab.mixin.SetGet
    
    properties
        R
        currents = currentWire.empty()
    end
    
    methods
        function obj = mConf(R,varargin)
            narginchk(1,2);
            obj.R = R;
            if nargin==2
                obj.currents = varargin{1};
            end
        end
        
        function obj = set.currents(obj,curs)
            if all(arrayfun(@(x)isa(x,'current'),curs) & isvalid(curs))
                obj.currents = curs;
            end
            % TODO - Check parent and children for non included currents in
            % curs!
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
        
        function p = fluxFx(obj,x,y)
            p = zeros(size(x));
            for cur=obj.currents
                p = p + cur.FluxFx(x,y,obj.R);
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