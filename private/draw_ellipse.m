function plot_handle = draw_ellipse( ellipse_t,axis_handle )
% DRAW_ELLIPSE Based on the fit_ellipse function.

% check if we need to plot an ellipse with it's axes.
    isHoldOn = ishold;
    hold on;
    cObj = onCleanup(@()preserveHold(isHoldOn)); % Preserve original hold state
    
    % rotation matrix to rotate the axes with respect to an angle phi
    cos_phi = cos( ellipse_t.phi );
    sin_phi = sin( ellipse_t.phi );    
    R = [ cos_phi sin_phi; -sin_phi cos_phi ];
    
    % the axes
    ver_line        = [ [ellipse_t.X0 ellipse_t.X0]; ellipse_t.Y0+ellipse_t.b*[-1 1] ];
    horz_line       = [ ellipse_t.X0+ellipse_t.a*[-1 1]; [ellipse_t.Y0 ellipse_t.Y0] ];
    
    % the ellipse
    theta_r         = linspace(0,2*pi);
    ellipse_x_r     = ellipse_t.X0 + ellipse_t.a*cos( theta_r );
    ellipse_y_r     = ellipse_t.Y0 + ellipse_t.b*sin( theta_r );
    rotated_ellipse = R * [ellipse_x_r;ellipse_y_r];
    
    % draw
    hold_state = get( axis_handle,'NextPlot' );
    set( axis_handle,'NextPlot','add' );
    plot_handle = plot( rotated_ellipse(1,:),rotated_ellipse(2,:),'y' );

    set( axis_handle,'NextPlot',hold_state );
end

function preserveHold(wasHoldOn)
% Function for preserving hold behavior on exit
if ~wasHoldOn
    hold off
end

end