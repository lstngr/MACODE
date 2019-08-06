function varargout = triangularity(obj)
% TRIANGULARITY Estimate the triangularity of a magnetic configuration
%   t = TRIANGULARITY(obj) returns the mean triangularity of a magnetic
%   configuration (mConf) handle. The mean triangularity is the sum of the
%   upper and lower triangularities divided by two.
%
%   [t,u,l] = TRIANGULARITY(obj) also returns the upper and lower
%   triangularities of obj.
%
%   See also MCONF

assert(~isempty(obj.magR));
nargoutchk(0,3);
triUpper = (obj.magR.Rgeo - obj.magR.Rupper)/obj.a;
triLower = (obj.magR.Rgeo - obj.magR.Rlower)/obj.a;
tri      = (triUpper+triLower)/2;
varargout = {tri,triUpper,triLower};
varargout = varargout(1:max(1,nargout));
end