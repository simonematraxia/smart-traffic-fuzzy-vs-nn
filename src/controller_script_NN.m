function [exectime, data] = controller_script_NN(segment, data)

persistent initialized; % Variable used by the controller during the first simulation clock
                        % to define which lane group gets priority to start with the green light.
                        % The logic ensures that the initial time assignment condition occurs only at the beginning:
                        % either for S1 and S2, or for S3.

persistent S1_2_total S3_total   % Total green times assigned in the current phase

persistent log_msg_sent log_hours_passed log_NN_timeS1_2 log_NN_timeS3 log_red_timeS1_2 log_red_timeS3; % Log variables to measure system performance

persistent ds_X ds_Y    % Neural network dataset: inputs and outputs

persistent intergreen_countdown pending_green % All-red pause between green phases

persistent netNN


MinGreen_S12 = 30;   % Minimum green time for S1/S2
MaxGreen_S12 = 90;   % Maximum green time for S1/S2
MinGreen_S3  = 30;   % Minimum green time for S3
MaxGreen_S3  = 90;   % Maximum green time for S3

% Initialize persistent variables during the first execution
% ============================================================
if isempty(log_msg_sent) 
    log_msg_sent = 0; % Number of messages sent
    log_hours_passed = 0; % Total simulation time (converted from seconds to hours on Line: 173)
    log_NN_timeS1_2 = []; % Calculated times for S1 and S2
    log_NN_timeS3 = []; % Calculated times for S3
    log_red_timeS1_2 = []; % Red times for S1 and S2
    log_red_timeS3 = []; % Red times for S3
    ds_X = []; % Fuzzy inputs for neural network training (current lane queue, current lane flow, and opposing lane queue)
    ds_Y = []; % Fuzzy outputs for neural network training (green time extensions)
    intergreen_countdown = 0; % 
    pending_green = '';       % 
end

if isempty(netNN)
    NN = load('green_extend_NN.mat','net');  % Load the 'net' variable
    netNN = NN.net;
