%% Work on Magnetic Configurations with Symbolic Variables
% In order to implement a configuration's magnetic structure equations
% elsewhere (GBS for example), it might be handy to obtain equations where
% system parameters are displayed as variables. Such parameters could be
% coils locations and currents, etc.
%
% We go through the creation and retrieval of such expressions using the
% <matlab:doc('current') current> and <matlab:doc('mConf') mConf> classes.

%% Create a Symbolic System
% Suppose we want to replicate the simple divertor configuration once
% again, but start from fully symbolic expressions. We need to define two
% currents, the plasma's and a divertor one, including only symbolic
% variables. The currents can then be passed to a configuration object.
% Note that the constructors are exactly the same as when working with
% numerical variables.

% Define symbolic variables
xc  = sym('xc',[1,2],'real');   % Current locations (x)
yc  = sym('yc',[1,2],'real');   % Current locations (y)
cI  = sym('cI',[1,2],'real');   % Current intensities (I)
sgm = sym('sgm','real');        % Gaussian extension of the plasma current
R   = sym('R','real');          % Tokamak major radius

% Create currents
plasma = currentGaussian(xc(1),yc(1),cI(1),sgm);
plasma.isPlasma = true;
divertor = currentWire(xc(2),yc(2),cI(2),plasma);

% Create configuration
clear config % Make sure workspace is clean
config = mConf(R, [plasma,divertor]);

%% Obtain Field Equations from the Divertor
% Now that the currents and configuration are initialized, we may start
% by querying the magnetic structure of the divertor current. Instead of
% calling its |magFieldX/Y| and |fluxFx| methods, we call methods returning
% a symbolic form of the former functions evaluated at symbolic coordinate
% $(x,y)$. Below, we print the magnetic field components and poloidal flux
% function of the divertor current.
% Note the dependency on the plasma current coefficient |cI1|!

% Obtain field equations
bx = divertor.symMagFieldX;
by = divertor.symMagFieldY;
fx = divertor.symFluxFx(R);

% Display these
disp(['Bx = ',char(bx)])
disp(['By = ',char(by)])
disp(['Fx = ',char(fx)])

%%
% Note that symbolic variables with string |x| and |y| _must not_
% have been included in the variables from the former paragraph to avoid
% mixups. If you wish to use other characters than |x/y| for the evaluation
% point of the functions, consider the following code.
%
%   target_x = sym('xreq','real');
%   target_y = sym('yreq','real');
%   % Evaluate the field at symbolic coordinates (xreq,yreq)
%   bx = divertor.magFieldX(target_x,target_y);

%% Obtain Field Equations from the Magnetic Configuration
% The same procedure as the one highlighted in the previous paragraph can
% be used to query symbolic expressions for a whole configuration. The same
% remarks also apply if the name of the evaluation coordinates need to be
% changed.

% Obtain field equations
bx = config.symMagFieldX;
by = config.symMagFieldY;
fx = config.symFluxFx;

% Display these
disp(['Bx = ',char(bx)])
disp(['By = ',char(by)])
disp(['Fx = ',char(fx)])

%% Substitute Real Values in Symbolic Expressions
% Finally, one might want to check whether these expressions are accurate,
% and substitute numerical quantities in place of the symbolic variables.
% This is of course a needed step if implementing these equations in
% another code.
%
% First, we define two substitution arrays, one with the symbolic variables
% we want to replace, the other with the numerical values they're supposed
% to be assigned to. We only replace parameters concerning the coils and do
% not evaluate the actual fields on a grid yet.

% Perform substitutions to replicate a simple divertor
subOld = [xc,yc,cI,sgm,R];
subNew = [0,0,60,-10,1,0.5,4,150];
bx = subs(bx,subOld,subNew);
by = subs(by,subOld,subNew);
fx = subs(fx,subOld,subNew);

%%
% Then, a meshgrid is created on which quantities will be computed.
step = 6;
nx = linspace(-50,50,100);
ny = linspace(-20,120,120);
[X,Y] = meshgrid(nx,ny);
lX = X(1:step:end,1:step:end);
lY = Y(1:step:end,1:step:end);

%%
% Assuming the magnetic field expressions are not too complex, one can use
% the symbolic toolbox to generate inline function handles. We indicate
% |matlabFunction| that the handle should have two inputs, being the two
% coordinates that we did not replace yet.
x = sym('x','real');
y = sym('y','real');
hbx = matlabFunction(bx,'Vars',[x,y]);
hby = matlabFunction(by,'Vars',[x,y]);

%%
% The flux function is however trickier. Since the plasma current
% includes an exponential integral term, |matlabFunction| will fail to
% build a function handle. This is likely cause by a mix-up between
% MATLAB(R)'s |expint| function, which is defined differently in the
% symbolic toolbox.
%
% Instead of requesting a function handle, we use |vpa| to get a numerical
% approximation of the |expint| term, and subsitute the coordinates with
% the meshgrid created earlier.
nfx = subs(vpa(fx),{x,y},{X,Y});

%%
% In general, however, this approach should be avoided as the performance
% is poor during substitution.
%
% The configuration can now be plotted using standard commands. The simple
% divertor configuration is retrieved.
figure('Position',[10 10 968 420])
subplot(1,2,1)
quiver(lX,lY,hbx(lX,lY),hby(lX,lY),2)
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Magnetic Field','Interpreter','latex')
axis image
ax = subplot(1,2,2);
contourf(X,Y,nfx,40,'EdgeColor','none')
xlabel('$x$','Fontsize',14,'Interpreter','latex')
ylabel('$y$','Fontsize',14,'Interpreter','latex')
title('Poloidal Flux, $\psi$','Interpreter','latex')
colorbar
axis image

%% Committing a Symbolic Configuration
% A magnetic configuration which contains symbolic variables can't be
% committed. To check whether a configuration can be commit or not, use the
% following command:
config.checkCommit

%%
% If a commit can be performed, |Avail| is returned. When a commit has
% already been requested, and that the magnetic structure didn't undergo
% changes, |Done| is returned.
%
% In our case, |NotAvail| prevents any commit attempt due to symbolic
% variables. If you try to commit anyway, an error is thrown.
try
    config.commit;
catch ME
    fprintf('\nExpected error occured:\n')
    disp(getReport(ME))
end

displayEndOfDemoMessage(mfilename)