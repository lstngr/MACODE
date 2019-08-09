%% Copying Currents and Configurations
% Currents and configurations (mConf) objects inherit their properties from
% handle classes. This means that when assigning a copy of the handle
% using the equality operator, the content of the object is not actually
% copied.
%
% The |==| operator will behave accordingly and return |true| only when the
% handles are pointing to the same object in memory (not if the objects'
% properties are equal).

wire  = currentWire(0,0,1);
wire2 = wire;
wire3 = currentWire(0,0,1);

if wire == wire2
    disp('wire2 is a handle copy of wire.')
else
    disp('wire2 is different from wire.')
end

if wire == wire3
    disp('wire3 is a handle copy of wire.')
else
    disp('wire3 is different from wire.')
end

%%
% So what if you need to make a "deep" copy of a given handle, which just
% duplicates the content in memory? For this purpose, the |current| class
% also inherits the |matlab.mixin.Copyable| superclass, which allows a
% shallow copy of a handle object.
%
% The behavior of this copy method is modified such that:
%
% # When an independent current is passed, the copy method's behavior is
% similar to the one of the superclass, |matlab.mixin.Copyable|.
% # When a current depends on a Parent, the Parent is not copied. However,
% in the Parent's Children array, a reference to the new current is added.
% # When other currents depend on the copied object, a (recursive) deep
% copy is performed on those. This means all currents below the copied
% object in the Parent-Children hieararchy are also copied.

% wire is the parent current of child
child = currentWire(1,1,1,wire);

%%%%% RULE #2 %%%%%
fprintf('\nRULE 2\nNumber of children in ''wire'': %u\n',numel(wire.Children))
% Make a copy of the child
childCopy = copy(child);
% Check child and childCopy parents are the same
if child.Parent == childCopy.Parent
    disp('Handles ''child'' and ''childCopy'' have the same parent.')
end
% Parent knows about the two children
fprintf('Number of children in ''wire'': %u\n\n',numel(wire.Children))

%%%%% RULE #3 %%%%%
% Make a copy of the parent
wireCopy = copy(wire);
% We check that the copied current is different from the original.
% We check that their children were also copied.
if wireCopy ~= wire && wireCopy.Children(1) ~= wire.Children(1)
    fprintf(['RULE 3\nHandles ''wireCopy'' and ''wire'' are different, ',...
        'and so are their children!\n'])
end

%%
% The copy behavior of magnetic configuration (mConf) objects is very
% similar to the one of the currents, with a slight exception.
%
% An mConf object expects to be instanciated with a "closed set" of
% currents, which means that if some currents depend on a parent current,
% this current mandatorily needs to be included in the array that will be
% passed to the mConf constructor.
%
% By recursion, one can see that some of the included currents for mConf
% will be independent, and the rest of the passed currents will depend on
% them directly, or through multiple children.

cur_root = currentGaussian(0,0,1,1); % Root current
cur_root.isPlasma = true;
child1 = currentWire(1,1,1,cur_root); % First child
child2 = currentWire(2,2,1,cur_root); % Second child

% Perfectly fine. child1 exists, but is not used in the configuration.
goodConfig = mConf(10,[cur_root,child2]);

% Bad call, one must include the root current!
try
    badConfig = mConf(10,[child1,child2]);
catch ME
    disp(getReport(ME,'basic'))
end

%%
% Thus, the mConf copy behavior can be simplified a bit. It will first look
% for independent currents and copy those first. _However_, while parent
% currents are always included, some of their children may not. During the
% copy operation, all children of those root currents (including
% unnecessary ones for the configuration at hand) will firstly also be
% copied.
% The second step consists in iterating over the original configuration's
% currents, and identify which original child of the root currents
% corresponds to which newly created child.
%
% Once this comparison is done, the new configuration's current array can
% match the original object's.

config_copy = copy(goodConfig);

%%
% Inspect original currents array,
goodConfig.currents

%%
% Do the same for copied configuration,
config_copy.currents

%%
% We can also make sure these objects are different in memory.
disp('Are the copied currents the same in memory?')
disp(goodConfig.currents == config_copy.currents)

displayEndOfDemoMessage(mfilename)