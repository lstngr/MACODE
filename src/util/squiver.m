function varargout = squiver( X, Y, U, V, varargin )
% SQUIVER   Quiver Plot with Additional Styles
%   SQUIVER(X,Y,U,V) plots velocity vectors as arrows with components (U,V)
%   at the points (X,Y). The matrices X,Y,U,V must all be the same size and
%   contain corresponding position and velocity components (X and Y can
%   also be vectors to specify a uniform grid). SQUIVER automatically
%   scales the arrows to fit within the grid.
%
%   SQUIVER(X,Y,U,V,S) automatically scales the arrows to fit within the
%   grid and then stretches them by S.
%
%   SQUIVER(...,'PropertyName',PropertyValue) specifies property name and
%   property value pairs for the quiver objects the function creates.
%
%   H = SQUIVER(...) returns an axis handle.
%
%   Example:
%      [x,y] = meshgrid(-2:.2:2,-1:.15:1);
%      z = x .* exp(-x.^2 - y.^2); [px,py] = gradient(z,.2,.15);
%      contour(x,y,z,'k-'), hold on
%      squiver(x,y,px,py,1.5,'Style',{'w','c'},...
%          'Colormap','jet','FillArrowHead',true)
%      hold off, axis image, colorbar

% Check inputs
% ===============================
narginchk(4,+Inf);
nargoutchk(0,1);

% Parse inputs
% ===============================
% Definition of defaults
defaultScale = 1.0;
defaultStyle = 'Length';
defaultLineWidth = 0.5;
defaultHeadSize = 0.33;
defaultColor = 'b';
defaultColormap = 0.33;
isPositive = @(x) isnumeric(x)&&(x>0);
validationFcn = @(x) validateattributes(x,{'numeric'},{'2d'},'squiver');

% Running the parser
p = inputParser;
addRequired(p,'X',validationFcn);
addRequired(p,'Y',validationFcn);
addRequired(p,'U',validationFcn);
addRequired(p,'V',validationFcn);
addOptional(p,'S',defaultScale,isPositive);
addParameter(p,'Style',defaultStyle,@isstyle);
addParameter(p,'LineWidth',defaultLineWidth,isPositive);
addParameter(p,'MaxHeadSize',defaultHeadSize,isPositive);
addParameter(p,'Color',defaultColor,@iscolor);
addParameter(p,'Colormap',defaultColormap,@(x)colormap(x)); % Sets the colormap at the same time!
addParameter(p,'FillArrowHead',true,@(x)validateattributes(x,{'logical'},{'scalar'}));
parse(p,X,Y,U,V,varargin{:});

% Reading the results
X = p.Results.X;
Y = p.Results.Y;
U = p.Results.U;
V = p.Results.V;
S = p.Results.S;
Style = p.Results.Style;
if ~iscell(p.Results.Style)
    Style = {Style};
end
for is=1:length(Style)
    Style{is} = validatestring(Style{is},{'Length','Width','Color'},'squiver','Style');
end
Style = unique(Style);
LineWidth = p.Results.LineWidth;
HeadSize  = p.Results.MaxHeadSize;
Color     = p.Results.Color;
FillHead  = p.Results.FillArrowHead;
if ischar(Color)
    Color = str2rgb(Color);
end

% Verify assertions
% ===============================
% X,Y,U,V must be ready to use in quiver.
assert(isequal(size(X),size(Y)))
assert(isequal(size(U),size(V)))
if ~isequal(size(X),size(U))
    X = squeeze(X);
    Y = squeeze(Y);
    assert(ismatrix(X))
    [X,Y] = meshgrid(X,Y);
end
assert(isequal(size(X),size(U)))

% Remove NaN points from input
% ===============================
nanPoints = isnan(X) | isnan(Y) | isnan(U) | isnan(V);
X = X(~nanPoints); Y = Y(~nanPoints);
U = U(~nanPoints); V = V(~nanPoints);

% Figure out some "optimal" options
% ===============================
normUV     = hypot(U,V);
mVecLength = median(normUV);
mPointSep  = hypot(max(X)-min(X),max(Y)-min(Y))/sqrt(2)/numel(X);
baseScale  = mPointSep / mVecLength;

% Provide matching style with input
% ===============================
u = baseScale * S * U ./ normUV;
v = baseScale * S * V ./ normUV;
lwS = ones(size(X));
arrowColor = repmat(Color,[numel(X),1]);
if any(cellfun(@(x)strcmp(x,'Color'),Style))
    cm = colormap;
    colidx = round((normUV-min(normUV(:)))/range(normUV(:))...
        * (length(cm(:,1))-1)) + 1;
    arrowColor = cm(colidx,:);
end
if any(cellfun(@(x)strcmp(x,'Length'),Style))
    u = u .* normUV;
    v = v .* normUV;
end
if any(cellfun(@(x)strcmp(x,'Width'),Style))
   lwS = normUV / median(mVecLength);
end

% Plot an ugly ugly quiver
% ===============================
cax = newplot;
hold_state = ishold(cax);
hold(cax,'on');
hg = hggroup('Parent',cax,'DisplayName','squiver');
dn = get(hg,'Annotation');
le = get(dn,'LegendInformation');
set(le,'IconDisplayStyle','on');
set(hg,'Parent',cax);
for i=1:numel(X)
    plot([X(i),X(i)+u(i)], [Y(i),Y(i)+v(i)],...
        'Color',arrowColor(i,:),'LineWidth',lwS(i)*LineWidth,'Parent',hg)
    if FillHead
        patch([X(i)+u(i)-HeadSize*(u(i)+HeadSize*v(i));X(i)+u(i);X(i)+u(i)-HeadSize*(u(i)-HeadSize*v(i))],...
            [Y(i)+v(i)-HeadSize*(v(i)-HeadSize*u(i));Y(i)+v(i);Y(i)+v(i)-HeadSize*(v(i)+HeadSize*u(i))],...
            arrowColor(i,:),'EdgeColor',arrowColor(i,:),'LineWidth',lwS(i)*LineWidth,'Parent',hg)
    else
        plot([X(i)+u(i)-HeadSize*(u(i)+HeadSize*v(i));X(i)+u(i);X(i)+u(i)-HeadSize*(u(i)-HeadSize*v(i))],...
            [Y(i)+v(i)-HeadSize*(v(i)-HeadSize*u(i));Y(i)+v(i);Y(i)+v(i)-HeadSize*(v(i)+HeadSize*u(i))],...
            'Color',arrowColor(i,:),'LineWidth',lwS(i)*LineWidth,'Parent',hg)
    end
end
if any(cellfun(@(x)strcmp(x,'Color'),Style))
    set(cax,'CLim',[min(normUV(:)),max(normUV(:))])
end
if ~hold_state
    hold(cax,'off');
end

% Return created handles
% ===============================
varargout = {};
if nargout==1
    varargout{1} = cax;
end

end

function [] = iscolor(in)
% Checks if input is a color
if ischar(in)
    in = str2rgb(in);
end
validateattributes(in,{'numeric'},{'nonnan','row','numel',3},'squiver')
end

function [] = isstyle(in)
if ischar(in)
    in = {in};
end
validateattributes(in,{'cell','char'},{'vector'},'squiver')
end