clear; close all; clc;

hours = 0:0.05:24;
gauss   = @(x,mu,sig,amp) amp * exp(-((x-mu).^2)./(2*sig^2));
sigmoid = @(x,center,w)   1./(1 + exp(-(x-center)/w));

% --- day/night (transition at 06:00 and 22:00) ---
% Night (22:00-06:00): p_arr = 0.02/lane
% Quiet day:           p_arr S12=0.22, S3=0.24
day_S12 = 0.02*4 + (0.22-0.02)*4 .* (sigmoid(hours,6,0.4) - sigmoid(hours,22,0.4));
day_S3  = 0.03*2 + (0.24-0.03)*2 .* (sigmoid(hours,6,0.4) - sigmoid(hours,22,0.4));

S12 = day_S12 ...
    + gauss(hours, 8.0,  0.85, (0.30-0.22)*4) ...
    + gauss(hours, 10.5, 1.4,  (0.26-0.22)*4) ...
    + gauss(hours, 13.0, 0.9,  (0.33-0.22)*4) ...
    + gauss(hours, 19.0, 0.85, 0.3525);

S3 = day_S3 ...
    + gauss(hours, 8.0,  0.85, (0.32-0.24)*2) ...
    + gauss(hours, 10.5, 1.4,  (0.28-0.24)*2) ...
    + gauss(hours, 13.0, 0.9,  (0.35-0.24)*2) ...
    + gauss(hours, 19.0, 0.85, 0.1762);

S12 = max(S12, 0);
S3  = max(S3,  0);

blue   = [0  68 136]/255;
orange = [200 80  0]/255;

figure('Color','w','Position',[100 100 1000 480]);
hold on;

area(hours, S12, 'FaceColor', [0 100 200]/255, 'FaceAlpha', 0.10, 'EdgeColor','none', 'HandleVisibility','off');
area(hours, S3,  'FaceColor', orange,          'FaceAlpha', 0.12, 'EdgeColor','none', 'HandleVisibility','off');

plot(hours, S12, 'Color', blue,   'LineWidth', 2.5, 'DisplayName','S1/S2 (Via Catania – 4 lanes)');
plot(hours, S3,  'Color', orange, 'LineWidth', 2.0, 'LineStyle','--', 'DisplayName','S3 (Via Calabria – 2 lanes)');

xlim([0 24]); ylim([0 1.6]);
xticks(0:2:24);
xticklabels({'00:00','02:00','04:00','06:00','08:00','10:00','12:00', ...
             '14:00','16:00','18:00','20:00','22:00','24:00'});
yticks(0:0.2:1.6);

xlabel('Time of day','FontSize',12,'FontWeight','bold');
ylabel('Arrival rate (vehicles/s)','FontSize',12,'FontWeight','bold');
title('Daily vehicular traffic profile','FontSize',15,'FontWeight','bold');

ax = gca; ax.XGrid='on'; ax.YGrid='on';
ax.GridLineStyle='--'; ax.GridAlpha=0.35; ax.FontSize=11;

yline(0.22*4, ':', 'Color', blue,   'LineWidth',1.0, 'Alpha',0.5, 'HandleVisibility','off');
yline(0.24*2, ':', 'Color', orange, 'LineWidth',1.0, 'Alpha',0.5, 'HandleVisibility','off');

xregion(0,  6,  'FaceColor',[0.85 0.85 0.95],'FaceAlpha',0.25,'EdgeColor','none', 'HandleVisibility','off');
xregion(22, 24, 'FaceColor',[0.85 0.85 0.95],'FaceAlpha',0.25,'EdgeColor','none', 'HandleVisibility','off');

text(3.0,  1.50, '{\it Nighttime}', 'FontSize',8.5, ...
    'Color',[0.4 0.4 0.6],'HorizontalAlignment','center');
text(23.0, 1.50, '{\it Nighttime}', 'FontSize',8.5, ...
    'Color',[0.4 0.4 0.6],'HorizontalAlignment','center');

legend('Location','south','FontSize',10,'Box','on');

% --- LABELS ---
y_top = 1.50;

text(8.0,  y_top, {'{\bf Morning Peak}','{\it 07:00–09:00}'}, ...
    'FontSize',9,'HorizontalAlignment','center', ...
    'BackgroundColor','white','EdgeColor',[0.7 0.7 0.7],'Margin',3);

text(10.3, 1.23, {'{\it Off-Peak}','{\it 09:00–12:00}'}, ...
    'FontSize',9,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center', ...
    'BackgroundColor','white','EdgeColor',[0.8 0.8 0.8],'Margin',3);

text(16, 1.17, {'{\it Off-Peak}','{\it 14:00–18:00}'}, ...
    'FontSize',9,'Color',[0.45 0.45 0.45],'HorizontalAlignment','center', ...
    'BackgroundColor','white','EdgeColor',[0.8 0.8 0.8],'Margin',3);

text(13.0, y_top, {'{\bf Maximum Peak}','{\it 12:00–14:00}'}, ...
    'FontSize',9.5,'Color',[0.55 0 0],'HorizontalAlignment','center', ...
    'BackgroundColor','white','EdgeColor',[0.85 0.6 0.6],'Margin',3);

text(19.0, y_top, {'{\bf Evening Peak}','{\it 18:00–20:00}'}, ...
    'FontSize',9,'HorizontalAlignment','center', ...
    'BackgroundColor','white','EdgeColor',[0.7 0.7 0.7],'Margin',3);

exportgraphics(gcf,'traffic_profile.png','Resolution',300);