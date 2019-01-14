% Start with a tidy workspace.
clear;
close all;

% Parameters.
inputFolder = 'testimages';
inputFileFilter = '*.tif';

% Create output folder.
outputFolder = inputFolder;
createdirectory(outputFolder);

% Create a list of all input folders.
inputFiles = dir(fullfile(inputFolder,inputFileFilter));

% Display help window.
hHelp = figure( ...
    'Name','Help', ...
    'NumberTitle','off');

helpText = { ...
    'zoom in: +' ...
    'zoom out: -' ...
    'reset zoom: 0' ...
    '' ...
    'move center of view: right mouse button', ...
    '' ...
    'place point: left mouse button' ...
    'remove last point: middle mouse button' ...
    '' ...
    'next particle: enter' ...
    'backspace: remove last annotation' ...
    'next image: escape'};

hHelpText = uicontrol( ...
    hHelp, ...
    'style','text', ...
    'string',helpText);
hHelpText.Units = 'normalized';
hHelpText.Position = [0 0 1 1];

for inputFile = inputFiles'
    clear('EllipseParameterList_px');
    lastPlotHandles = gobjects(0);
    
    % Get input file path.
    inputFilePath = fullfile(inputFile.folder,inputFile.name);
    
    % Read image.
    image = imread(inputFilePath);
    
    % Convert image to grayscale if necessary.
    if ~ismatrix(image)
        image = rgb2gray(image);
    end
    
    %% Create GUI.
    % Create figure.
    hFigure = figure( ...
        'Name',inputFilePath, ...
        'NumberTitle','off');
    % Create axes object.
    hAxis = axes;
    % Show image.
    hImage = imshow(image, ...
        'Border','tight', ...
        'InitialMagnification',200, ...
        'Parent',hAxis);
    % Create interactive scroll panel.
    hScrollPanel = imscrollpanel(hFigure,hImage);
    
    % Display overview panel.
    hOverview = imoverview(hImage);
    % Position overview panel on the top left of the main window.
    hOverview.Position(2) = ....
        hFigure.Position(2)+hFigure.Position(4)-hOverview.Position(3);
    
    % Position help panel on the top right of the main window.
    hHelp.Position(1) = hFigure.Position(1)+hFigure.Position(3)+15;
    hHelp.Position(2) = hFigure.Position(2);
    hHelp.Position(4) = hFigure.Position(4);
    hHelp.Position(3) = 200;
    
    % Make the main window the current figure.
    figure(hFigure)
    
    %% Loop until the user skips to the next image.
    iParticle = 0;
    while true
        iParticle = iParticle+1;
        
        % Let the user define the outline of an object.
        [xList,yList,pressedKey,wasError] = ginput_modified();
        
        if wasError
            if ishandle(hFigure)
                close(hFigure)
            end
            
            if ishandle(hHelp)
                close(hHelp)
            end
            
            return
        end
        
        % Get number of points.
        nPoints = numel(xList);
        
        if strcmp(pressedKey,'backspace')
            
            if ~isempty(lastPlotHandles)
                delete(lastPlotHandles(end))
                lastPlotHandles(end) = [];
                EllipseParameterList_px = ...
                    EllipseParameterList_px(1:end-1);
                iParticle = iParticle-2;
            end
            
        elseif nPoints >= 7   % For 7+ points fit an ellipse.
            
            % Fit the points with an ellipse.
            EllipseParameterList_px_temp = fit_ellipse(xList,yList);
            
            % Check if the fit was succesful.
            if ~isempty(EllipseParameterList_px_temp.a) % Success.
                
                % Store parameters.
                EllipseParameterList_px(iParticle) = ...
                    EllipseParameterList_px_temp;
                
                % Draw ellipse.
                lastPlotHandles(end+1) = draw_ellipse( ...
                    EllipseParameterList_px(iParticle), ...
                    hAxis); %#ok<SAGROW>
            else % Fail.
                % Decrement particle counter.
                iParticle = iParticle-1;
            end
            
        elseif nPoints >= 3   % For 3-6 points fit a circle.
            
            % Fit circle.
            EllipseParameterList_px_temp = fit_circle([xList,yList]);
            
            % Check if the fit was succesful.
            if ~isempty(EllipseParameterList_px_temp.a)
                EllipseParameterList_px(iParticle) = ...
                    EllipseParameterList_px_temp;
            else % Fail.
                % Decrement particle counter.
                iParticle = iParticle-1;
            end
            
            % Draw the circle.
            lastPlotHandles(end+1) = ...
                draw_ellipse(EllipseParameterList_px(iParticle),hAxis); %#ok<SAGROW>
            
        else
            
            % Construct a question dialog with two options
            choice = questdlg('Next image?', ...
                'Next image?', ...
                'yes','no', ...
                'no');
            % Handle response
            switch choice
                case 'no'
                    iParticle = iParticle-1;
                case 'yes'
                    break;
            end
            
        end
    end
    
    % Restore view.
    zoom('reset');
    
    %% Store data
    % Construct output filename
    [~,outputFileName,~] = fileparts(inputFile.name);
    outputFileName = [outputFileName '_manual_analysis.mat']; %#ok<AGROW>
    
    outputFilePath = fullfile(outputFolder,outputFileName);
    
    % Write data
    if exist('EllipseParameterList_px','var')
        save(outputFilePath,'EllipseParameterList_px');
    end
    
    %% Close current image.
    if ishandle(hFigure)
        close(hFigure)
    end
end

% Close help figure.
if ishandle(hHelp)
    close(hHelp)
end
