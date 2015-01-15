function [stamps, stampsIdx] = getsyncstamps(syncData, fs, thresh)
  % [STAMPS, STAMPSIDX] = GETSYNCSTAMPS(SYNCDATA, FS, THRESH) extracts the
  % time STAMPS (hour:min and their position STAMPSIDX in the data) of the
  % sync event channel SYNCDATA (analog or digital pulse triplets). FS is the
  % sampling frequency and THRESH is the threshold to find pulses (e.g.
  % mean(abs(SYNCDATA)) * 10 for analog, 0 for digital).
  %
  % Author: Louis-Emmanuel Martinet <louis.emmanuel.martinet@gmail.com>

  % Find the triplet
  isAboveThresh = syncData > thresh;
  onsetBins = find(isAboveThresh(1:end-1) == 0 & isAboveThresh(2:end) == 1) + 1;
  onsetTimes = onsetBins / fs;
  onsetTimes = reshape(onsetTimes,[],1); % forcing a column vector (see below)

  % Ensure the first 3 pulses belong to the same triplet
  itv = max(diff(onsetTimes(1:4)));
  while onsetTimes(3) - onsetTimes(1) > 0.9 * itv
      onsetTimes = onsetTimes(2 : end);
      onsetBins = onsetBins(2 : end);
  end
  % Same for the end
  while onsetTimes(end) - onsetTimes(end - 2) > 0.9 * itv
      onsetTimes = onsetTimes(1 : end - 1);
      onsetBins = onsetBins(1 : end - 1);
  end

  % Time Conversions
  % Hour = ((t2-t1)-100)/50
  % Minute = ((t3-t1)-1500)/50
  t2t1 = onsetTimes(2:3:end) - onsetTimes(1:3:end);
  t3t1 = onsetTimes(3:3:end) - onsetTimes(1:3:end);
  hour = round((t2t1 * 1000 - 100) ./ 50);
  min =  round((t3t1 * 1000 - 1500) ./ 50);
  stamps = [hour min]; % assume times are column-shaped (see above)

  stampsIdx = onsetBins(diff([onsetTimes(1) - itv ; onsetTimes]) > 0.9 * itv);
end
