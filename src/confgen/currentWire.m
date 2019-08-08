classdef currentWire < current
    % CURRENTWIRE Delta distributed current
    %   This class provides an infinitely thin (delta function) current
    %   distribution at the specified location.
    
    methods
        function obj=currentWire(x,y,c,varargin)
            % CURRENTWIRE Current filament constructor
            %   h = CURRENTWIRE(x,y,c) constructs an infinitely long
            %   electrical current filament at cartesian coordinates (x,y)
            %   with current intensity c and returns a handle h to the
            %   created current.
            %
            %   h = CURRENTWIRE(...,p) uses the current handle p as a
            %   parent current for h.
            obj@current(x,y,c,varargin{:});
        end
        
        function bx = magFieldX(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentWire/magFieldX','x')
            validateattributes(y,{'double','sym'},{'real'},'currentWire/magFieldX','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            bx = obj.curr * ( dy./d2);
        end
        
        function by = magFieldY(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentWire/magFieldY','x')
            validateattributes(y,{'double','sym'},{'real'},'currentWire/magFieldY','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            by = obj.curr * (-dx./d2);
        end
        
        function flx = fluxFx(obj,x,y,R)
            validateattributes(x,{'double','sym'},{'real'},'currentWire/fluxFx','x')
            validateattributes(y,{'double','sym'},{'real'},'currentWire/fluxFx','y')
            validateattributes(R,{'double','sym'},{'real','positive'},'currentWire/fluxFx','R')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            flx = .5 * obj.curr * R * log(d2);
        end
    end
    
end