function S = removeOpenContours( S )
% Takes an input contour structure array and removes closed contours

allxi = arrayfun(@(v)v.x(1),S);
allxe = arrayfun(@(v)v.x(end),S);
allyi = arrayfun(@(v)v.y(1),S);
allye = arrayfun(@(v)v.y(end),S);
closd = ( allxi == allxe ) & ( allyi == allye );
S = S(closd);

end