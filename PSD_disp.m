close all; clear; clc;

% ####
% compare control accelerometer data to the control file
% ####


% files
PSD_file     = 'X/RND_X/RND_X_PSD.mat';
Control_file = 'X/RND_X/RND_X_Control.mat';

% settings
axis = 'X';

% load
PSD_data     = load(PSD_file);
Control_data = load(Control_file);

PSD   = PSD_data.PSD;
PSD_1 = Control_data.PSD_1;

% PSD FILE
% Frequency vector
f_PSD = PSD.x_values.start_value + ...
        (0:PSD.x_values.number_of_values-1) .* ...
        PSD.x_values.increment;

% PSD values
y_PSD = PSD.y_values.values;

% Channel names
names_PSD = PSD.function_record.name;

% select right accelerometers
idx_control_X = ...
    contains(names_PSD, 'Control') & ...
    endsWith(names_PSD, axis);

y_control = ...
    y_PSD(:, idx_control_X);

names_control = ...
    names_PSD(idx_control_X);

nControl = size(y_control, 2);

% CHECK
if nControl ~= 2

    error( ...
        'Expected 2 Control X channels, found %d.', ...
        nControl);
end

fprintf('\n');
fprintf('============================================================\n');
fprintf(' RANDOM VIBRATION - X AXIS\n');
fprintf('============================================================\n');

fprintf('\nSelected control accelerometers:\n');

for i = 1:nControl

    fprintf('  %d: %s\n', ...
        i, names_control{i});
end

% CONTROL FILE
% Frequency vector
f_reference = ...
    PSD_1.x_values.start_value + ...
    (0:PSD_1.x_values.number_of_values-1) .* ...
    PSD_1.x_values.increment;

% Values
y_reference = ...
    PSD_1.y_values.values;

% Check number of channels
if size(y_reference, 2) ~= 1

    error( ...
        'PSD_1 contains %d channels instead of 1.', ...
        size(y_reference, 2));
end

% Remove singleton dimension
y_reference = y_reference(:,1);

% UNIT INFORMATION
PSD_factor = ...
    PSD.y_values.quantity.unit_transformation.factor;

fprintf('\n');
fprintf('PSD information:\n');

fprintf('  Frequency range : %.2f - %.2f Hz\n', ...
    f_PSD(1), f_PSD(end));

fprintf('  Frequency step  : %.3f Hz\n', ...
    PSD.x_values.increment);

fprintf('  Number of points: %d\n', ...
    PSD.x_values.number_of_values);

fprintf('\nControl PSD_1 information:\n');

fprintf('  Frequency range : %.2f - %.2f Hz\n', ...
    f_reference(1), f_reference(end));

fprintf('  Frequency step  : %.3f Hz\n', ...
    PSD_1.x_values.increment);

fprintf('  Number of points: %d\n', ...
    PSD_1.x_values.number_of_values);

% PLOT
figure( ...
    'Name', 'Random Vibration - Control X vs PSD_1');

for i = 1:nControl

    subplot(1,2,i);

    % Control accelerometer
    loglog( ...
        f_PSD, ...
        abs(y_control(:,i)), ...
        'm', ...
        'LineWidth', 1.3);
    hold on;

    % Control PSD_1 reference
    loglog( ...
        f_reference, ...
        abs(y_reference), ...
        'g', ...
        'LineWidth', 1.5);
    grid on;
    grid minor;

    title( ...
        names_control{i}, ...
        'Interpreter', 'none');

    xlabel('Frequency [Hz]');
    ylabel('PSD [g^2/Hz]');

    legend( ...
        'Control accelerometer', ...
        'Control PSD_1', ...
        'Location', 'best');
end

sgtitle('Random Vibration - X Axis');

% GRMS
fprintf('\n');
fprintf('============================================================\n');
fprintf(' GRMS COMPARISON\n');
fprintf('============================================================\n');

% Reference GRMS
grms_reference_raw = sqrt( ...
    trapz( ...
        f_reference, ...
        abs(y_reference)));

grms_reference = ...
    grms_reference_raw * PSD_factor;

fprintf('\nControl PSD_1:\n');

fprintf('  GRMS: %.4f g RMS\n', ...
    grms_reference);

% Compare both accelerometers
for i = 1:nControl

    PSD_control = ...
        abs(y_control(:,i));

    % Common frequency range
    f_min = max( ...
        f_PSD(1), ...
        f_reference(1));

    f_max = min( ...
        f_PSD(end), ...
        f_reference(end));

    idx_control = ...
        f_PSD >= f_min & ...
        f_PSD <= f_max;

    idx_reference = ...
        f_reference >= f_min & ...
        f_reference <= f_max;

    % GRMS
    grms_control_raw = sqrt( ...
        trapz( ...
            f_PSD(idx_control), ...
            PSD_control(idx_control)));

    grms_control = ...
        grms_control_raw * PSD_factor;

    % Difference
    grms_difference = ...
        100 * ...
        (grms_control - grms_reference) ...
        / grms_reference;

    % Maximum PSD
    [max_control, idx_max_control] = ...
        max(PSD_control);

    [max_reference, idx_max_reference] = ...
        max(y_reference);

    freq_max_control = ...
        f_PSD(idx_max_control);

    freq_max_reference = ...
        f_reference(idx_max_reference);

    % PRINT
    fprintf('\n');
    fprintf('------------------------------------------------------------\n');
    fprintf('%s\n', names_control{i});
    fprintf('------------------------------------------------------------\n');

    fprintf('Frequency range:\n');
    fprintf('  %.2f - %.2f Hz\n', ...
        f_min, f_max);

    fprintf('\nGRMS:\n');

    fprintf('  Control accelerometer : %.4f g RMS\n', ...
        grms_control);

    fprintf('  Control PSD_1         : %.4f g RMS\n', ...
        grms_reference);

    fprintf('  Difference            : %+.2f %%\n', ...
        grms_difference);

    fprintf('\nMaximum PSD:\n');

    fprintf('  Accelerometer : %.6g at %.2f Hz\n', ...
        max_control, ...
        freq_max_control);

    fprintf('  PSD_1         : %.6g at %.2f Hz\n', ...
        max_reference, ...
        freq_max_reference);
end