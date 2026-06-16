function [exectime, data] = traffic_light_script(segment, data)
persistent toggleState toggleGrey; % variables useful for the "Flashing Yellow" state logic
persistent log_msg_received; % log variables to measure system performance

if isempty(log_msg_received)
    log_msg_received = 0; % Number of received messages
end

    switch segment
        case 1
            msg = ttGetMsg;
            
            if (~isempty(msg) && msg(end) == 4) % check if the controller message has arrived (identified by 4 at the end of the message)
                %----------------@DEBUG@----------------------------------------------------------------------------------------
                %disp(['[', ttSimTimeStr(),'][Traffic Light ', num2str(data.traffic_light_id),']: I received a message from the controller: ', num2str(msg)]);
                %---------------------------------------------------------------------------------------------------------------
                log_msg_received = log_msg_received + 1;
                
                if(length(msg) == 2 && msg(end) == 4) % message containing a 2-element array ending with 4: 
                                                      % traffic light state communicated by the controller

                        ttAnalogOut(1, msg(1)); % Red: msg(1) == 1 | Yellow: msg(1) == 2 | Green: msg(1) == 3
                        data.lastState = msg(1); % store the last valid state for the traffic light
                        data.lostCount = 0;     % reset the lost packets counter

                        %----------------@DEBUG@------------------------------------------------------------------------------------------------------
                        %disp(['[', ttSimTimeStr(),'][Traffic Light ', num2str(data.traffic_light_id), '] my "lastState" is = ', num2str(data.lastState)]);
                        %-----------------------------------------------------------------------------------------------------------------------------
                end
                
            elseif isempty(msg) % "Flashing Yellow" state logic
                % no message received in this second

                data.lostCount = data.lostCount + 1;
    
                if data.lostCount == 1
                    % First lost packet: keep the previous state for at least 1 s
                    ttAnalogOut(1, data.lastState);

                    %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Traffic Light ', num2str(data.traffic_light_id), '] LOST PACKET, lastState = ', num2str(data.lastState)]);
                    %---------------------------------------------------------------------------------------------------------------------------------------------------
                else
                    % Two or more consecutive lost packets: flashing yellow

                    %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Traffic Light ', num2str(data.traffic_light_id),']: Receiving no messages, entering "Flashing Yellow" state.']);
                    %---------------------------------------------------------------------------------------------------------------------------------------------------

                    if isempty(toggleState)
                        toggleState = 0; 
                    end
                    if isempty(toggleGrey)
                        toggleGrey = 0;
                    end
    
                    if toggleState < 3 % all 3 traffic lights (S1, S2, S3) need to enter this condition
                        ttAnalogOut(1, 2); % Yellow
                        toggleState = toggleState + 1;
                        if toggleState == 3
                            toggleGrey = 0; % reset the other variable so that at the next clock, all traffic lights 
                                            % enter the "grey" condition
                        end
                    elseif toggleGrey < 3 % all 3 traffic lights (S1, S2, S3) need to enter this condition
                        ttAnalogOut(1, 4); % Grey (Off)
                        toggleGrey = toggleGrey + 1;
                        if toggleGrey == 3
                            toggleState = 0; % reset the first variable so that at the next clock, all traffic lights 
                                             % enter the "yellow" condition
                        end
                    end
                end
               
            end
            exectime = 1;
            return;
            
        otherwise
            % Save logs
            save('traffic_light_data_latest.mat', 'log_msg_received');
            exectime = -1;
    end
end