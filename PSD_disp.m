close all; clear; clc;
% ####
% For analising PSDs,,,
% ####

% files
PSD_file    = 'X/RND_X/RND_X_PSD.mat';
Signal_file = 'X/RND_X/RND_X_Time.mat';

% settings
axis = 'X';                  % X, Y or Z

% PSD calculation
PSD_resolution = 2;         % [Hz]

%  load
PSD_data    = load(PSD_file);
Signal_data = load(Signal_file);

PSD    = PSD_data.PSD;
Signal = Signal_data.Signal;

% PSD unit conversion
PSD_factor = PSD.y_values.quantity.unit_transformation.factor;
fprintf('PSD unit conversion factor: %.6f\n', PSD_factor);

%  RECONSTRUCT X-AXES
% specified PSD frequency vector
f_PSD = PSD.x_values.start_value + ...
        (0:PSD.x_values.number_of_values-1) * ...
        PSD.x_values.increment;

% time vector
t = Signal.x_values.start_value + ...
    (0:Signal.x_values.number_of_values-1) * ...
    Signal.x_values.increment;

%  EXTRACT Y DATA
y_PSD    = PSD.y_values.values;
y_Signal = Signal.y_values.values;

names_PSD    = PSD.function_record.name;
names_Signal = Signal.function_record.name;

%  SAMPLING FREQUENCY
Fs = 1 / Signal.x_values.increment;

fprintf('\nSampling frequency: %.3f Hz\n', Fs);
fprintf('Signal duration: %.2f s\n', t(end));
fprintf('PSD frequency range: %.1f - %.1f Hz\n', ...
    f_PSD(1), f_PSD(end));

%  find axis
idx_PSD    = endsWith(names_PSD, axis);
idx_Signal = endsWith(names_Signal, axis);

%  Selected channels
y_PSD       = y_PSD(:, idx_PSD);
names_PSD   = names_PSD(idx_PSD);

y_Signal    = y_Signal(:, idx_Signal);
names_Signal = names_Signal(idx_Signal);

%  PSD PARAMETERS
% to obtain 2 Hz frequency resolution:

nfft = round(Fs / PSD_resolution);

windowLength = nfft;
overlap = round(0.5 * windowLength);
window = hann(windowLength);

fprintf('PSD frequency resolution: %.3f Hz\n', Fs/nfft);
fprintf('FFT length: %d samples\n', nfft);
fprintf('Window length: %d samples\n', windowLength);
fprintf('Overlap: %.1f %%\n', 100*overlap/windowLength);

%  PLOT
nChannels = size(y_Signal, 2);

figure('Name', ['Random Vibration PSD - ' axis]);

for i = 1:nChannels

    % spacified
    PSD_target = y_PSD(:,i);

    % PSD measured from time signal
    signal = y_Signal(:,i);

    [PSD_measured, f_measured] = pwelch( ...
        signal, ...
        window, ...
        overlap, ...
        nfft, ...
        Fs);

    %  LIMIT MEASURED PSD TO SPECIFIED FREQUENCY RANGE
    idx = f_measured >= f_PSD(1) & ...
          f_measured <= f_PSD(end);

    f_measured_plot   = f_measured(idx);
    PSD_measured_plot = PSD_measured(idx);

    %  PLOT
    subplot(2,3,i);

    loglog(f_PSD, PSD_target, 'g');

    hold on;

    loglog(f_measured_plot, PSD_measured_plot, 'm');

    grid on;
    grid minor;

    title(names_Signal{i}, ...
        'Interpreter', 'none');

    xlabel('Frequency [Hz]');
    ylabel('PSD [g^2/Hz]');

    legend('Specified PSD', ...
           'Measured PSD', ...
           'Location', 'best');
end

sgtitle(['Random Vibration - ' axis]);

%  GRMS
% Specified GRMS
grms_target = sqrt(trapz(f_PSD, PSD_target));

% measured GRMS
grms_measured = sqrt(trapz(f_measured_plot, PSD_measured_plot));

% display
fprintf('%s\n', names_Signal{i});
fprintf('  Specified GRMS : %.4f g RMS\n', grms_target*PSD_factor);
fprintf('  Measured GRMS  : %.4f g RMS\n', grms_measured*PSD_factor);
fprintf('  Difference     : %+.2f %%\n', ...
    100 * (grms_measured - grms_target) / grms_target);
fprintf('\n');