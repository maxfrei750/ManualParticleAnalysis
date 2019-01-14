function [out1,out2,out3,waserr] = ginput_modified(arg1)
%GINPUT Graphical input from mouse.
%   [X,Y] = GINPUT(N) gets N points from the current axes and returns
%   the X- and Y-coordinates in length N vectors X and Y.  The cursor
%   can be positioned using a mouse.  Data points are entered by pressing
%   a mouse button or any key on the keyboard except carriage return,
%   which terminates the input before N points are entered.
%
%   [X,Y] = GINPUT gathers an unlimited number of points until the
%   return key is pressed.
%
%   [X,Y,BUTTON] = GINPUT(N) returns a third result, BUTTON, that
%   contains a vector of integers specifying which mouse button was
%   used (1,2,3 from left) or ASCII numbers if a key on the keyboard
%   was used.
%
%   Examples:
%       [x,y] = ginput;
%
%       [x,y] = ginput(5);
%
%       [x, y, button] = ginput(1);
%
%   See also GTEXT, WAITFORBUTTONPRESS.

%   Copyright 1984-2015 The MathWorks, Inc.

out1 = []; out2 = []; out3 = []; y = [];

if ~matlab.ui.internal.isFigureShowEnabled
    error(message('MATLAB:hg:NoDisplayNoFigureSupport', 'ginput'))
end

% Check Inputs
if nargin == 0
    how_many = -1;
    b = [];
else
    how_many = arg1;
    b = [];
    if  ~isPositiveScalarIntegerNumber(how_many)
        error(message('MATLAB:ginput:NeedPositiveInt'))
    end
    if how_many == 0
        % If input argument is equal to zero points,
        % give a warning and return empty for the outputs.
        warning (message('MATLAB:ginput:InputArgumentZero'));
    end
end

% Get figure
fig = gcf;
drawnow;
figure(gcf);
%     plothandle_points = plot(out1,out2,'b.');
% Make sure the figure has an axes
gca(fig);

% Setup the figure to disable interactive modes and activate pointers.
initialState = setupFcn(fig);

% onCleanup object to restore everything to original state in event of
% completion, closing of figure errors or ctrl+c.
c = onCleanup(@() restoreFcn(initialState));

drawnow
char = 0;

% Initialize plothandle_points and plothandle_ellipse.
plothandle_points = [];
plothandle_ellipse = [];

