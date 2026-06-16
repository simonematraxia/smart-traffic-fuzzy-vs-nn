%% performance_metrics.m - Performance Comparison: FUZZY vs NN
% Required files:
%   controller_data_fuzzy_latest.mat -> log_hours_passed,
%                                       log_fuzzy_timeS1_2, log_fuzzy_timeS3,
%                                       log_red_timeS1_2,   log_red_timeS3
%   controller_data_NN_latest.mat    -> log_hours_passed,
%                                       log_NN_timeS1_2,    log_NN_timeS3,
%                                       log_red_timeS1_2,   log_red_timeS3
clear; close all; clc;

MinGreen = 30;
MaxGreen = 90;
cFuzzy = [0.22 0.49 0.72];
cNN    = [0.89 0.44 0.13];

% ============================================================
%% LOAD DATA
% ============================================================
ctrl_F      = load('controller_data_fuzzy.mat');
sim_hours_F = ctrl_F.log_hours_passed;
gS12_F      = ctrl_F.log_fuzzy_timeS1_2(:);
gS3_F       = ctrl_F.log_fuzzy_timeS3(:);
rS12_F      = ctrl_F.log_red_timeS1_2(:);
rS3_F       = ctrl_F.log_red_timeS3(:);

ctrl_NN      = load('controller_data_NN.mat');
sim_hours_NN = ctrl_NN.log_hours_passed;
gS12_NN      = ctrl_NN.log_NN_timeS1_2(:);
gS3_NN       = ctrl_NN.log_NN_timeS3(:);
rS12_NN      = ctrl_NN.log_red_timeS1_2(:);
rS3_NN       = ctrl_NN.log_red_timeS3(:);

% ============================================================
%% LOAD DATASET
% ============================================================
ds_F  = load('dataset_fuzzy_test.mat');
ds_NN = load('dataset_NN_test.mat');

Y_F  = ds_F.ds_Y(:);
Y_NN = ds_NN.ds_Y(:);
n    = min(length(Y_F), length(Y_NN)); 
Y_F  = Y_F(1:n);
Y_NN = Y_NN(1:n);
% ============================================================
%% FUZZY STATISTICS
% ============================================================
n_cyc_S12_F = length(gS12_F);   n_cyc_S3_F = length(gS3_F);
avg_gS12_F  = mean(gS12_F);     avg_gS3_F  = mean(gS3_F);
med_gS12_F  = median(gS12_F);   med_gS3_F  = median(gS3_F);
std_gS12_F  = std(gS12_F);      std_gS3_F  = std(gS3_F);
p95_gS12_F  = prctile(gS12_F,95); p95_gS3_F = prctile(gS3_F,95);
max_gS12_F  = max(gS12_F);      max_gS3_F  = max(gS3_F);
n_ext_S12_F   = sum(gS12_F > MinGreen);
n_ext_S3_F    = sum(gS3_F  > MinGreen);
pct_ext_S12_F = n_ext_S12_F / max(1,n_cyc_S12_F) * 100;
pct_ext_S3_F  = n_ext_S3_F  / max(1,n_cyc_S3_F)  * 100;
if any(gS12_F > MinGreen); mean_ext_S12_F = mean(gS12_F(gS12_F>MinGreen)-MinGreen); else; mean_ext_S12_F = 0; end
if any(gS3_F  > MinGreen); mean_ext_S3_F  = mean(gS3_F( gS3_F >MinGreen)-MinGreen); else; mean_ext_S3_F  = 0; end
avg_rS12_F = mean(rS12_F); std_rS12_F = std(rS12_F);
med_rS12_F = median(rS12_F); p95_rS12_F = prctile(rS12_F,95); max_rS12_F = max(rS12_F);
avg_rS3_F  = mean(rS3_F);  std_rS3_F  = std(rS3_F);
med_rS3_F  = median(rS3_F);  p95_rS3_F  = prctile(rS3_F,95);  max_rS3_F  = max(rS3_F);

