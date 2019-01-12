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

for inputFile = inputFiles'
    % Get input file path.
    inputFilePath = fullfile(inputFile.folder,inputFile.name);
    display(inputFilePath);
    
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
    % Display an overview panel.
    imoverview(hImage)
    
    %% Loop until the user skips to the next image.
    iParticle = 0;
    while true
        iParticle = iParticle+1;
        
        % Let the user define the outline of an object.
        [xList,yList] = ginput_modified();
        
        % Get number of points.
        nPoints = numel(xList);
        
        if nPoints >= 7   % For 7+ points fit an ellipse.
            
            % Fit the points with an ellipse.
            EllipseParameterList_px_temp = fit_ellipse(xList,yList);
            
            % Check if the fit was succesful.
            if ~isempty(EllipseParameterList_px_temp.a) % Success.
                
                % Store parameters.
                EllipseParameterList_px(iParticle) = ...
                    EllipseParameterList_px_temp; %#ok<SAGROW>
                
                % Draw ellipse.
                lastPlotHandle = draw_ellipse( ...
                    EllipseParameterList_px(iParticle), ...
                    hAxis);
            else % Fail.
                % Decrement particle counter.
                iParticle = iParticle-1;
            end
            
        elseif nPoints >= 3   % For 3-6 points fit a circle.
            
            % Fit circle.
            EllipseParameterList_px_temp = fit_circle([xList,yList]);
            
            % Check if
            if ~isempty(EllipseParameterList_px_temp.a)
                EllipseParameterList_px(iParticle) = ...
                    EllipseParameterList_px_temp; %#ok<SAGROW>
            end
            
            % Draw the circle.
            lastPlotHandle = ...
                draw_ellipse(EllipseParameterList_px(iParticle),hAxis);
        else
            % Construct a question dialog with three options
            choice = questdlg('How would you like to continue?', ...
                'Image Menu', ...
                'Continue','Undo Last Circle','Next Image', ...
                'Continue');
            % Handle response
            switch choice
                case 'Continue'
                    iParticle = iParticle-1;
                case 'Undo Last Circle'
                    delete(lastPlotHandle)
                    EllipseParameterList_px = ...
                        EllipseParameterList_px(1:iParticle-1);
                    iParticle = iParticle-1;
                case 'Next Image'
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
    save(outputFilePath,'EllipseParameterList_px');
    
    %% Close current image.
    close(hFigure);
    
    %% Clear EllipseParameterList_px
    EllipseParameterList_px(:) = [];
    
end
