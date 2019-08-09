classdef currentGaussian < current
    % CURRENTGAUSSIAN Normally distributed current
    %   Creates a current handle with Gaussian distribution around the
    %   prescribed location. The distribution is described by an
    %   exp(-d2/(2*sig2)) decay, with d2 the square of the distance to the
    %   distribution's center, and sig2 the variance. The current
    %   distribution is not normalized by sqrt(2*pi*sig2)!
    
    properties
        sigma % Standard deviation of the normal distribution
    end
    
    methods
        function obj = currentGaussian(x,y,c,s,varargin)
            % CURRENTGAUSSIAN Constructor for normally distributed current
            %   h = CURRENTGAUSSIAN(x,y,c,s) returns a new handle to a
            %   CURRENTGAUSSIAN object. x and y describe the center of the
            %   current distribution, c the current intensity and s the
            %   standard deviation of the distribution.
            %
            %   h = CURRENTGAUSSIAN(...,p) assigns the parent current p to
            %   the new Gaussian current.
            %
            %   See also CURRENT
            narginchk(4,5)
            obj@current(x,y,c,varargin{:});
            obj.sigma = s;
        end
        
        function set.sigma(obj,s)
            if isnumeric(s)
                validateattributes(s,{'double'},{'scalar','positive'})
            else
                validateattributes(s,{'sym'},{'scalar'})
                assume( s>0 );
            end
            obj.sigma = s;
        end
        
        function bx = magFieldX(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentGaussian/magFieldX','x')
            validateattributes(y,{'double','sym'},{'real'},'currentGaussian/magFieldX','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            bx = obj.curr * ( dy./d2) .* (1 - exp( -0.5*d2./obj.sigma^2 ));
        end
        
        function by = magFieldY(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentGaussian/magFieldY','x')
            validateattributes(y,{'double','sym'},{'real'},'currentGaussian/magFieldY','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            by = obj.curr * (-dx./d2) .* (1 - exp( -0.5*d2./obj.sigma^2 ));
        end
        
        function flx = fluxFx(obj,x,y,R)
            validateattributes(x,{'double','sym'},{'real'},'currentGaussian/fluxFx','x')
            validateattributes(y,{'double','sym'},{'real'},'currentGaussian/fluxFx','y')
            if isnumeric(R)
                validateattributes(R,{'double'},{'real','positive'},'currentGaussian/fluxFx','R')
            else
                validateattributes(R,{'sym'},{'real'},'currentGaussian/fluxFx','R')
                assume(R>0);
            end
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            dx = x - obj.x;
            dy = y - obj.y;
            d2 = dx.^2 + dy.^2;
            u  = 0.5 * d2 / obj.sigma^2;
            % Integration prop to log(u) - Ei(-u)
            % Wolfram says E1(x)=expint(x)=-Ei(-x)
            flx = .5 * obj.curr * R * ( log(u) + expint(u) );
        end
    end
    
end