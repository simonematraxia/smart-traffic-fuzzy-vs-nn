function [exectime, data] = controllore_code_NN(segment, data)
persistent impostato; % variabile che il controllore usa per definire, al primo clock della simulazione, 
                      % chi deve avere la priorità per iniziare con la luce verde.
                      % La logica prevede infatti che la condizione di assegnazione del primo tempo si verifichi solo all'inizio: 
                      % o per S1 ed S2, o per S3.

persistent S1_2_total S3_total   % tempi verdi totali assegnati nella fase corrente

persistent log_msg_sent log_hours_passed log_NN_timeS1_2 log_NN_timeS3 log_red_timeS1_2 log_red_timeS3; %variabili di Log per misurare le performance del sistema

persistent ds_X ds_Y    % dataset della rete neurale: input e output

persistent intergreen_countdown pending_green % pausa all-red tra un verde e l'altro

persistent netNN


MinGreen_S12 = 30;   % verde minimo S1/S2
MaxGreen_S12 = 90;   % verde massimo S1/S2
MinGreen_S3  = 30;   % verde minimo S3
MaxGreen_S3  = 90;   % verde massimo S3

% Inizializza le variabili persistenti alla prima esecuzione
% ============================================================
if isempty(log_msg_sent) 
    log_msg_sent = 0; % Numero di messaggi inviati
    log_hours_passed = 0; % Tempo totale di simulazione (convertito da secondi in ore Line: 173)
    log_NN_timeS1_2 = []; % Tempi calcolati per S1 ed S2
    log_NN_timeS3 = []; % Tempi calcolati per S3
    log_red_timeS1_2 = []; % Tempi di rosso per S1 ed S2
    log_red_timeS3 = []; % Tempi di rosso per S3
    ds_X = []; % ingressi al fuzzy per training rete neurale (coda del ramo attuale, flusso del ramo attuale e coda dell'altro ramo)
    ds_Y = []; % uscite del fuzzy per training rete neurale (estensioni del tempo di verde)
    intergreen_countdown = 0; % 
    pending_green = '';       % 
end

if isempty(netNN)
    NN = load('green_extend_NN.mat','net');  % carica la variabile 'net'
    netNN = NN.net;
end
% ============================================================

    switch segment
        case 1
            current_state = ttAnalogIn(5); % Stato attuale dei semafori (Normale: 1 | Giallo Lampeggiante: 2)

            %----------------@DEBUG@------------------------------------------------
            %disp(['[', ttSimTimeStr(),'][Controllore]: current state: ', num2str(current_state)])
            %-----------------------------------------------------------------------
            
            if(current_state == 1) %stato normale

                % Lettura sensori (queue/flow) - usati sia per scelta iniziale sia
                % per eventuale estensione
                % ============================================================
                queue_S12 = ttAnalogIn(1);
                flow_S12 = ttAnalogIn(2);
                queue_S3 = ttAnalogIn(3);
                flow_S3 = ttAnalogIn(4);
                % ============================================================

                %----------------@DEBUG@----------------------------------------------------------------
                %disp(['[', ttSimTimeStr(),'][Controllore]: Traffic Queue corsia di S1/S2: ', num2str(queue_S12)]);
                %disp(['[', ttSimTimeStr(),'][Controllore]: Traffic Flow corsia di S1/S2: ', num2str(flow_S12)]);
                %disp(['[', ttSimTimeStr(),'][Controllore]: Traffic Queue corsia di S3: ', num2str(queue_S3)]);
                %disp(['[', ttSimTimeStr(),'][Controllore]: Traffic Flow corsia di S3: ', num2str(flow_S3)]);
                %---------------------------------------------------------------------------------------

                if isempty(impostato) % Controlla se 'impostato' non è stato inizializzato
                    impostato = 0;

                    %----------------@DEBUG@----------------------
                    %disp(['[', ttSimTimeStr(),'][Controllore]: impostato = 0 ']);
                    %---------------------------------------------
                end
                
                %    Scelta di chi inizia con il verde (solo all'inizio)
                %    se queue_S3 > queue_S12 → parte S3, altrimenti S1/S2
                % ============================================================
                if impostato == 0
                    if queue_S3 > queue_S12
                        % Parte S3
                        data.S3stato  = 'verde';
                        data.S3durata = MinGreen_S3;
                        S3_total      = MinGreen_S3;
                        data.S1stato  = 'rosso';
                        data.S2stato  = 'rosso';
                    else
                        % Partono S1/S2
                        data.S1stato  = 'verde';
                        data.S2stato  = 'verde';
                        data.S1durata = MinGreen_S12;
                        data.S2durata = MinGreen_S12;
                        S1_2_total    = MinGreen_S12;
                        data.S3stato  = 'rosso';
                    end
                    impostato = 1;
                end
                % ============================================================


                %------------------------------------------------------------------------------------------
                %Leggenda messaggi del controllore, (presente anche nel codice del semaforo a Line 20):
                %   [1, 4] = semaforo rosso
                %   [2, 4] = semaforo giallo
                %   [3, 4] = semaforo verde
                %i semafori utilizzano 1, 2 e 3 come uscite analogiche per esporre il loro stato attuale
                %------------------------------------------------------------------------------------------
                

                % INTERGREEN - 2 secondi di all-red tra verde e verde
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
                    % Pausa finita: attiva il verde in attesa
                    if strcmp(pending_green, 'S3')
                        data.S3stato = 'verde';
                        data.S3durata = MinGreen_S3;
                        S3_total = MinGreen_S3;
                    else % 'S12'
                        data.S1stato = 'verde';
                        data.S2stato = 'verde';
                        data.S1durata = MinGreen_S12;
                        data.S2durata = MinGreen_S12;
                        S1_2_total = MinGreen_S12;
                    end
                    pending_green = '';
                end
                % ============================================================


                % LOGICA PER S1 ED S2 IN ATTIVITA'
                % ============================================================
                if strcmp(data.S1stato, 'verde') || strcmp(data.S1stato, 'giallo') || strcmp(data.S2stato, 'verde') || strcmp(data.S2stato, 'giallo')
                    
                    %----------------@DEBUG@----------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Controllore]: Semaforo 1 attivo, tempo rimanente: ', num2str(data.S1durata),' secondi.']);
                    %disp(['[', ttSimTimeStr(),'][Controllore]: Semaforo 2 attivo, tempo rimanente: ', num2str(data.S2durata),' secondi.']);
                    %---------------------------------------------------------------------------------------------------------

                    % Tentativo di estensione quando sta per finire il verde
                    if data.S1durata == 6 && S1_2_total < MaxGreen_S12
                       
                        queue_curr  = queue_S12;
                        flow_curr   = flow_S12;
                        queue_other = queue_S3;
    
                        ext = netNN([queue_curr; flow_curr; queue_other]);

                        % Salva un campione nel dataset della NN (ramo S12)
                        sample_in  = [queue_curr, flow_curr, queue_other]; 
                        sample_out = ext; % estensione effettiva usata
                        
                        ds_X = [ds_X; sample_in];
                        ds_Y = [ds_Y; sample_out];


                        ext = max(0, min(10, round(ext)));   % estensione in secondi (0..10)
                        if ext > 0
                            new_total = S1_2_total + ext;
                            if new_total > MaxGreen_S12
                                ext = MaxGreen_S12 - S1_2_total;
                                new_total = MaxGreen_S12;
                            end
                            data.S1durata = data.S1durata + ext;
                            data.S2durata = data.S2durata + ext;
                            S1_2_total    = new_total;
                        end

                        %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------------------------
                       % if ext ~= 0
                       %     fprintf('[%s][Controllore] estensione per S1/S2 = %.3fs\n', ttSimTimeStr(), ext);
                       % else
                       %     fprintf('[%s][Controllore] nessuna estensione per S1/S2 (%.3fs), il tempo verde totale di questo ciclo è stato di %.0f secondi.\n', ttSimTimeStr(), ext, S1_2_total);
                       % end
                        %---------------------------------------------------------------------------------------------------------------------------------------------------------------------

                    end

                    if data.S1durata > 5
                        ttSendMsg([1, 1], [3, 4], 1, 1); %messaggio al semaforo 1 (nella rete 1) (1 bit di lunghezza, priorità 1)
                        ttSendMsg([1, 2], [3, 4], 1, 1); %messaggio al semaforo 2 (nella rete 1) (1 bit di lunghezza, priorità 1)
                        data.S1stato = 'verde';
                        data.S1durata = data.S1durata - 1;
                        data.S2stato = 'verde';
                        data.S2durata = data.S2durata - 1;
                    elseif data.S1durata > 0
                        ttSendMsg([1, 1], [2, 4], 1, 1);
                        ttSendMsg([1, 2], [2, 4], 1, 1);
                        data.S1stato = 'giallo';
                        data.S1durata = data.S1durata - 1;
                        data.S2stato = 'giallo';
                        data.S2durata = data.S2durata - 1;
                    elseif data.S1durata <= 0
                        % Logga il verde effettivo usato in questa fase
                        if ~isempty(S1_2_total)
                            log_NN_timeS1_2 = [log_NN_timeS1_2; S1_2_total];
                            % Logga anche il rosso dell'altra parte (S3) = verde/giallo S12 + intergreen (2 s)
                            log_red_timeS3 = [log_red_timeS3; (S1_2_total + 2)];
                        end

                        ttSendMsg([1, 1], [1, 4], 1, 1);
                        ttSendMsg([1, 2], [1, 4], 1, 1);
                        data.S1stato = 'rosso';
                        data.S2stato = 'rosso';

                        % avvia intergreen di 2 sec prima di dare verde a S3
                        intergreen_countdown = 1;
                        pending_green = 'S3';
                        S1_2_total = []; % reset
                    end

                    log_msg_sent = log_msg_sent + 2; % Incrementa il numero di messaggi inviati di due (dato che inviamo messaggi a S1 ed S2)

                elseif strcmp(data.S1stato, 'rosso') || strcmp(data.S2stato, 'rosso')
                    ttSendMsg([1, 1], [1, 4], 1, 1);
                    ttSendMsg([1, 2], [1, 4], 1, 1);
                    log_msg_sent = log_msg_sent + 2; % Incrementa il numero di messaggi inviati
                end
                % ============================================================

                
                % 3) LOGICA PER S3 IN ATTIVITA'
                % ============================================================
                if strcmp(data.S3stato, 'verde') || strcmp(data.S3stato, 'giallo')

                    %----------------@DEBUG@-------------------------------------------------------------------------------------------------
                    %disp(['[', ttSimTimeStr(),'][Controllore]: Semaforo 3 attivo, tempo rimanente: ', num2str(data.S3durata),' secondi.']);
                    %------------------------------------------------------------------------------------------------------------------------

                    % Tentativo di estensione quando sta per finire il verde
                    if data.S3durata == 6 && S3_total < MaxGreen_S3
                        queue_curr  = queue_S3;
                        flow_curr   = flow_S3;
                        queue_other = queue_S12;
    
                        ext = netNN([queue_curr; flow_curr; queue_other]);
                      
                        % Salva un campione nel dataset della NN (ramo S3)
                        sample_in  = [queue_curr, flow_curr, queue_other]; 
                        sample_out = ext; % estensione effettiva usata

                        ds_X = [ds_X; sample_in];
                        ds_Y = [ds_Y; sample_out];

                        
                        ext = max(0, min(10, round(ext)));
                        if ext > 0
                            new_total = S3_total + ext;
                            if new_total > MaxGreen_S3
                                ext = MaxGreen_S3 - S3_total;
                                new_total = MaxGreen_S3;
                            end
                            data.S3durata = data.S3durata + ext;
                            S3_total      = new_total;
                        end

                        %----------------@DEBUG@----------------------------------------------------------------------------------------------------------------------------------------------
                        if ext ~= 0
                       %     fprintf('[%s][Controllore] estensione per S3 = %.3fs\n', ttSimTimeStr(), ext);
                        else
                       %     fprintf('[%s][Controllore] nessuna estensione per S3 (%.3fs), il tempo verde totale di questo ciclo è stato di %.0f secondi.\n', ttSimTimeStr(), ext, S3_total);
                        end
                        %---------------------------------------------------------------------------------------------------------------------------------------------------------------------

                    end

                    if data.S3durata > 5
                        ttSendMsg([1, 3], [3, 4], 1, 1); %messaggio al semaforo 3 (nella rete 1) (1 bit di lunghezza, priorità 1)
                        data.S3stato = 'verde';
                        data.S3durata = data.S3durata - 1;
                    elseif data.S3durata > 0
                        ttSendMsg([1, 3], [2, 4], 1, 1); 
                        data.S3stato = 'giallo';
                        data.S3durata = data.S3durata - 1;
                    elseif data.S3durata <= 0
                        % Logga il verde effettivo usato in questa fase
                        if ~isempty(S3_total)
                            log_NN_timeS3 = [log_NN_timeS3; S3_total];
                            % Logga anche il rosso dell'altra parte (S12) = verde/giallo S3 + intergreen (2 s)
                            log_red_timeS1_2 = [log_red_timeS1_2; (S3_total + 2)];
                        end

                        ttSendMsg([1, 3], [1, 4], 1, 1);
                        data.S3stato = 'rosso';
                        
                        % avvia intergreen di 2 sec prima di dare verde a S1/S2
                        intergreen_countdown = 1;
                        pending_green = 'S12';
                        S3_total = []; % rese
                    end    
                
                    log_msg_sent = log_msg_sent + 1; % Incrementa il numero di messaggi inviati

                elseif strcmp(data.S3stato, 'rosso')
                    ttSendMsg([1, 3], [1, 4], 1, 1);
                    log_msg_sent = log_msg_sent + 1; % Incrementa il numero di messaggi inviati
                end
                % ============================================================

            elseif(current_state == 2) %stato di giallo lampeggiante

                %----------------@DEBUG@------------------------------------------------------------------------------
                %disp('[', ttSimTimeStr(),'][Controllore]: Stato di giallo lampeggiante, controllore fermo.');
                %-----------------------------------------------------------------------------------------------------

            end

            exectime = 1; % Tempo di esecuzione
        case 2
            % Salva i log alla fine della simulazione
            log_hours_passed = (ttCurrentTime-data.simStartTime)/3600;
            save('controller_data_NN_latest.mat', 'log_msg_sent', 'log_hours_passed', 'log_NN_timeS1_2', 'log_NN_timeS3', 'log_red_timeS1_2', 'log_red_timeS3');

            % Dataset per la rete neurale
            save('dataset_NN_latest.mat', 'ds_X', 'ds_Y');
            
            exectime = -1; % Segmento finito
    end
end