end
% ============================================================

    switch segment
        case 1
            current_state = ttAnalogIn(5); % Current traffic light state (Normal: 1 | Flashing Yellow: 2)

            %----------------@DEBUG@------------------------------------------------
            %disp(['[', ttSimTimeStr(),'][Controller]: current state: ', num2str(current_state)])
            %-----------------------------------------------------------------------
            
            if(current_state == 1) % Normal state

                % Sensor reading (queue/flow) - used both for initial choice and
                % for potential extension
                % ============================================================
                queue_S12 = ttAnalogIn(1);
                flow_S12 = ttAnalogIn(2);
                queue_S3 = ttAnalogIn(3);
                flow_S3 = ttAnalogIn(4);
                % ============================================================

                %----------------@DEBUG@----------------------------------------------------------------
                %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Queue for S1/S2 lane: ', num2str(queue_S12)]);
                %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Flow for S1/S2 lane: ', num2str(flow_S12)]);
                %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Queue for S3 lane: ', num2str(queue_S3)]);
                %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Flow for S3 lane: ', num2str(flow_S3)]);
                %---------------------------------------------------------------------------------------

                if isempty(initialized) % Check if 'initialized' has not been set yet
                    initialized = 0;

                    %----------------@DEBUG@----------------------
                    %disp(['[', ttSimTimeStr(),'][Controller]: initialized = 0 ']);
                    %-----------------------------
                end
                
                %    Selection of who starts with green (only at the beginning)
                %    if queue_S3 > queue_S12 → S3 starts, otherwise S1/S2 starts
                % ============================================================
                if initialized == 0
                    if queue_S3 > queue_S12
                        % S3 starts
                        data.S3state  = 'green';
                        data.S3duration = MinGreen_S3;
                        S3_total      = MinGreen_S3;
                        data.S1state  = 'red';
                        data.S2state  = 'red';
                    else
                        % S1/S2 start
                        data.S1state  = 'green';
                        data.S2state  = 'green';
                        data.S1duration = MinGreen_S12;
                        data.S2duration = MinGreen_S12;
                        S1_2_total    = MinGreen_S12;
                        data.S3state  = 'red';
                    end
                    initialized = 1;
                end
                % ============================================================


                %------------------------------------------------------------------------------------------
                % Controller message legend (also present in the traffic light code at Line 20):
                %   [1, 4] = red light
                %   [2, 4] = yellow light
                %   [3, 4] = green light
                % Traffic lights use 1, 2, and 3 as analog outputs to expose their current state
                %------------------------------------------------------------------------------------------
                

                % INTERGREEN - 2 seconds of all-red between alternating green phases
                % ============================================================
                if intergreen_countdown > 0
                    intergreen_countdown = intergreen_countdown - 1;
                    ttSendMsg([1, 1], [1, 4], 1, 1);
                    ttSendMsg([1, 2], [1, 4], 1, 1);
                    ttSendMsg([1, 3], [1, 4], 1, 1);
                    log_msg_sent = log_msg_sent + 3;
                    exectime = 1;
                    return;
                elseif ~isempty(pending_green)
                    % Pause finished: activate the pending green light
                    if strcmp(pending_green, 'S3')
                        data.S3state = 'green';
                        data.S3duration = MinGreen_S3;
                        S3_total = MinGreen_S3;
                    else % 'S12'
                        data.S1state = 'green';
                        data.S2state = 'green';
                        data.S1duration = MinGreen_S12;
                        data.S2duration = MinGreen_S12;
                        S1_2_total = MinGreen_S12;
                    end
                    pending_green = '';
                end
                % ============================================================


                % LOGIC FOR ACTIVE S1 AND S2
                % ============================================================
                if strcmp(data.S1state, 'green') || strcmp(data.S1state, 'yellow') || strcmp(data.S2state, 'green') || strcmp(data.S2state, 'yellow')
                    
                    %----------------@DEBUG@----------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Light 1 active, remaining time: ', num2str(data.S1duration),' seconds.']);
                    %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Light 2 active, remaining time: ', num2str(data.S2duration),' seconds.']);
                    %---------------------------------------------------------------------------------------------------------

                    % Attempt extension when the green light is about to expire
                    if data.S1duration == 6 && S1_2_total < MaxGreen_S12
                       
                        queue_curr  = queue_S12;
                        flow_curr   = flow_S12;
                        queue_other = queue_S3;
    

                        ext = netNN([queue_curr; flow_curr; queue_other]);

                        % Save a sample into the NN dataset (S12 branch)
                        sample_in  = [queue_curr, flow_curr, queue_other]; 
                        sample_out = ext; % actual extension used
                        
                        ds_X = [ds_X; sample_in];
                        ds_Y = [ds_Y; sample_out];


                        ext = max(0, min(10, round(ext)));   % Extension in seconds (0..10)
                        if ext > 0
                            new_total = S1_2_total + ext;
                            if new_total > MaxGreen_S12
                                ext = MaxGreen_S12 - S1_2_total;
                                new_total = MaxGreen_S12;
                            end
                            data.S1duration = data.S1duration + ext;
                            data.S2duration = data.S2duration + ext;
                            S1_2_total    = new_total;
                        end

                        %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------------------------
                        % if ext ~= 0
                        %     fprintf('[%s][Controller] extension for S1/S2 = %.3fs\n', ttSimTimeStr(), ext);
                        % else
                        %     fprintf('[%s][Controller] no extension for S1/S2 (%.3fs), total green time for this cycle was %.0f seconds.\n', ttSimTimeStr(), ext, S1_2_total);
                        % end
                        %---------------------------------------------------------------------------------------------------------------------------------------------------------------------

                    end

                    if data.S1duration > 5
                        ttSendMsg([1, 1], [3, 4], 1, 1); % Message to traffic light 1 (in network 1) (1-bit length, priority 1)
                        ttSendMsg([1, 2], [3, 4], 1, 1); % Message to traffic light 2 (in network 1) (1-bit length, priority 1)
                        data.S1state = 'green';
                        data.S1duration = data.S1duration - 1;
                        data.S2state = 'green';
                        data.S2duration = data.S2duration - 1;
                    elseif data.S1duration > 0
                        ttSendMsg([1, 1], [2, 4], 1, 1);
                        ttSendMsg([1, 2], [2, 4], 1, 1);
                        data.S1state = 'yellow';
                        data.S1duration = data.S1duration - 1;
                        data.S2state = 'yellow';
                        data.S2duration = data.S2duration - 1;
                    elseif data.S1duration <= 0
                        % Log the actual green time used in this phase
                        if ~isempty(S1_2_total)
                            log_NN_timeS1_2 = [log_NN_timeS1_2; S1_2_total];
                            % Also log the red time for the opposing side (S3) = green/yellow S12 + intergreen (2 s)
                            log_red_timeS3 = [log_red_timeS3; (S1_2_total + 2)];
                        end

                        ttSendMsg([1, 1], [1, 4], 1, 1);
                        ttSendMsg([1, 2], [1, 4], 1, 1);
                        data.S1state = 'red';
                        data.S2state = 'red';

                        % Start 2-second intergreen before granting green to S3
                        intergreen_countdown = 1;
                        pending_green = 'S3';
                        S1_2_total = []; % Reset
                    end

                    log_msg_sent = log_msg_sent + 2; % Increment the number of sent messages by two (since we send messages to both S1 and S2)

                elseif strcmp(data.S1state, 'red') || strcmp(data.S2state, 'red')
                    ttSendMsg([1, 1], [1, 4], 1, 1);
                    ttSendMsg([1, 2], [1, 4], 1, 1);
                    log_msg_sent = log_msg_sent + 2; % Increment the number of sent messages
                end
                % ============================================================

                
                % LOGIC FOR ACTIVE S3
                % ============================================================
                if strcmp(data.S3state, 'green') || strcmp(data.S3state, 'yellow')

                    %----------------@DEBUG@-------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Controller]: Traffic Light 3 active, remaining time: ', num2str(data.S3duration),' seconds.']);
                    %------------------------------------------------------------------------------------------------------------------------

                    % Attempt extension when the green light is about to expire
                    if data.S3duration == 6 && S3_total < MaxGreen_S3
                        queue_curr  = queue_S3;
                        flow_curr   = flow_S3;
                        queue_other = queue_S12;
    
                        ext = netNN([queue_curr; flow_curr; queue_other]);
                      
                        % Save a sample into the NN dataset (S3 branch)
                        sample_in  = [queue_curr, flow_curr, queue_other]; 
                        sample_out = ext; % actual extension used

                        ds_X = [ds_X; sample_in];
                        ds_Y = [ds_Y; sample_out];


                        ext = max(0, min(10, round(ext)));
                        if ext > 0
                            new_total = S3_total + ext;
                            if new_total > MaxGreen_S3
                                ext = MaxGreen_S3 - S3_total;
                                new_total = MaxGreen_S3;
                            end
                            data.S3duration = data.S3duration + ext;
                            S3_total      = new_total;
                        end

                        %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------------------------
                        if ext ~= 0
                        %     fprintf('[%s][Controller] extension for S3 = %.3fs\n', ttSimTimeStr(), ext);
                        else
                        %     fprintf('[%s][Controller] no extension for S3 (%.3fs), total green time for this cycle was %.0f seconds.\n', ttSimTimeStr(), ext, S3_total);
                        end
                        %---------------------------------------------------------------------------------------------------------------------------------------------------------------------

                    end

                    if data.S3duration > 5
                        ttSendMsg([1, 3], [3, 4], 1, 1); % Message to traffic light 3 (in network 1) (1-bit length, priority 1)
                        data.S3state = 'green';
                        data.S3duration = data.S3duration - 1;
                    elseif data.S3duration > 0
                        ttSendMsg([1, 3], [2, 4], 1, 1); 
                        data.S3state = 'yellow';
                        data.S3duration = data.S3duration - 1;
                    elseif data.S3duration <= 0
                        % Log the actual green time used in this phase
                        if ~isempty(S3_total)
                            log_NN_timeS3 = [log_NN_timeS3; S3_total];
                            % Also log the red time for the opposing side (S12) = green/yellow S3 + intergreen (2 s)
                            log_red_timeS1_2 = [log_red_timeS1_2; (S3_total + 2)];
                        end

                        ttSendMsg([1, 3], [1, 4], 1, 1);
                        data.S3state = 'red';
                        
                        % Start 2-second intergreen before granting green to S1/S2
                        intergreen_countdown = 1;
                        pending_green = 'S12';
                        S3_total = []; % Reset
                    end    
                
                    log_msg_sent = log_msg_sent + 1; % Increment the number of sent messages

                elseif strcmp(data.S3state, 'red')
                    ttSendMsg([1, 3], [1, 4], 1, 1);
                    log_msg_sent = log_msg_sent + 1; % Increment the number of sent messages
                end
                % ============================================================

            elseif(current_state == 2) % Flashing yellow state

                %----------------@DEBUG@------------------------------------------------------------------------------
                %disp('[', ttSimTimeStr(),'][Controller]: Flashing yellow state, controller idle.');
                %-----------------------------------------------------------------------------------------------------

            end

            exectime = 1; % Execution time
        case 2
            % Save logs at the end of the simulation
            log_hours_passed = (ttCurrentTime-data.simStartTime)/3600;
            save('NNcontroller_data_latest.mat', 'log_msg_sent', 'log_hours_passed', 'log_NN_timeS1_2', 'log_NN_timeS3', 'log_red_timeS1_2', 'log_red_timeS3');

            % Dataset for the neural network
            save('dataset_NN_latest.mat', 'ds_X', 'ds_Y');
            
            exectime = -1; % Segment finished
    end
end