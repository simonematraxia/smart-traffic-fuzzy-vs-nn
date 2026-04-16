function [exectime, data] = S_code(segment, data)
persistent toggleState toggleGrey; % variabili utili alla logica dello stato "Giallo Lampeggiante"
persistent log_msg_recieved; % variabili di log per misurare le performance del sistema

if isempty(log_msg_recieved)
    log_msg_recieved = 0; % Numero di messaggi ricevuti
end

    switch segment
        case 1
            msg = ttGetMsg;
            
            if (~isempty(msg) && msg(end) == 4) % controllo se è arrivato il messaggio del controllore (identificato con 4 a fine messaggio)
                %----------------@DEBUG@----------------------------------------------------------------------------------------
                %disp(['[', ttSimTimeStr(),'][Semaforo ', num2str(data.id_semaforo),']: Ho ricevuto un messaggio dal controllore: ', num2str(msg)]);
                %---------------------------------------------------------------------------------------------------------------
                log_msg_recieved = log_msg_recieved + 1;
                
                if(length(msg) == 2 && msg(end) == 4) % messaggio contenente un array di 2 elementi che finisce per 4: 
                                                      % stato del semaforo comunicato dal controllore

                        ttAnalogOut(1, msg(1)); % Rosso: msg(1) == 1 | Giallo: msg(1) == 2 | Verde: msg(1) == 3
                        data.lastState = msg(1); % memorizza l'ultimo stato valido per semaforo
                        data.lostCount = 0;     % azzera contatore di pacchetti persi

                        %----------------@DEBUG@------------------------------------------------------------------------------------------------------
                        %disp(['[', ttSimTimeStr(),'][Semaforo ', num2str(data.id_semaforo), '] il mio "lastState" è = ', num2str(data.lastState)]);
                        %-----------------------------------------------------------------------------------------------------------------------------
                end
                
            elseif isempty(msg) %logica dello stato "Giallo Lampeggiante"
                % nessun messaggio ricevuto in questo secondo

                data.lostCount = data.lostCount + 1;
    
                if data.lostCount == 1
                    % Primo pacchetto perso: mantieni lo stato precedente per almeno 1 s
                    ttAnalogOut(1, data.lastState);

                    %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Semaforo ', num2str(data.id_semaforo), '] PACCHETTO PERSO, lastState = ', num2str(data.lastState)]);
                    %---------------------------------------------------------------------------------------------------------------------------------------------------
                else
                    % Due o più pacchetti consecutivi persi: giallo lampeggiante

                    %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Semaforo ', num2str(data.id_semaforo),']: Non ricevo alcun messaggio, sono nello stato di "Giallo Lampeggiante".']);
                    %---------------------------------------------------------------------------------------------------------------------------------------------------

                    if isempty(toggleState)
                        toggleState = 0; 
                    end
                    if isempty(toggleGrey)
                        toggleGrey = 0;
                    end
    
                    if toggleState < 3 % tutti e 3 i semafori (S1, S2, S3) hanno bisogno di entrare in questa condizione
                        ttAnalogOut(1, 2); % Giallo
                        toggleState = toggleState + 1;
                        if toggleState == 3
                            toggleGrey = 0; % azzero l'altra variabile per far si che al prossimo clock, tutti i semafori 
                                            % entrino nella condizione di "grigio"
                        end
                    elseif toggleGrey < 3 % tutti e 3 i semafori (S1, S2, S3) hanno bisogno di entrare in questa condizione
                        ttAnalogOut(1, 4); % Grigio
                        toggleGrey = toggleGrey + 1;
                        if toggleGrey == 3
                            toggleState = 0; % azzero la prima variabile per far si che al prossimo clock, tutti i semafori 
                                             % entrino nella condizione di "giallo"
                        end
                    end
                end
               
            end
            exectime = 1;
            return;
            
        otherwise
            % Salvataggio log
            save('semaphores_data_latest.mat', 'log_msg_recieved');
            exectime = -1;
    end
end
