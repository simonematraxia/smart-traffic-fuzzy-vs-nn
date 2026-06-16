function controller_init
    ttInitKernel('prioFP');
    
    % Initial data for the controller
    data.fis = readfis('green_extend.fis'); % .fis file (fuzzy logic)

    data.S1state = 'red';        % Initial state for traffic light 1
    data.S1duration = 0;         % Current duration for traffic light 1

    data.S2state = 'red';        % Initial state for traffic light 2
    data.S2duration = 0;         % Current duration for traffic light 2

    data.S3state = 'red';        % Initial state for traffic light 3
    data.S3duration = 0;         % Current duration for traffic light 3
    
    % Task period (in this case, every second)
    period = 1;
    
    % Creation of the periodic task
    starttime = str2double(get_param(bdroot,'StartTime'));
    data.simStartTime = starttime;
    ttCreatePeriodicTask('time_calculation', starttime, period, 'controller_script_NN', data); % for the NN version use 'controller_script_NN', otherwise 'controller_script'
end