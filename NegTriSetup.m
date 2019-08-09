function NegTriSetup(varargin)
% NEGTRISETUP Sets up the negative triangularity project
%   NEGTRISETUP makes sure required scripts and paths are added to MATLAB's
%   userpath.
%
%   NEGTRISETUP('MakeDocs',true) also generates documentation for the
%   toolbox.

% TODO - Add other things that NEGTRISETUP might do!

%% Parse varargin
% Defaults
defaultMakeDocs = false;

% Parser
p = inputParser;
addParameter(p,'MakeDocs',defaultMakeDocs,@(x)validateattributes(x,{'logical'},{'scalar'}))

%Processing
parse(p,varargin{:})

%% Add the negative triangularity project to the userpath
% Request the current's script location with <matlab:doc('mfilename') mfilename>
% and add required subfolders to the path.
script_path     = mfilename('fullpath');	% Get full setup path
[script_path,~] = fileparts(script_path);	% Strip the script name
addpath( script_path,...                    % Add folders to path
    genpath([script_path,filesep,'src']),...
    genpath([script_path,filesep,'examples']))

%% Check for pitfalls
sExpint = which('expint');
assert(~isempty(strfind(sExpint,'toolbox/matlab')))

%% Generate M2HTML documentation for everybody!
if ~p.Results.MakeDocs
    % If no documentation is required, exit here
    return;
end

% Warn about configuration being generated
waitfor(...
    msgbox({'Documentation will now be generated.',...
    'Please wait until all figures figures are closed.'},...
    'Documentation')...
    );
drawnow;

docs_path = [script_path,filesep,'docs'];
if ~exist(docs_path,'dir')
    error('MACODE:nonExistentFolder','Documentation folder seems to be missing.')
end
if ~exist([docs_path,filesep,'m2html'],'dir')
    mkdir([docs_path,filesep,'m2html'])
end

m2html('mfiles','src','ignoredDir','m2html',...
    'htmldir','docs/m2html', 'recursive','on', 'global','on',...
    'graph','on','globalHypertextLinks','on','verbose','off');

examples_path = [script_path,filesep,'examples'];
demos_path = [script_path,filesep,'docs',filesep,'demos'];
if ~exist(demos_path,'dir')
    mkdir(demos_path)
end
publish([examples_path,filesep,'currents.m'],'outputDir',demos_path);
publish([examples_path,filesep,'simpleDivertor.m'],'outputDir',demos_path);
publish([examples_path,filesep,'configDivertor.m'],'outputDir',demos_path);
publish([examples_path,filesep,'doubleXPoint.m']  ,'outputDir',demos_path);
publish([examples_path,filesep,'symbolicConfig.m'],'outputDir',demos_path);
publish([examples_path,filesep,'configCopy.m'],'outputDir',demos_path);
% Special option to capture full window figures
publishoptions = struct('format','html','outputDir',demos_path,...
    'figureSnapMethod','entireFigureWindow');
publish([examples_path,filesep,'parameterScan.m'],publishoptions);

% Publish startpage
png_path = [demos_path,filesep,'configDivertor_02.png'];
if exist(png_path,'file')
    cp_path = [docs_path,filesep,'startImg.png'];
    copyfile(png_path,cp_path);
end
publish([examples_path,filesep,'startPage.m'],'outputDir',docs_path);

% Cleanup
close all
evalin('base','clear all')
end