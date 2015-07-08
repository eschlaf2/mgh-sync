function [npStartTime, npEndTime] = ecog2neuroporttime(ecog, np)

% Find the corresponding start and end time in the Neuroport data file
% compared to the ECoG data.
% 
% Part of the MGH/BU data analysis toolbox 
% Authors: Louis Emmanuel Martinet [LEM] <louis.emmanuel.martinet@gmail.com>

IBE = 35; % Interval Between Events: used to add times to be sure we capture an event
syncCh = num2str(np.SyncInfo.Channel);

% We read one sync event to identify the time roughly (to read as few data as possible)
evalc('d = openNSx(np.RawFile, ''noread'');');
Fs = d.MetaTags.SamplingFreq;
idxEnd = num2str(round(Fs * IBE));
npRefSkip = openNSx(np.RawFile, 'read', ['c:' syncCh ':' syncCh], ['t:1:' idxEnd]);
thresh =  mean(abs(npRefSkip.Data)) * 10;
[eventTime, eventIdx] = getsyncstamps(npRefSkip.Data, Fs, thresh);
[eventTime, eventIdx] = deal(eventTime(1,:), eventIdx(1));
z = zeros(size(eventTime,1), 1);
npT = datenum([z z z eventTime z]);
z = zeros(size(ecog.SyncInfo.EventTime,1), 1);
ecogT = datenum([z z z ecog.SyncInfo.EventTime z]);
if npT > ecogT(1)
    error('Neuroport data start after ecog');
end

% We read the restricted sync channel for the np
diffvec = datevec(ecogT(1) - npT);
idxStart = eventIdx + round(Fs * (diffvec(4) * 3600 + diffvec(5) * 60 - IBE));
% We read the whole duration of the ecog in the np channel
diffvec = datevec(ecogT(end) - npT);
idxEnd = eventIdx + round(Fs * (diffvec(4) * 3600 + diffvec(5) * 60 + IBE));
% % Or we can read only a bit more than one minute to pick only 2 sync events
% % at the beginning and use them (much faster, but slightly less precise)
% idxEnd = idxStart + 2 * round(Fs * IBE);
npRefSkip = openNSx(np.RawFile, 'read', ['c:' syncCh ':' syncCh], ...
                    ['t:' num2str(idxStart) ':' num2str(idxEnd)]);
thresh =  mean(abs(npRefSkip.Data)) * 10;
[eventTime, eventIdx] = getsyncstamps(npRefSkip.Data, Fs, thresh);

[ecogStart, npStart, ecogEnd, npEnd] = matchsyncevents(ecog.SyncInfo.EventTime, eventTime);

dtStart = (ecog.SyncInfo.EventIdx(ecogStart) - 1) / ecog.SamplingRate - ecog.Padding(1);
dtEnd = (length(ecog.Data) - ecog.SyncInfo.EventIdx(ecogEnd)) / ecog.SamplingRate - ecog.Padding(2);
npStartTime = (idxStart + eventIdx(npStart) - 1) / Fs - dtStart;
npEndTime = (idxStart + eventIdx(npEnd) - 1) / Fs + dtEnd;

end
