function zoom(command)
%ZOOM Summary of this function goes here
%   Detailed explanation goes here

% Validate command.
validatestring(command,{'in','out','reset'});

% Get current magnification.
hScrollPanel = get(gcf,'children');
api = iptgetapi(hScrollPanel);
currentMagnification = api.getMagnification();

% Determine target magnification.
switch lower(command)
    case 'in'
        targetMagnification = currentMagnification*2;
    case 'out'
        targetMagnification = currentMagnification/2;
    case 'reset'
        targetMagnification = 1;
end

% Set magnification.
api.setMagnification(targetMagnification);
end

