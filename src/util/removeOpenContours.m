function S = removeOpenContours( S )
% REMOVEOPENCONTOURS Remove contours with open contour lines
%   N = REMOVEOPENCONTOURS(S) processes a structure array of contours and
%   identifies which contours are closed. Open contours are removed from
%   the returned structure array.
%
%   See also EXTRACT_CONTOURC

allxi = arrayfun(@(v)v.x(1),S);
allxe = arrayfun(@(v)v.x(end),S);
allyi = arrayfun(@(v)v.y(1),S);
allye = arrayfun(@(v)v.y(end),S);
closd = ( allxi == allxe ) & ( allyi == allye );
S = S(closd);

end