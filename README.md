# Magnetic Configuration Designer
## What's this?
A set of functions and classes (aka. toolbox) for MATLAB&reg;. It aims at
computing magnetic equilibria for Tokamak reactors. This specific toolbox is
targeted to be used alongside the GBS code when implementing new magnetic
configurations.

The code is targeted to work with releases of MATLAB&reg; starting R2015a. It
depends on the core MATLAB&reg; functionalities, as well as the Symbolic Math
Toolbox.

## How do I get the code in MATLAB?
Navigate to the Git repository within MATLAB&reg;.
From here, make sure that the following folders exist: `docs`, `examples` and `src`.
If you miss one, there's a high chance something's already wrong.
Once this is done, also check the following files exist: `docs/helptoc.xml`,
`info.xml` and `demos.xml`. They will allow you to browse the code's
documentation once generated.

Then, run `MACODESetup('MakeDocs',true)`, which will generate the
documentation of the code on your workstation. Once this is done, the folder
should be in the path and you should be set.

## How do I use this code?
The code is documented accordingly within MATLAB&reg;. You can start by
querying the package's help by typing `help MACODE`, or browse the HTML
documentation using MATLAB&reg;'s `doc` command (look under _Supplemental
Software_).

Demonstration scripts are also available using the `demo` command, or from
MATLAB&reg;'s web browser (see previous paragraph).

## Organisational Remarks
The Git repository is organised as follows:

- The _master_ branch contains the last functional release of MACODE. It is
  meant to track only files relevant to magnetic configuration generation, and
  should not be used as a workspace to develop actual configurations.
- The _work_ branch is used when developing magnetic configurations and trying
  out the toolbox. The philosophy here is you should feel free to merge the
  _master_ into _work_ as often as you want to, however, _work_ should never be
  merged into any other branch.
- _feature_ branches are used when implementing new functionalities.
- _bugs_ branches are used to fix bugs not uncovered at the time of the feature
  implementation. You can also use this branch to fix consistencies issues
  between different parts of the code. I often solve bugs on the _master_
  branch if sufficiently convenient.

## Negative Triangularity
Negative trianguarity configurations are located on the _work_ branch. The
scripts there are decently commented to be understandable. If you have trouble
understanding them, I recommend checking out the toolbox's documentation.

By checking out to the _work_ branch, an additional folder, named `work`, should
appear. This folder will not be in your path by default, it contains additional
configurations. Note a README is also available there which describes them.
