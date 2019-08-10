function S = extract_contourc(C)
% EXTRACT_CONTOURC  Store contours in a structure array
%   S = EXTRACT_CONTOURC(C) processes a 2 rows matrix, C, output by MATLAB's
%   contourc function into a structure array. These structures have fields
%   'level','x' and 'y'. The contours and their points are ordered in the
%   same manner as in C.
%
%   See also: CONTOURC

if(isempty(C))
    return;
end
assert(size(C,1)==2,'mConf:wrongdim','Expected CONTOURC object.')

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
