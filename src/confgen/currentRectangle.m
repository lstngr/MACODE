classdef currentRectangle < current
    % CURRENTWIRE Delta distributed current
    %   This class provides an infinitely thin (delta function) current
    %   distribution at the specified location.
    
    properties
        a
        b
        rot
    end
    
    methods
        function obj=currentRectangle(x,y,c,a,b,rot,varargin)
            % CURRENTWIRE Current filament constructor
            %   h = CURRENTWIRE(x,y,c) constructs an infinitely long
            %   electrical current filament at cartesian coordinates (x,y)
            %   with current intensity c and returns a handle h to the
            %   created current.
            %h
            %   h = CURRENTWIRE(...,p) uses the current handle p as a
            %   parent current for h.
            obj@current(x,y,c,varargin{:});
            obj.a = a;
            obj.b = b;
            obj.rot = rot;
        end
        
        function bx = magFieldX(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentRectangle/magFieldX','x')
            validateattributes(y,{'double','sym'},{'real'},'currentRectangle/magFieldX','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            bx = 0.5*obj.curr*cos(obj.rot).*(-0.5.*(log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2-4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2+4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))-1./2.*(log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2-4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2+4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))+atan((obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))-atan((obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))-atan((obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))))-1./2.*obj.curr.*sin(obj.rot).*((log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))-atan((obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))-atan((obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+1./2.*(log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(-(obj.b./2)+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(-(obj.b./2)+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))));
        end
        
        function by = magFieldY(obj,x,y)
            validateattributes(x,{'double','sym'},{'real'},'currentRectangle/magFieldY','x')
            validateattributes(y,{'double','sym'},{'real'},'currentRectangle/magFieldY','y')
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            by = 1./2.*obj.curr.*cos(obj.rot).*((log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.b./2+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))-atan((obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))-atan((obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))./(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+1./2.*(log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(-(obj.b./2)+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+(-(obj.b./2)+(y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))))+1./2.*obj.curr.*sin(obj.rot).*(-(1./2).*(log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2-4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2+4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2+4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))-1./2.*(log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2-4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))-log(obj.a.^2-4.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+obj.b.^2+4.*obj.b.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))+4.*(((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)).^2))).*(obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))+atan((obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))+atan((obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b+2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))-atan((obj.a+2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))-atan((obj.a-2.*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)))./(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot)))).*(obj.b-2.*((y-obj.y).*cos(obj.rot)-(x-obj.x).*sin(obj.rot))));
        end
        
        function flx = fluxFx(obj,x,y,R)
            validateattributes(x,{'double','sym'},{'real'},'currentRectangle/fluxFx','x')
            validateattributes(y,{'double','sym'},{'real'},'currentRectangle/fluxFx','y')
            if isnumeric(R)
                validateattributes(R,{'double'},{'real','positive'},'currentRectangle./fluxFx','R')
            else
                validateattributes(R,{'sym'},{'real'},'currentRectangle/fluxFx','R')
                assume(R>0);
            end
            assert(isequal(size(x),size(y)),'MACODE:dimagree','Matrix dimensions must agree.')
            flx = 1./16.*obj.curr.*R.*(-log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2).*obj.a.^2+log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*obj.a.^2-log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*obj.a.^2+4.*obj.b.*atan((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*obj.a-4.*obj.b.*atan((obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*obj.a+8.*atan((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).*obj.a-8.*atan((obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).*obj.a-4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a-4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).*obj.a+4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).^2-4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).^2+4.*log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).^2-4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+4.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2-4.*log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot)).^2+obj.b.^2.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2)-obj.b.^2.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2)+obj.b.^2.*log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2)-4.*obj.b.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot))+4.*obj.b.*log((obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot))+4.*obj.b.*log((obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2+(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)).^2).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot))+8.*obj.b.*atan((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot))+8.*obj.b.*atan((obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot))+16.*atan((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot))+16.*atan((obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot))./(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot))).*((y-obj.y).*cos(obj.rot)+(obj.x-x).*sin(obj.rot)).*((x-obj.x).*cos(obj.rot)+(y-obj.y).*sin(obj.rot))-4.*atan((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))./(obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot))).*(obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).*(obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot))+log((obj.a+2.*(x-obj.x).*cos(obj.rot)+2.*(y-obj.y).*sin(obj.rot)).^2+(obj.b+2.*(y-obj.y).*cos(obj.rot)-2.*(x-obj.x).*sin(obj.rot)).^2).*(obj.a-obj.b+2.*(x-obj.x-y+obj.y).*cos(obj.rot)+2.*(x-obj.x+y-obj.y).*sin(obj.rot)).*(obj.a+obj.b+2.*(x-obj.x+y-obj.y).*cos(obj.rot)+2.*(-x+obj.x+y-obj.y).*sin(obj.rot))+4.*atan((obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot))./(obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot))).*(obj.b-2.*(y-obj.y).*cos(obj.rot)+2.*(x-obj.x).*sin(obj.rot)).*(obj.a-2.*(x-obj.x).*cos(obj.rot)-2.*(y-obj.y).*sin(obj.rot)));
        end
    end
    
end