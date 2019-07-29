classdef current < handle & matlab.mixin.Heterogeneous
    
    properties(GetAccess=public,SetAccess=private)
        x = 0;
        y = 0;
        Parent = currentWire.empty();
        Children = currentWire.empty();
    end
    
    properties(Dependent)
        curr
    end
    
    properties(Access=protected)
        c = 1;
    end
    
    methods
        function obj = current(x,y,c,varargin)
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
            % Delete parental reference in child wires, and take care of
            % current computation
            for child=obj.Children
                childCurr = child.curr;
                child.Parent = [];
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
        
        function varargout = eq(A,B)
            varargout{1:nargout} = eq@handle(A,B);
        end
        
        function set.x(obj,x)
            obj.x = x;
        end
        
        function set.y(obj,y)
            obj.y = y;
        end
        
        function set.c(obj,c)
            obj.c = c;
        end
        
        function set.curr(obj,c)
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
    
    methods (Abstract)
        bx = magFieldX(obj,x,y);
        by = magFieldY(obj,x,y);
        flx = FluxFx(obj,x,y,R);
    end
    
    methods (Static, Sealed, Access = protected)
        function default_object = getDefaultScalarElement
            default_object = currentWire(0,0,0);
        end
    end
        
end