while how_many ~= 0
    waserr = 0;
    try
        keydown = wfbp;
    catch %#ok<CTCH>
        waserr = 1;
    end
    if(waserr == 1)
        cleanup(c);
        return
    end
    % g467403 - ginput failed to discern clicks/keypresses on the figure it was
    % registered to operate on and any other open figures whose handle
    % visibility were set to off
    figchildren = allchild(0);
    if ~isempty(figchildren)
        ptr_fig = figchildren(1);
    else
        error(message('MATLAB:ginput:FigureUnavailable'));
    end
    %         old code -> ptr_fig = get(0,'CurrentFigure'); Fails when the
    %         clicked figure has handlevisibility set to callback
    if(ptr_fig == fig)
        if keydown
            char = get(fig, 'CurrentCharacter');
            button = abs(get(fig, 'CurrentCharacter'));
        else
            button = get(fig, 'SelectionType');
            if strcmp(button,'open')
                button = 4;
            elseif strcmp(button,'normal')
                button = 1;
            elseif strcmp(button,'extend')
                button = 2;
            elseif strcmp(button,'alt')
                button = 3;
            else
                error(message('MATLAB:ginput:InvalidSelection'))
            end
        end
        
        %% Quit gathering points.
        if(char == 13) % Return key
            % if the return key was pressed, char will == 13,
            % and that's our signal to break out of here whether
            % or not we have collected all the requested data
            % points.
            % If this was an early breakout, don't include
            % the <Return> key info in the return arrays.
            % We will no longer count it if it's the last input.
            out3 = 'return';
            break;
        end
        
        %% Abort
        if(char == 27) % Escape key
            clearplots(plothandle_points,plothandle_ellipse)
            out3 = 'escape';
            return
        end
        
        %% Abort
        if(char == 8) % Backspace
            clearplots(plothandle_points,plothandle_ellipse)
            out3 = 'backspace';
            return
        end
        
        %% Zoom
        if(char == uint8('+'))
            % Zoom in
            zoom('in');
            char = [];
            continue;
        end
        
        if(char == uint8('-'))
            % Zoom out
            zoom('out');
            char = [];
            continue;
        end
        
        if(char == uint8('0'))
            % Reset zoom
            zoom('reset');
            char = [];
            continue;
        end
        
        if(button == 4)
            % Do nothing.
            continue;
        end
        
        if(button == 3) % right mouse button
            axes_handle = gca;
            scrollpanel_handle = get(gcf,'children');
            api = iptgetapi(scrollpanel_handle);
            
            imagesize = [xlim;ylim];
            imagesize = [imagesize(1,2)-imagesize(1,1),imagesize(2,2)-imagesize(2,1)];
            
            bound_box = api.getVisibleImageRect();
            pt = get(axes_handle, 'CurrentPoint');
            
            new_location = [pt(1,1)- bound_box(3)/2 , pt(1,2)- bound_box(4)/2];
            new_location(new_location<0.5) = 0.5;
            if new_location(1)+bound_box(3) > imagesize(1)+0.5
                new_location(1) = imagesize(1)-bound_box(3)+0.5;
            end
            if new_location(2)+bound_box(4) > imagesize(2)+0.5
                new_location(2) = imagesize(2)-bound_box(4)+0.5;
            end
            api.setVisibleLocation(new_location)
            button = [];
            continue;
        end
        
        if(button == 2) % middle mouse button
            if length(out1)>=1
                out1(end)= [];
                y(end)= [];
                b(end) = [];
            end
            
            if length(out1)<3 && ~isempty(plothandle_ellipse)
                plothandle_ellipse.delete;
                plothandle_ellipse = [];
            end
        end
        
        axes_handle = gca;
        if ~isa(axes_handle,'matlab.graphics.axis.Axes')
            % If gca is not an axes, warn but keep listening for clicks.
            % (There may still be other subplots with valid axes)
            warning(message('MATLAB:Chart:UnsupportedConvenienceFunction', 'ginput', axes_handle.Type));
            continue
        end
        
        drawnow;
        
        if ~(button == 2)
            pt = get(axes_handle, 'CurrentPoint');
            how_many = how_many - 1;
            
            out1 = [out1;pt(1,1)]; %#ok<AGROW>
            y = [y;pt(1,2)]; %#ok<AGROW>
            b = [b;button]; %#ok<AGROW>
        else
            button=[];
        end
        
        %fit ellipse
        if length(out1) >= 3 && length(out1) < 7
            ellipse_t = fit_circle([out1,y]);
        elseif length(out1) >= 7
            ellipse_t = fit_ellipse(out1,y);
        end
        
        %plot input points
        if isempty(plothandle_points) && length(out1)>=1
            hold on;
            plothandle_points = plot(out1,y,'b.','XDataSource','out1','YDataSource','y','Parent',gca(fig));
        else
            refreshdata(plothandle_points,'caller')
        end
        
        if length(out1) >= 3 && ~isempty(ellipse_t.X0)
            % rotation matrix to rotate the axes with respect to an angle phi
            cos_phi = cos( ellipse_t.phi );
            sin_phi = sin( ellipse_t.phi );
            R = [ cos_phi sin_phi; -sin_phi cos_phi ];
            
            % the ellipse
            theta_r         = linspace(0,2*pi);
            ellipse_x_r     = ellipse_t.X0 + ellipse_t.a*cos( theta_r );
            ellipse_y_r     = ellipse_t.Y0 + ellipse_t.b*sin( theta_r );
            rotated_ellipse = R * [ellipse_x_r;ellipse_y_r];
            
            if isempty(plothandle_ellipse)
                hold on
                plothandle_ellipse = plot( rotated_ellipse(1,:),rotated_ellipse(2,:),'b-','XDataSource','rotated_ellipse(1,:)','YDataSource','rotated_ellipse(2,:)','Parent',gca(fig));
            else
                refreshdata(plothandle_ellipse,'caller')
            end
        end
        
    end
end

% Cleanup and Restore
cleanup(c);

if nargout > 1
    out2 = y;
    if nargout > 2
        out3 = b;
    end
else
    out1 = [out1 y];
end

clearplots(plothandle_points,plothandle_ellipse)

end

function clearplots(plothandle_points,plothandle_ellipse)
if isa(plothandle_points,'matlab.graphics.chart.primitive.Line')
    % Clear points
    delete(plothandle_points)
end

if isa(plothandle_ellipse,'matlab.graphics.chart.primitive.Line')
    % Clear ellipse
    delete(plothandle_ellipse)
end
end

function valid = isPositiveScalarIntegerNumber(how_many)
valid = ~ischar(how_many) && ...            % is numeric
    isscalar(how_many) && ...           % is scalar
    (fix(how_many) == how_many) && ...  % is integer in value
    how_many >= 0;                      % is positive
end

function key = wfbp
%WFBP   Replacement for WAITFORBUTTONPRESS that has no side effects.

fig = gcf;
current_char = []; %#ok<NASGU>

