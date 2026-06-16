function S1_init
    ttInitKernel('prioFP');

    % Initial data for the traffic light
    data.traffic_light_id = 1;      % Traffic light ID (specific to each kernel)

    % Task period (in this case, every second)
    period = 1;

    data.lastState = 1;        % red as initial state (1 = red)
    data.lostCount = 0;        % lost packets counter
    
    % Creation of the periodic task
    starttime = str2double(get_param(bdroot,'StartTime'));
    ttCreatePeriodicTask('traffic_light_1', starttime, period, 'traffic_light_script', data);
end