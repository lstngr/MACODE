function NegTriSetup
% NEGTRISETUP Sets up the negative triangularity project
%   NEGTRISETUP makes sure required scripts and paths are added to MATLAB's
%   userpath, builds the documentation if required, and does other things.

% TODO - Add other things that NEGTRISETUP might do!

%% Add the negative triangularity project to the userpath
% Request the current's script location with <matlab:doc('mfilename') mfilename>
% and add required subfolders to the path.
script_path     = mfilename('fullpath');	% Get full setup path
[script_path,~] = fileparts(script_path);	% Strip the script name
addpath( script_path,...                    % Add folders to path
    genpath([script_path,filesep,'src']),...
    genpath([script_path,filesep,'examples']))

%% Generate M2HTML documentation for everybody!
if ~exist([script_path,filesep,'docs'],'dir')
    mkdir([script_path,filesep,'docs'])
end
m2html('mfiles','src','ignoredDir','m2html',...
    'htmldir','docs', 'recursive','on', 'global','on',...
    'graph','on','globalHypertextLinks','on','verbose','off');

examples_path = [script_path,filesep,'examples'];
demos_path = [script_path,filesep,'docs',filesep,'demos'];
if ~exist(demos_path,'dir')
    mkdir(demos_path)
end
publish([examples_path,filesep,'currents.m'],'outputDir',demos_path);
publish([examples_path,filesep,'simpleDivertor.m'],'outputDir',demos_path);
publish([examples_path,filesep,'configDivertor.m'],'outputDir',demos_path);
end