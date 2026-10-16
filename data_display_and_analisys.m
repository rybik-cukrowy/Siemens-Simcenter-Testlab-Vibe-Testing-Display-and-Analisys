close all; clear; clc;
% ####
% For analising pre and post modes (from RV)
% ####

% files
pre_file  = 'Y/RS_Y/RS_preRND_Y_1_HarmonicSpectra.mat';
post_file = 'Y/RS_Y/RS_postRND_Y_1_HarmonicSpectra.mat'; 

% settings
axis = 'Y'; % plot only one axis of the accelerometers

% peak detection
minPeakProminence = 0.5; % [g] minimum peak prominence
minPeakDistance   = 5; % [Hz] minimum distance between peaks

% peak matching
maxFreqShift = 20; % [Hz] maximum allowed pre/post frequency difference

% load
pre_data  = load(pre_file);
post_data = load(post_file);

pre  = pre_data.FrequencySpectrum;
post = post_data.FrequencySpectrum;

% extract
f_pre  = pre.x_values.values;
y_pre  = pre.y_values.values;

f_post = post.x_values.values;
y_post = post.y_values.values;

names_pre  = pre.function_record.name;
names_post = post.function_record.name;

% find axis
idx_pre  = endsWith(names_pre, axis) & ~contains(names_pre, "Control");
idx_post = endsWith(names_post, axis) & ~contains(names_pre, "Control");

% extract selected channels
f_pre  = f_pre(:, idx_pre);
y_pre  = y_pre(:, idx_pre);
names_pre = names_pre(idx_pre);

f_post  = f_post(:, idx_post);
y_post  = y_post(:, idx_post);
names_post = names_post(idx_post);

% plot
nChannels = sum(idx_pre);

figure('Name', ['Pre/Post Resonance Search - ' axis]);

for i = 1:nChannels

    %  magnitude
    pre_mag  = abs(y_pre(:,i));
    post_mag = abs(y_post(:,i));

    pre_freq  = f_pre(:,i);
    post_freq = f_post(:,i);

    %  FIND PEAKS
    [pre_peaks, pre_freq_peaks, ~, pre_prom] = ...
        findpeaks(pre_mag, pre_freq, ...
        'MinPeakProminence', minPeakProminence, ...
        'MinPeakDistance', minPeakDistance);

    [post_peaks, post_freq_peaks, ~, post_prom] = ...
        findpeaks(post_mag, post_freq, ...
        'MinPeakProminence', minPeakProminence, ...
        'MinPeakDistance', minPeakDistance);

    %  MATCH PEAKS
    % matched peak information
    matched_pre_freq  = [];
    matched_post_freq = [];
    matched_pre_mag   = [];
    matched_post_mag  = [];

    used_post = false(size(post_freq_peaks));

    for p = 1:length(pre_freq_peaks)

        % frequency difference to all post-test peaks
        freq_diff = abs(post_freq_peaks - pre_freq_peaks(p));

        % ignore already used peaks
        freq_diff(used_post) = Inf;

        % find closest post-test peak
        [min_diff, idx] = min(freq_diff);

        % accept only if within allowed frequency shift
        if min_diff <= maxFreqShift

            matched_pre_freq(end+1)  = pre_freq_peaks(p);
            matched_post_freq(end+1) = post_freq_peaks(idx);

            matched_pre_mag(end+1)   = pre_peaks(p);
            matched_post_mag(end+1)  = post_peaks(idx);

            used_post(idx) = true;
        end
    end

    %  CALCULATE CHANGES
    freq_shift_Hz = matched_post_freq - matched_pre_freq;

    freq_shift_percent = ...
        100 * freq_shift_Hz ./ matched_pre_freq;

    magnitude_change_g = ...
        matched_post_mag - matched_pre_mag;

    magnitude_change_percent = ...
        100 * magnitude_change_g ./ matched_pre_mag;

    magnitude_change_dB = ...
        20 * log10(matched_post_mag ./ matched_pre_mag);

    %  PLOT SPECTRA
    subplot(2,2,i);

    plot(pre_freq, pre_mag, 'g');
    hold on;

    plot(post_freq, post_mag, 'm');

    %  MARK PEAKS
    % detected pre-test peaks
    plot(pre_freq_peaks, pre_peaks, 'gp');

    % detected post-test peaks
    plot(post_freq_peaks, post_peaks, 'mp');

    %  LABEL MATCHED PEAKS
    for p = 1:length(matched_pre_freq)

        % label near the pre-test peak
        %text(matched_pre_freq(p), matched_pre_mag(p), sprintf('  %.1f Hz', matched_pre_freq(p)), 'FontSize', 7);
    end

    %  GRAPH SETTINGS
    grid on;

    title(names_pre{i}, 'Interpreter', 'none');

    xlabel('Frequency [Hz]');
    ylabel('Magnitude [g]');

    legend('Pre', 'Post', ...
           'Pre peaks', 'Post peaks', ...
           'Location', 'best');
