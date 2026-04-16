function S1_init
    ttInitKernel('prioFP');

    % Dati iniziali per il semaforo
    data.id_semaforo = 1;      % ID del semaforo (specifico per ogni kernel)

    % Periodo del task (in questo caso ogni secondo)
    periodo = 1;

    data.lastState = 1;        % rosso come stato iniziale (1 = rosso)
    data.lostCount = 0;        % contatore di pacchetti persi
    
    % Creazione del task periodico
    starttime = str2double(get_param(bdroot,'StartTime'));
    ttCreatePeriodicTask('semaforo_1', starttime, periodo, 'S_code', data);
end