% ============================================================
%% NN STATISTICS
% ============================================================
n_cyc_S12_NN = length(gS12_NN);   n_cyc_S3_NN = length(gS3_NN);
avg_gS12_NN  = mean(gS12_NN);     avg_gS3_NN  = mean(gS3_NN);
med_gS12_NN  = median(gS12_NN);   med_gS3_NN  = median(gS3_NN);
std_gS12_NN  = std(gS12_NN);      std_gS3_NN  = std(gS3_NN);
p95_gS12_NN  = prctile(gS12_NN,95); p95_gS3_NN = prctile(gS3_NN,95);
max_gS12_NN  = max(gS12_NN);      max_gS3_NN  = max(gS3_NN);
n_ext_S12_NN   = sum(gS12_NN > MinGreen);
n_ext_S3_NN    = sum(gS3_NN  > MinGreen);
pct_ext_S12_NN = n_ext_S12_NN / max(1,n_cyc_S12_NN) * 100;
pct_ext_S3_NN  = n_ext_S3_NN  / max(1,n_cyc_S3_NN)  * 100;
if any(gS12_NN > MinGreen); mean_ext_S12_NN = mean(gS12_NN(gS12_NN>MinGreen)-MinGreen); else; mean_ext_S12_NN = 0; end
if any(gS3_NN  > MinGreen); mean_ext_S3_NN  = mean(gS3_NN( gS3_NN >MinGreen)-MinGreen); else; mean_ext_S3_NN  = 0; end
avg_rS12_NN = mean(rS12_NN); std_rS12_NN = std(rS12_NN);
med_rS12_NN = median(rS12_NN); p95_rS12_NN = prctile(rS12_NN,95); max_rS12_NN = max(rS12_NN);
avg_rS3_NN  = mean(rS3_NN);  std_rS3_NN  = std(rS3_NN);
med_rS3_NN  = median(rS3_NN);  p95_rS3_NN  = prctile(rS3_NN,95);  max_rS3_NN  = max(rS3_NN);

% ============================================================
%% CONSOLE OUTPUT
% ============================================================
fprintf('==========================================================================\n');
fprintf('=== FUZZY  (%.2f simulated hours | %d S1/S2 cycles | %d S3 cycles) ===\n', ...
    sim_hours_F, n_cyc_S12_F, n_cyc_S3_F);