end

sgtitle(['Pre/Post Resonance Search - ' axis]);

%  PRINT RESULTS TO CONSOLE
fprintf('\n');
fprintf('============================================================\n');
fprintf(' PRE / POST RESONANCE SEARCH COMPARISON\n');
fprintf(' Axis: %s\n', axis);
fprintf('============================================================\n');


for i = 1:nChannels

    pre_mag  = abs(y_pre(:,i));
    post_mag = abs(y_post(:,i));

    pre_freq  = f_pre(:,i);
    post_freq = f_post(:,i);

    % Find peaks again

    [pre_peaks, pre_freq_peaks, ~, pre_prom] = ...
        findpeaks(pre_mag, pre_freq, ...
        'MinPeakProminence', minPeakProminence, ...
        'MinPeakDistance', minPeakDistance);

    [post_peaks, post_freq_peaks, ~, post_prom] = ...
        findpeaks(post_mag, post_freq, ...
        'MinPeakProminence', minPeakProminence, ...
        'MinPeakDistance', minPeakDistance);

    % Match peaks
    matched_pre_freq  = [];
    matched_post_freq = [];
    matched_pre_mag   = [];
    matched_post_mag  = [];

    used_post = false(size(post_freq_peaks));

    for p = 1:length(pre_freq_peaks)

        freq_diff = abs(post_freq_peaks - pre_freq_peaks(p));

        freq_diff(used_post) = Inf;

        [min_diff, idx] = min(freq_diff);

        if min_diff <= maxFreqShift

            matched_pre_freq(end+1)  = pre_freq_peaks(p);
            matched_post_freq(end+1) = post_freq_peaks(idx);

            matched_pre_mag(end+1)   = pre_peaks(p);
            matched_post_mag(end+1)  = post_peaks(idx);

            used_post(idx) = true;
        end
    end

    % Calculate changes
    freq_shift_Hz = matched_post_freq - matched_pre_freq;

    freq_shift_percent = ...
        100 * freq_shift_Hz ./ matched_pre_freq;

    magnitude_change_percent = ...
        100 * (matched_post_mag - matched_pre_mag) ./ matched_pre_mag;

    magnitude_change_dB = ...
        20 * log10(matched_post_mag ./ matched_pre_mag);

    % Print channel

    fprintf('\n');
    fprintf('%s\n', names_pre{i});
    fprintf('------------------------------------------------------------\n');

    if isempty(matched_pre_freq)

        fprintf('No matching peaks found.\n');

    else

        fprintf('%10s %10s %10s %10s %12s %12s %12s\n', ...
            'Pre Hz', ...
            'Post Hz', ...
            'Shift Hz', ...
            'Shift %', ...
            'Pre [g]', ...
            'Post [g]', ...
            'Mag [%]');

        fprintf('%s\n', repmat('-',1,90));

        for p = 1:length(matched_pre_freq)

            fprintf('%10.2f %10.2f %10.2f %10.2f %12.4f %12.4f %12.2f\n', ...
                matched_pre_freq(p), ...
                matched_post_freq(p), ...
                freq_shift_Hz(p), ...
                freq_shift_percent(p), ...
                matched_pre_mag(p), ...
                matched_post_mag(p), ...
                magnitude_change_percent(p));
        end

        fprintf('\nMagnitude change [dB]:\n');

        for p = 1:length(magnitude_change_dB)

            fprintf('  %.2f Hz -> %.2f Hz : %+7.2f dB\n', ...
                matched_pre_freq(p), ...
                matched_post_freq(p), ...
                magnitude_change_dB(p));
        end
    end
end