function varargout = fig2png(varargin)
% FIG2PNG Batch export of figures to PNG
%   FIG2PNG exports all the figure files found in the current folder to the
%   PNG file format. Original figures are not deleted.
%
%   FIG2PNG(path) performs the same operation as above in the directory
%   specified by path.
%
%   files = FIG2PNG(...) returns a list of the files that were exported.
%
%   See also SAVEAS

narginchk(0,1)
nargoutchk(0,1)
varargout = {};

if nargin==1
    path = varargin{1};
    assert(exist(path,'dir'));
    oldPath = pwd;
    cd(path)
else
    path = pwd;
end

fs=dir('*.fig');

if nargout==1
    varargout{1} = cell(1,length(fs));
    idx = 1;
end

for f={fs.name}
    h=openfig(f{:},'invisible');
    nn = strrep(f{:},'fig','png');
    saveas(h,nn);
    if nargout==1
        varargout{1}{idx} = fullfile(path,nn);
        idx = idx + 1;
    end
    close(h)
end

if nargin==1
    cd(oldPath);
end

end