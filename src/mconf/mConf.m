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
    end
    
end