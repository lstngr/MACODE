classdef currentGaussian < current
    
    properties
        sigma
    end
    
    methods
        function obj = currentGaussian(x,y,c,s,varargin)
            narginchk(4,5)
            obj@current(x,y,c,varargin{:});
            obj.sigma = s;
        end
        
        function bx = magFieldX(obj,x,y)
            assert(isequal(size(x),size(y)));
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            bx = obj.curr * ( dy./d2) .* (1 - exp( -0.5*d2./obj.sigma^2 ));
        end
        
        function by = magFieldY(obj,x,y)
            assert(isequal(size(x),size(y)));
            assert(isequal(size(x),size(y)));
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            by = obj.curr * (-dx./d2) .* (1 - exp( -0.5*d2./obj.sigma^2 ));
        end
        
        function flx = FluxFx(obj,x,y,R)
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            u  = 0.5 * d2 / obj.sigma^2;
            flx = .5 * obj.curr * R * ( log(u) - real(-expint(u)) );
        end
    end
    
end