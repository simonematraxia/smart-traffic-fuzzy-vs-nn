function controllore_init
    ttInitKernel('prioFP');
    
    % Dati iniziali per il controllore
    data.fis = readfis('green_extend.fis'); % file .fis (logica fuzzy)

    data.S1stato = 'rosso';      % Stato iniziale semaforo 1
    data.S1durata = 0;           % Durata corrente del semaforo 1

    data.S2stato = 'rosso';      % Stato iniziale semaforo 2
    data.S2durata = 0;           % Durata corrente del semaforo 2

    data.S3stato = 'rosso';      % Stato iniziale semaforo 3
    data.S3durata = 0;           % Durata corrente del semaforo 3
    
    % Periodo del task (in questo caso ogni secondo)
    periodo = 1;
    
    % Creazione del task periodico
    starttime = str2double(get_param(bdroot,'StartTime'));
    data.simStartTime = starttime;
    ttCreatePeriodicTask('calcolo_tempi', starttime, periodo, 'controllore_code_NN', data); %per versione NN "controllore_code_NN", sennò "controllore_code"
end