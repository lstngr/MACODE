function varargout = triangularity(obj)
% TRIANGULARITY Estimate the triangularity of a magnetic configuration
%   t = TRIANGULARITY(obj) returns the mean triangularity of a magnetic
%   configuration (mConf) handle. The mean triangularity is the sum of the
%   upper and lower triangularities divided by two.
%
%   [t,u,l] = TRIANGULARITY(obj) also returns the upper and lower
%   triangularities of obj.
%
%   Note that TRIANGULARITY relies on the magR property of mConf, which in
%   turn is (partially) computed using MATLAB's contour detection
%   functionalities. In certain cases, configurations you would expect to
%   be totally symmetrical will display non-zero triangularity due to
%   numerical "errors" from contour detection. It is recommended to
%   increase 'OffsetScale' when committing if this behavior needs to be
%   avoided.
%
%   See also MCONF, MCONF/COMMIT

% Check if commit was done
assert(obj.checkCommit==commitState.Done)
nargoutchk(0,3);
triUpper = (obj.magR.Rgeo - obj.magR.Rupper)/obj.a;
triLower = (obj.magR.Rgeo - obj.magR.Rlower)/obj.a;
tri      = (triUpper+triLower)/2;
varargout = {tri,triUpper,triLower};
varargout = varargout(1:max(1,nargout));
end