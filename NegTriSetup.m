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
m2html('mfiles','src','ignoredDir','m2html',...
    'htmldir','docs', 'recursive','on', 'global','on',...
    'graph','on','globalHypertextLinks','on','verbose','off');
end