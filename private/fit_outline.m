function [outputArg1,outputArg2] = fit_outline(xList,yList)
%FIT_OUTLINE Summary of this function goes here
%   Detailed explanation goes here
        % Let the user define the outline of an object.
        
        
        [xList,yList] = ginput_modified();
        
        % Get number of points.
        nPoints = numel(xList);
        
        if nPoints >= 7   % For 7+ points fit an ellipse.
            
            % Fit the points with an ellipse.
            Parameters_px_temp = fit_ellipse(xList,yList);
            
            % Check if the fit was succesful.
            if ~isempty(Parameters_px_temp.a) % Success.
                
                % Store parameters.
                ParameterList_px(iParticle) = Parameters_px_temp; %#ok<SAGROW>
                
                % Draw ellipse.
                lastPlotHandle = draw_ellipse( ...
                    ParameterList_px(iParticle), ...
                    hAxis);
            else % Fail.
                % Decrement particle counter.
                iParticle = iParticle-1;
            end
            
        elseif nPoints >= 3   % For 3-6 points fit a circle.
            
            % Fit circle.
            Parameters_px_temp = CircleFitByPratt([xList,yList]);
            
            % Check if
            if ~isempty(Parameters_px_temp.a)
                ParameterList_px(iParticle) = Parameters_px_temp; %#ok<SAGROW>
            end
            
            % Draw the circle.
            lastPlotHandle = draw_ellipse(ParameterList_px(iParticle),hAxis);
end