% Now wait for that buttonpress, and check for error conditions
waserr = 0;
try
    h=findall(fig,'Type','uimenu','Accelerator','C');   % Disabling ^C for edit menu so the only ^C is for
    set(h,'Accelerator','');                            % interrupting the function.
    keydown = waitforbuttonpress;
    current_char = double(get(fig,'CurrentCharacter')); % Capturing the character.
    if~isempty(current_char) && (keydown == 1)          % If the character was generated by the
        if(current_char == 3)                           % current keypress AND is ^C, set 'waserr'to 1
            waserr = 1;                                 % so that it errors out.
        end
    end
    
    set(h,'Accelerator','C');                           % Set back the accelerator for edit menu.
catch %#ok<CTCH>
    waserr = 1;
end

drawnow;



if(waserr == 1)
    set(h,'Accelerator','C');                          % Set back the accelerator if it errored out.
    error(message('MATLAB:ginput:Interrupted'));
end

if nargout>0, key = keydown; end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

function initialState = setupFcn(fig)

% Store Figure Handle.
initialState.figureHandle = fig;

% Suspend figure functions
initialState.uisuspendState = uisuspend(fig);

% Disable Plottools Buttons
initialState.toolbar = findobj(allchild(fig),'flat','Type','uitoolbar');
if ~isempty(initialState.toolbar)
    initialState.ptButtons = [uigettool(initialState.toolbar,'Plottools.PlottoolsOff'), ...
        uigettool(initialState.toolbar,'Plottools.PlottoolsOn')];
    initialState.ptState = get (initialState.ptButtons,'Enable');
    set (initialState.ptButtons,'Enable','off');
end

%Setup empty pointer
cdata = NaN(16,16);
hotspot = [8,8];
set(gcf,'Pointer','custom','PointerShapeCData',cdata,'PointerShapeHotSpot',hotspot)

% Create uicontrols to simulate fullcrosshair pointer.
initialState.CrossHair = createCrossHair(fig);


% Adding this to enable automatic updating of currentpoint on the figure
% This function is also used to update the display of the fullcrosshair
% pointer and make them track the currentpoint.
set(fig,'WindowButtonMotionFcn',@(o,e) dummy()); % Add dummy so that the CurrentPoint is constantly updated
initialState.MouseListener = addlistener(fig,'WindowMouseMotion', @(o,e) updateCrossHair(o,initialState.CrossHair));

% Get the initial Figure Units
initialState.fig_units = get(fig,'Units');
end

function restoreFcn(initialState,plothandle_points)
if ishghandle(initialState.figureHandle)
    delete(initialState.CrossHair);
    
    % Figure Units
    set(initialState.figureHandle,'Units',initialState.fig_units);
    
    set(initialState.figureHandle,'WindowButtonMotionFcn','');
    delete(initialState.MouseListener);
    
    % Plottools Icons
    if ~isempty(initialState.toolbar) && ~isempty(initialState.ptButtons)
        set (initialState.ptButtons(1),'Enable',initialState.ptState{1});
        set (initialState.ptButtons(2),'Enable',initialState.ptState{2});
    end
    
    % UISUSPEND
    uirestore(initialState.uisuspendState);
    
end
end

function updateCrossHair(fig, crossHair)
% update cross hair for figure.
gap = 3; % 3 pixel view port between the crosshairs
cp = hgconvertunits(fig, [fig.CurrentPoint 0 0], fig.Units, 'pixels', fig);
cp = cp(1:2);
figPos = hgconvertunits(fig, fig.Position, fig.Units, 'pixels', fig.Parent);
figWidth = figPos(3);
figHeight = figPos(4);

% Early return if point is outside the figure
if cp(1) < gap || cp(2) < gap || cp(1)>figWidth-gap || cp(2)>figHeight-gap
    return
end

set(crossHair, 'Visible', 'on');
thickness = 1; % 1 Pixel thin lines.
set(crossHair(1), 'Position', [0 cp(2) cp(1)-gap thickness]);
set(crossHair(2), 'Position', [cp(1)+gap cp(2) figWidth-cp(1)-gap thickness]);
set(crossHair(3), 'Position', [cp(1) 0 thickness cp(2)-gap]);
set(crossHair(4), 'Position', [cp(1) cp(2)+gap thickness figHeight-cp(2)-gap]);
end

function crossHair = createCrossHair(fig)
% Create thin uicontrols with black backgrounds to simulate fullcrosshair pointer.
% 1: horizontal left, 2: horizontal right, 3: vertical bottom, 4: vertical top
for k = 1:4
    crossHair(k) = uicontrol(fig, 'Style', 'text', 'Visible', 'off', 'Units', 'pixels', 'BackgroundColor', [1 0 0], 'HandleVisibility', 'off', 'HitTest', 'off'); %#ok<AGROW>
end
end

function cleanup(c)
if isvalid(c)
    delete(c);
end
end

function dummy(~,~)
end
