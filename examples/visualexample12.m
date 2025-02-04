% Evaluation Metrics for Fully Sampled and Undersampled Data

% Extract T1 and T2 Maps
T1_fully = T1_maps{1};
T1_under = T1_maps{2};
T2_fully = T2_maps{1};
T2_under = T2_maps{2};

% Apply mask to consider only valid voxels
T1_fully_masked = T1_fully(mask);
T1_under_masked = T1_under(mask);
T2_fully_masked = T2_fully(mask);
T2_under_masked = T2_under(mask);

% Calculate Metrics for T1
mean_T1_fully = mean(T1_fully_masked);
std_T1_fully = std(T1_fully_masked);
range_T1_fully = [min(T1_fully_masked), max(T1_fully_masked)];

mean_T1_under = mean(T1_under_masked);
std_T1_under = std(T1_under_masked);
range_T1_under = [min(T1_under_masked), max(T1_under_masked)];

rmse_T1 = sqrt(mean((T1_fully_masked - T1_under_masked).^2));

% Calculate Metrics for T2
mean_T2_fully = mean(T2_fully_masked);
std_T2_fully = std(T2_fully_masked);
range_T2_fully = [min(T2_fully_masked), max(T2_fully_masked)];

mean_T2_under = mean(T2_under_masked);
std_T2_under = std(T2_under_masked);
range_T2_under = [min(T2_under_masked), max(T2_under_masked)];

rmse_T2 = sqrt(mean((T2_fully_masked - T2_under_masked).^2));

% Display Results
disp('--- T1 Metrics ---');
disp(['Fully Sampled - Mean: ', num2str(mean_T1_fully), ', Std: ', num2str(std_T1_fully), ', Range: [', num2str(range_T1_fully(1)), ', ', num2str(range_T1_fully(2)), ']']);
disp(['Undersampled - Mean: ', num2str(mean_T1_under), ', Std: ', num2str(std_T1_under), ', Range: [', num2str(range_T1_under(1)), ', ', num2str(range_T1_under(2)), ']']);
disp(['RMSE for T1 Maps: ', num2str(rmse_T1)]);

disp('--- T2 Metrics ---');
disp(['Fully Sampled - Mean: ', num2str(mean_T2_fully), ', Std: ', num2str(std_T2_fully), ', Range: [', num2str(range_T2_fully(1)), ', ', num2str(range_T2_fully(2)), ']']);
disp(['Undersampled - Mean: ', num2str(mean_T2_under), ', Std: ', num2str(std_T2_under), ', Range: [', num2str(range_T2_under(1)), ', ', num2str(range_T2_under(2)), ']']);
disp(['RMSE for T2 Maps: ', num2str(rmse_T2)]);

% Fully Sampled and Undersampled T1/T2 Maps from Both Strategies
% Strategy 1
T1_fully_1 = T1_maps_strategy1{1};
T1_under_1 = T1_maps_strategy1{2};
T2_fully_1 = T2_maps_strategy1{1};
T2_under_1 = T2_maps_strategy1{2};

% Strategy 2
T1_fully_2 = T1_maps_strategy2{1};
T1_under_2 = T1_maps_strategy2{2};
T2_fully_2 = T2_maps_strategy2{1};
T2_under_2 = T2_maps_strategy2{2};

% Number of bins for histograms
numBins = 30;

% Create a figure for comparison
figure;

% T1 Histogram - Strategy 1
subplot(2, 2, 1);
histogram(T1_fully_1, numBins, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'DisplayName', 'Fully Sampled'); hold on;
histogram(T1_under_1, numBins, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'DisplayName', 'Undersampled');
title('T1 - Strategy 1');
xlabel('T1 Values'); ylabel('Frequency');
legend('Fully Sampled', 'Undersampled');
hold off;

% T1 Histogram - Strategy 2
subplot(2, 2, 2);
histogram(T1_fully_2, numBins, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'DisplayName', 'Fully Sampled'); hold on;
histogram(T1_under_2, numBins, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'DisplayName', 'Undersampled');
title('T1 - Strategy 2');
xlabel('T1 Values'); ylabel('Frequency');
legend('Fully Sampled', 'Undersampled');
hold off;

% T2 Histogram - Strategy 1
subplot(2, 2, 3);
histogram(T2_fully_1, numBins, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'DisplayName', 'Fully Sampled'); hold on;
histogram(T2_under_1, numBins, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'DisplayName', 'Undersampled');
title('T2 - Strategy 1');
xlabel('T2 Values'); ylabel('Frequency');
legend('Fully Sampled', 'Undersampled');
hold off;

% T2 Histogram - Strategy 2
subplot(2, 2, 4);
histogram(T2_fully_2, numBins, 'FaceColor', 'b', 'FaceAlpha', 0.5, 'DisplayName', 'Fully Sampled'); hold on;
histogram(T2_under_2, numBins, 'FaceColor', 'r', 'FaceAlpha', 0.5, 'DisplayName', 'Undersampled');
title('T2 - Strategy 2');
xlabel('T2 Values'); ylabel('Frequency');
legend('Fully Sampled', 'Undersampled');
hold off;

% Adjust layout
sgtitle('Histogram Comparison Between Strategies');
