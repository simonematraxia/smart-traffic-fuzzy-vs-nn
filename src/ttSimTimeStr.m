function s = ttSimTimeStr()
% Restituisce il tempo TrueTime formattato come [HH:MM:SS]

t = ttCurrentTime;                 % tempo simulazione in secondi

hour   = floor(mod(t/3600, 24));   % 0..23
minute = floor(mod(t,3600)/60);    % 0..59
second = floor(mod(t,60));         % 0..59

s = sprintf('%02d:%02d:%02d', hour, minute, second);
end