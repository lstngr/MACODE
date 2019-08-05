classdef current < matlab.mixin.SetGet & matlab.mixin.Heterogeneous
    % CURRENT   Object describing an electrical current
    %   This abstract superclass constitutes the base class for one dimensional
    %   current objects. Such objects must be described by (at least) a
    %   position in two dimensional space, and an electrical current value.
    %   It provides magnetic field expressions, as well as poloidal flux
    %   functions handles.
    
    properties(GetAccess=public,SetAccess=private)
        x = 0; % Position of the current on the x-axis
        y = 0; % Position of the current on the y-axis
        
        % PARENT - Handle to a parent current
        % This variable stores a handle to another current object. When not
        % empty, the current value of the class is computed as a fraction
        % of the parent's current.
        Parent = currentWire.empty();
        
        % CHILDREN - Array of handle to child currents
        % If a current has a non-empty parent handle, then, the parent
        % handle contains this current in its CHILDREN array.
        Children = currentWire.empty();
    end
    
    properties(Access=public)
        isPlasma = false; % Property is true if the current is a plasma current
    end
    
    properties(Dependent,Access=public)
        % CURR - Value of the electrical current
        % This property is computed in dependence of a parent being set or
        % not. This distinction is however not relevant for a typical user.
        curr
    end
    
    properties(Access=protected)
        % C - Low-level current
        % If the Parent property is empty, C is the value of the electrical
        % current. If Parent is set, C act as a multiplicative factor to
        % the parent's current when the object's curr property is
        % requested.
        c = 1;
    end
    
    methods
        function obj = current(x,y,c,varargin)
            % CURRENT Constructor of the current class
            %   h = CURRENT(x,y,c) returns a current handle. x and y are
            %   scalars indicating the current's position. c is the value
            %   of the electrical current.
            %
            %   h = CURRENT(x,y,c,p) returns a current related to the
            %   current handle p. c now represents a multiplicative factor
            %   instead of a current. The electrical current is evaluated
            %   to the parent's current multiplied by c. The Parent and
            %   Children properties of both h and p are updated.
            narginchk(3,4);
            obj.x = x;
            obj.y = y;
            obj.c = c;
            if nargin==4
                relCur = varargin{1};
                assert(~isempty(relCur) && isa(relCur,'current'));
                obj.Parent = relCur;
                if isempty(obj.Parent.Children)
                    obj.Parent.Children = obj;
                else
                    obj.Parent.Children(end+1) = obj;
                end
            end
        end
        
        function delete(obj)
            % DELETE Current destructor
            %   Destroys the class and updates Parent-Children
            %   relationships. If the current has children, their parent is
            %   emptied and their <a href="matlab:doc('current/c')">c</a>
            %   property is updated to behave independently. If the current
            %   has a parent, the parent's children array is also updated.
            
            % Delete parental reference in child wires, and take care of
            % current computation
            for child=obj.Children
                childCurr = child.curr;
                child.Parent = currentWire.empty();
                child.curr = childCurr;
            end
            % Delete the object handle in the parent's reference
            if ~isempty(obj.Parent)
                for child=obj.Parent.Children
                    me = (obj.Parent.Children == obj);
                    obj.Parent.Children(me) = [];
                end
            end
        end
        
        function set.x(obj,x)
            validateattributes(x,{'double'},{'scalar'})
            obj.x = x;
        end
        
        function set.y(obj,y)
            validateattributes(y,{'double'},{'scalar'})
            obj.y = y;
        end
        
        function set.isPlasma(obj,p)
            validateattributes(p,{'logical'},{'scalar'})
            obj.isPlasma = p;
        end
        
        function set.c(obj,c)
            validateattributes(c,{'double'},{'scalar'})
            obj.c = c;
        end
        
        function set.curr(obj,c)
            validateattributes(c,{'double'},{'scalar'})
            obj.c = c;
        end
        
        function curr = get.curr(obj)
            % NOTE - Cannot access dependent property, even from parent or
            % children, when getting it. Problematic in the fictive case
            % where
            %
            %   cur1 = currentWire(0,0,1);
            %   cur2 = currentWire(1,1,0.5,cur1);
            %   cur3 = currentWire(2,2,0.5,cur2);
            %   disp(cur3.curr)
            %
            % To compute the third current, we need not return cur2.c *
            % cur3.c, but cur1.c*cur2.c*cur3.c (due to the chain
            % dependency).
            % The loop below avoids reffering to curr with a "travelling
            % while loop".
            idx = 1;
            currAll(idx) = obj.c;
            parent = obj.Parent;
            while ~isempty(parent)
                idx = idx + 1;
                currAll(idx) = parent.c;
                parent = parent.Parent;
            end
            curr = prod(currAll);
        end
    end
    
    methods(Abstract,Access=public)
        % MAGFIELDX X-Component of the magnetic field
        %   bx = MAGFIELDX(x,y) returns the x-component of the magnetic
        %   field of the current distribution. x and y are same sized
        %   numerical variables. The ouput variable, bx, has the same
        %   size as x and y.
        bx = magFieldX(obj,x,y);
        
        % MAGFIELDY Y-Component of the magnetic field
        %   by = MAGFIELDY(x,y) returns the y-component of the magnetic
        %   field of the current distribution. x and y are same sized
        %   numerical variables. The ouput variable, by, has the same
        %   size as x and y.
        by = magFieldY(obj,x,y);
        
        % FLUXFX Poloidal flux function of the current
        %   flx = FLUXFX(x,y) returns the poloidal magnetic flux function
        %   of the current distribution. x and y are same sized numerical
        %   variables. The ouput variable, p, has the same size as x and
        %   y.
        flx = fluxFx(obj,x,y,R);
    end
    
    methods(Sealed)
        function varargout = eq(A,B)
            varargout{1:nargout} = eq@handle(A,B);
        end
    end
    
    methods (Static, Sealed, Access = protected)
        function default_object = getDefaultScalarElement
            default_object = currentWire(0,0,0);
            % Since the current class is abstract, need to define a default
            % element when building current arrays which is of a concrete
            % type!
        end
    end
        
end