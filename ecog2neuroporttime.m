function [npStartTime, npEndTime] = ecog2neuroporttime(ecog, np)

% Find the corresponding start and end time in the Neuroport data file
% compared to the ECoG data.
% 
% Part of the MGH/BU data analysis toolbox 
% Authors: Louis Emmanuel Martinet [LEM] <louis.emmanuel.martinet@gmail.com>

SKIP = 1000;

fprintf('Converting ECoG start/end times into Neuroport times... ');

syncCh = num2str(np.SyncInfo.Channel);
lfpRefSkip = openNSx(np.RawFile, 'read', ['c:' syncCh ':' syncCh], 'skipfactor', SKIP);
FsSkip = lfpRefSkip.MetaTags.SamplingFreq / lfpRefSkip.MetaTags.DataPoints * length(lfpRefSkip.Data);
thresh =  mean(abs(lfpRefSkip.Data)) * 10;
[eventTime, eventIdx] = getsyncstamps(lfpRefSkip.Data, FsSkip, thresh);

[ecogStart, npStart, ecogEnd, npEnd] = matchsyncevents(ecog.SyncInfo.EventTime, eventTime);

dtStart = (ecog.SyncInfo.EventIdx(ecogStart) - 1) / ecog.SamplingRate - ecog.Padding(1);
dtEnd = (length(ecog.Data) - ecog.SyncInfo.EventIdx(ecogEnd)) / ecog.SamplingRate - ecog.Padding(2);
npStartTime = eventIdx(npStart) / FsSkip - dtStart;
npEndTime = eventIdx(npEnd) / FsSkip + dtEnd;

fprintf('Done. ');

end