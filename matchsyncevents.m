function [evt1Start, evt2Start, evt1End, evt2End] = matchsyncevents(evt1, evt2)

% This function finds the common sync events between two recordings sets
% and return the first and last indices of these events for both
% recordings. EVT1 and EVT2 are vectors of the sync event times.
% 
% Example:
%   [ecogStart, npStart, ecogEnd, npEnd] = matchsyncevents(ecog.SyncInfo.EventTime, np.SyncInfo.EventTime)
%   Then ecog.SyncInfo.EventTime(ecogStart:ecogEnd,:) and 
%   np.SyncInfo.EventTime(npStart:npEnd,:) should be the same times.
% 
% Note: alternative approaches not used anymore
% - Use strfind (works well if evt1 time interval is within evt2):
%     idS = strfind(evt2T, evt1T);
%     idE = idS + length(evt1T) - 1;
% 
% Part of the MGH/BU data analysis toolbox 
% Authors: Louis Emmanuel Martinet [LEM] <louis.emmanuel.martinet@gmail.com>

% Get the timestamps as a scalar
z = zeros(size(evt1,1), 1);
evt1T = datenum([z z z evt1 z]);
z = zeros(size(evt2,1), 1);
evt2T = datenum([z z z evt2 z]);

% Find where is the recording evt2 compared to evt1
% Be careful that some timestamps are not unique (because every ~30s)
inter = intersect(evt1T, evt2T); % find the common part
if isempty(inter) || length(inter) == 1
    fprintf('Sync events 1: %02dh%02d -> %02dh%02d\n', evt1([1 end], :)');
    fprintf('Sync events 2: %02dh%02d -> %02dh%02d\n', evt2([1 end], :)');
    if isempty(inter)
        error('No common section in these two recordings');
    else
        error('There should be at least two common sync events to avoid ambibuities');
    end
end
evt1Start = find(evt1T == inter(1)); % find where is the first common idx
evt2Start = find(evt2T == inter(1));
if length(evt1Start) == length(evt2Start) % both have 1 or 2 first idx
    [evt1Start, evt2Start] = deal(evt1Start(1), evt2Start(1));
else % one have 2 and the other have 1 so we take only the last
    [evt1Start, evt2Start] = deal(evt1Start(end), evt2Start(end));
end
evt1End = find(evt1T == inter(end)); % find where is the last common idx
evt2End = find(evt2T == inter(end));
if length(evt1End) == length(evt2End) % both have 1 or 2 first idx
    [evt1End, evt2End] = deal(evt1End(end), evt2End(end));
else % one have 2 and the other have 1 so we take only the last
    [evt1End, evt2End] = deal(evt1End(1), evt2End(1));
end

end
