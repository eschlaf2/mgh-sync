function [stamps, stampsIdx] = gettriggertime_v1(trigger_data, fs, thresh)
% [STAMPS, STAMPSIDX] = GETSYNCSTAMPS_V1(TRIGGER_DATA, FS, THRESH) extracts the
% time STAMPS (hour:min:second) and their position STAMPSIDX in the data of the
% trigger channel TRIGGER_DATA (analog or digital pulse quadruplets). FS is the
% sampling frequency and THRESH is the threshold to find pulses (e.g.
% mean(abs(SYNCDATA)) * 10 for analog, 0 for digital). Note: time stamps
% are spaced by around 10 sec (not precise).
%
% Author: Louis-Emmanuel Martinet <louis.emmanuel.martinet@gmail.com>

% Find the triplet
isAboveThresh = trigger_data > thresh;
onsetBins = find(isAboveThresh(1:end-1) == 0 & isAboveThresh(2:end) == 1) + 1;
if length(onsetBins) < 4
    warning('Too few pulses (no quadruplet), check whether your sync channel is correct');
    stamps = [];
    stampsIdx = [];
    return;
end
onsetTimes = onsetBins / fs;
onsetTimes = reshape(onsetTimes,[],1); % forcing a column vector (see below)

% Ensure the first 3 pulses belong to the same quadruplet
MAXITV = 1.5; % based on interval between 2 pulses (1.49 sec for 99sec/99min/99h);
while length(onsetTimes) >= 4 && onsetTimes(4) - onsetTimes(1) > 3 * MAXITV
    onsetTimes = onsetTimes(2 : end);
    onsetBins = onsetBins(2 : end);
end
if length(onsetTimes) < 4
    warning('Too much time between quadruplet pulses, check your sampling rate');
    stamps = [];
    stampsIdx = [];
    return;
end
% Same for the end
while onsetTimes(end) - onsetTimes(end - 3) > 3 * MAXITV
    onsetTimes = onsetTimes(1 : end - 1);
    onsetBins = onsetBins(1 : end - 1);
end

% additional step to clean some trigger channels by removing rebonds after
% the third event of the triplet
k = 4;
while length(onsetTimes) > k
    if onsetTimes(k+1) - onsetTimes(k) > MAXITV
        k = k + 4; % check next triplet
    else
        onsetTimes(k+1) = [];
    end
end


% Time Conversions, given 4 pulses at t1, t2, t3 and t4 in ms
% hour = (t2-t1)/10 - pulse_length, t2-t1 = [0.51s 1.49s] for [1h 99h???]
% minute = (t3-t2)/10 - pulse_length, t3-t2 = [0.51s 1.49s] for [1min 99min]
% second = (t4-t3)/10 - pulse_length, t4-t3 = [0.51s 1.49s] for [1s 99s]
pulse_length = 50;
t2t1 = onsetTimes(2:4:end) - onsetTimes(1:4:end);
t3t2 = onsetTimes(3:4:end) - onsetTimes(2:4:end);
t4t3 = onsetTimes(4:4:end) - onsetTimes(3:4:end);
hour = round(1000 * t2t1 / 10) - pulse_length;
minute = round(1000 * t3t2 / 10) - pulse_length;
second = round(1000 * t4t3 / 10) - pulse_length; % Note: second increases by 20 every quadruplet
stamps = [hour minute second]; % assume times are column-shaped (see above)
% assert(all(hour < 24), 'getsyncstamps: hour is greater than 23'); % no constraints on hours here
assert(all(minute < 99), 'getsyncstamps: minute is greater than 99');
assert(all(second < 99), 'getsyncstamps: second is greater than 99');

stampsIdx = onsetBins([true diff(onsetTimes') > 3 * MAXITV]);

end
