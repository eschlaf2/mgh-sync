function [stamps, stampsIdx] = getsyncstamps(syncData, fs, thresh)
  % [STAMPS, STAMPSIDX] = GETSYNCSTAMPS(SYNCDATA, FS, THRESH) extracts the
  % time STAMPS (hour:min and their position STAMPSIDX in the data) of the
  % sync event channel SYNCDATA (analog or digital pulse triplets). FS is the
  % sampling frequency and THRESH is the threshold to find pulses (e.g.
  % mean(abs(SYNCDATA)) * 10 for analog, 0 for digital). Note: time stamps
  % are usually spaced by around 30 sec (not precise).
  %
  % Author: Louis-Emmanuel Martinet <louis.emmanuel.martinet@gmail.com>

  % Find the triplet
  isAboveThresh = syncData > thresh;
  onsetBins = find(isAboveThresh(1:end-1) == 0 & isAboveThresh(2:end) == 1) + 1;
  if length(onsetBins) < 3
      warning('Too few pulses (no triplet), check whether your sync channel is correct');
      stamps = [];
      stampsIdx = [];
      return;
  end
  onsetTimes = onsetBins / fs;
  onsetTimes = reshape(onsetTimes,[],1); % forcing a column vector (see below)

  % Ensure the first 3 pulses belong to the same triplet
  MAXITV = 4.45; % based on mintues encoding (see end of function);
  while length(onsetTimes) >= 3 && onsetTimes(3) - onsetTimes(1) > MAXITV
      onsetTimes = onsetTimes(2 : end);
      onsetBins = onsetBins(2 : end);
  end
  if length(onsetTimes) < 3
      warning('Too much time between triplet pulses, check your sampling rate');
      stamps = [];
      stampsIdx = [];
      return;
  end
  % Same for the end
  while onsetTimes(end) - onsetTimes(end - 2) > MAXITV
      onsetTimes = onsetTimes(1 : end - 1);
      onsetBins = onsetBins(1 : end - 1);
  end

  % Additional steps to clean some trigger channels:
  % 1) remove rebonds after the third event of the triplet
  % Useful for BW11, 20100305-170437-001.ns5
  k = 3;
  while length(onsetTimes) > k
      if onsetTimes(k+1) - onsetTimes(k) > 29
          k = k + 3; % check next triplet
      else
          onsetTimes(k+1) = [];
      end   
  end
  % 2) remove noisy pulses to close to previous ones (<30 s) 
%   diff(onsetTimes)
  
  % Time Conversions
  % Hour = ((t2-t1)-100)/50
  % Minute = ((t3-t1)-1500)/50
  t2t1 = onsetTimes(2:3:end) - onsetTimes(1:3:end);
  t3t1 = onsetTimes(3:3:end) - onsetTimes(1:3:end);
  hour = round((t2t1 * 1000 - 100) ./ 50); % Note: t2t1 = [0.1s 1.25s] for [0h 23h]
  min =  round((t3t1 * 1000 - 1500) ./ 50); % Note: t3t1 = [1.5s 4.45s] for [0min 59min]
  
  min =  round((t3t1 * 1000 - 50 - 50) ./ 50);
  
  t3t2 = onsetTimes(3:3:end) - onsetTimes(2:3:end);
  min =  round((t3t2 * 1000 - 1500) ./ 50);
  
  stamps = [hour min]; % assume times are column-shaped (see above)
  assert(all(hour < 24), 'getsyncstamps: hour is greater than 23');
  assert(all(min < 60), 'getsyncstamps: minute is greater than 59');
  
  stampsIdx = onsetBins([true diff(onsetTimes') > MAXITV]);
end
