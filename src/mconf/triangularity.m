function varargout = triangularity(obj)
assert(~isempty(obj.magR));
nargoutchk(0,3);
triUpper = (obj.magR.Rgeo - obj.magR.Rupper)/obj.a;
triLower = (obj.magR.Rgeo - obj.magR.Rlower)/obj.a;
tri      = (triUpper+triLower)/2;
varargout = {tri,triUpper,triLower};
varargout = varargout(1:max(1,nargout));
end