fprintf('--------------------------------------------------------------------------\n');
fprintf('[Green S1/S2  ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_gS12_F, med_gS12_F, std_gS12_F, p95_gS12_F, max_gS12_F);
fprintf('[Green S3     ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_gS3_F, med_gS3_F, std_gS3_F, p95_gS3_F, max_gS3_F);
fprintf('[Extensions   ] S1/S2: %d/%d (%.1f%%), mean=%.1f s extra | S3: %d/%d (%.1f%%), mean=%.1f s extra\n', ...
    n_ext_S12_F, n_cyc_S12_F, pct_ext_S12_F, mean_ext_S12_F, ...
    n_ext_S3_F,  n_cyc_S3_F,  pct_ext_S3_F,  mean_ext_S3_F);
fprintf('[Waiting S1/S2] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_rS12_F, med_rS12_F, std_rS12_F, p95_rS12_F, max_rS12_F);
fprintf('[Waiting S3   ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_rS3_F, med_rS3_F, std_rS3_F, p95_rS3_F, max_rS3_F);

fprintf('\n=== NN  (%.2f simulated hours | %d S1/S2 cycles | %d S3 cycles) ===\n', ...
    sim_hours_NN, n_cyc_S12_NN, n_cyc_S3_NN);
fprintf('--------------------------------------------------------------------------\n');
fprintf('[Green S1/S2  ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_gS12_NN, med_gS12_NN, std_gS12_NN, p95_gS12_NN, max_gS12_NN);
fprintf('[Green S3     ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_gS3_NN, med_gS3_NN, std_gS3_NN, p95_gS3_NN, max_gS3_NN);
fprintf('[Extensions   ] S1/S2: %d/%d (%.1f%%), mean=%.1f s extra | S3: %d/%d (%.1f%%), mean=%.1f s extra\n', ...
    n_ext_S12_NN, n_cyc_S12_NN, pct_ext_S12_NN, mean_ext_S12_NN, ...
    n_ext_S3_NN,  n_cyc_S3_NN,  pct_ext_S3_NN,  mean_ext_S3_NN);
fprintf('[Waiting S1/S2] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_rS12_NN, med_rS12_NN, std_rS12_NN, p95_rS12_NN, max_rS12_NN);
fprintf('[Waiting S3   ] mean=%5.1f s | med=%5.1f s | std=%4.1f s | p95=%5.1f s | max=%5.1f s\n', ...
    avg_rS3_NN, med_rS3_NN, std_rS3_NN, p95_rS3_NN, max_rS3_NN);

fprintf('\n=== DIFFERENCES (NN - FUZZY) ===\n');
fprintf('--------------------------------------------------------------------------\n');
fprintf('Delta mean green time     S1/S2: %+.2f s  |  S3: %+.2f s\n', ...
    avg_gS12_NN-avg_gS12_F, avg_gS3_NN-avg_gS3_F);
fprintf('Delta extensions %%        S1/S2: %+.1f%%   |  S3: %+.1f%%\n', ...
    pct_ext_S12_NN-pct_ext_S12_F, pct_ext_S3_NN-pct_ext_S3_F);
fprintf('Delta mean waiting time   S1/S2: %+.2f s  |  S3: %+.2f s\n', ...
    avg_rS12_NN-avg_rS12_F, avg_rS3_NN-avg_rS3_F);
fprintf('==========================================================================\n');

% ============================================================
%% FIGURE 1 — Cycle-by-cycle Scatter: trend over time
% ============================================================
figure('Name','Green time per cycle','Position',[100 100 1050 520]);

subplot(2,2,1);
plot(gS12_F, '.', 'Color', cFuzzy, 'MarkerSize', 8);
yline(MinGreen,'--k','LineWidth',1.2);
yline(MaxGreen,'--k','LineWidth',1.2);
ylim([MinGreen-5, MaxGreen+5]);
yticks(30:10:MaxGreen+5);
xlabel('Cycle number','FontSize',11); ylabel('Green time (s)','FontSize',11);
title('Fuzzy — S1/S2','FontSize',12,'FontWeight','bold'); grid on; set(gca,'FontSize',10);

subplot(2,2,2);
plot(gS3_F, '.', 'Color', cFuzzy, 'MarkerSize', 8);
yline(MinGreen,'--k','LineWidth',1.2);
yline(MaxGreen,'--k','LineWidth',1.2);
ylim([MinGreen-5, MaxGreen+5]);
yticks(30:10:MaxGreen+5);
xlabel('Cycle number','FontSize',11); ylabel('Green time (s)','FontSize',11);
title('Fuzzy — S3','FontSize',12,'FontWeight','bold'); grid on; set(gca,'FontSize',10);

subplot(2,2,3);
plot(gS12_NN, '.', 'Color', cNN, 'MarkerSize', 8);
yline(MinGreen,'--k','LineWidth',1.2);
yline(MaxGreen,'--k','LineWidth',1.2);
ylim([MinGreen-5, MaxGreen+5]);
yticks(30:10:MaxGreen+5);
xlabel('Cycle number','FontSize',11); ylabel('Green time (s)','FontSize',11);
title('NN — S1/S2','FontSize',12,'FontWeight','bold'); grid on; set(gca,'FontSize',10);

subplot(2,2,4);
plot(gS3_NN, '.', 'Color', cNN, 'MarkerSize', 8);
yline(MinGreen,'--k','LineWidth',1.2);
yline(MaxGreen,'--k','LineWidth',1.2);
ylim([MinGreen-5, MaxGreen+5]);
yticks(30:10:MaxGreen+5);
xlabel('Cycle number','FontSize',11); ylabel('Green time (s)','FontSize',11);
title('NN — S3','FontSize',12,'FontWeight','bold'); grid on; set(gca,'FontSize',10);

sgtitle('Assigned green time for each simulation cycle', ...
    'FontSize',13,'FontWeight','bold');


% ============================================================
%% FIGURE 2 — Average waiting times ± std: Fuzzy vs NN
% ============================================================
figure('Name','Waiting times','Position',[100 100 680 500]);
labels_w  = categorical({'S1/S2 Waiting Time','S3 Waiting Time'}, ...
                        {'S1/S2 Waiting Time','S3 Waiting Time'});
means_rF  = [avg_rS12_F,  avg_rS3_F ];
means_rNN = [avg_rS12_NN, avg_rS3_NN];
stds_rF   = [std_rS12_F,  std_rS3_F ];
stds_rNN  = [std_rS12_NN, std_rS3_NN];
bw = bar(labels_w, [means_rF; means_rNN]', 'grouped');
bw(1).FaceColor = cFuzzy;  bw(1).FaceAlpha = 0.85;
bw(2).FaceColor = cNN;     bw(2).FaceAlpha = 0.85;
hold on;
errorbar(bw(1).XEndPoints, means_rF,  stds_rF,  'k.','LineWidth',1.8,'HandleVisibility','off');
errorbar(bw(2).XEndPoints, means_rNN, stds_rNN, 'k.','LineWidth',1.8,'HandleVisibility','off');
for i = 1:2
    text(bw(1).XEndPoints(i), means_rF(i)  + stds_rF(i)  + 1.5, ...
        sprintf('%.1f s', means_rF(i)),  'HorizontalAlignment','center', ...
        'FontSize',10,'FontWeight','bold','Color',cFuzzy);
    text(bw(2).XEndPoints(i), means_rNN(i) + stds_rNN(i) + 1.5, ...
        sprintf('%.1f s', means_rNN(i)), 'HorizontalAlignment','center', ...
        'FontSize',10,'FontWeight','bold','Color',cNN);
end
hold off;
ylabel('Average waiting time (s)','FontSize',13);
title('Average waiting times ± std — Fuzzy vs NN','FontSize',14,'FontWeight','bold');
legend({'Fuzzy','NN'},'Location','best','FontSize',12);
set(gca,'FontSize',12); grid on;