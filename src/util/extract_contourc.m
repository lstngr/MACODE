function S = extract_contourc(C)
% EXTRACT_CONTOURC  Store contours in a cell array
%   S=EXTRACT_CONTOURC(C) processes a 2 rows matrix, C, output by MATLAB's
%   <a href="matlab:help('contourc')">contourc</a> function into a cell
%   array holding "contour structures". These structures have fields
%   'level','x' and 'y'. The contours and their point sare ordered in the
%   same manner as in C.
%
%   See also: CONTOURC

% DONE - Using a cell array to store single structures is inefficient.
% Better to store the output as a structure array directly!
% TODO - Update description

if(isempty(C))
    return;
end
assert(size(C,1)==2, 'Expected CONTOURC object.')

levels = {}; xs = {}; ys = {};

%% Extract contours
ic = 1; is = 1;
while true
    id = ic + 1; iu = id + C(2,ic) - 1;
    levels{is} = C(1,ic);
    xs{is} = C(1,id:iu);
    ys{is} = C(2,id:iu);
    ic = iu + 1;
    is = is + 1;
    if(ic > size(C,2))
        break;
    end
end

S = struct('level',levels,'x',xs,'y',ys);

end
