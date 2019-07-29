classdef currentWire < current
    
    methods
        function obj=currentWire(x,y,c,varargin)
            obj@current(x,y,c,varargin{:});
        end
        
        function bx = magFieldX(obj,x,y)
            assert(isequal(size(x),size(y)));
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            bx = obj.curr * ( dy./d2);
        end
        
        function by = magFieldY(obj,x,y)
            assert(isequal(size(x),size(y)));
            assert(isequal(size(x),size(y)));
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            by = obj.curr * (-dx./d2);
        end
        
        function flx = FluxFx(obj,x,y,R)
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            flx = .5 * obj.curr * R * log(d2);
        end
    end
    
end