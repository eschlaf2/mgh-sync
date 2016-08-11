function ecog = mergemultipleecog(ecog1, ecog2, np)

% TODO: possbiel improvement is to actually do the sync at the same time so
% that we correct for the ECoG sampling rates to add the exactly right
% amount of nans

ecog = ECoG;

data1 = ecog1.Data;
Fs1 = ecog1.SamplingRate;
t1 = ecog1.Time;
data2 = ecog2.Data;
Fs2 = ecog2.SamplingRate;
t2 = ecog2.Time;

if isempty(ecog1.SyncInfo.EventTime) || isempty(ecog2.SyncInfo.EventTime)
    error('ECoG: Sync info required when loading from 2 files');
else
    et1 = ecog1.SyncInfo.EventTime;
    ei1 = ecog1.SyncInfo.EventIdx;
    et2 = ecog2.SyncInfo.EventTime;
    ei2 = ecog2.SyncInfo.EventIdx;
end
verboseprintf(['Part1 ends at event ' num2str(et1(end,:)) ' + ' num2str(t1(end) - t1(ei1(end))) 's \n']);
verboseprintf(['Part2 starts at event ' num2str(et2(1,:)) ' - ' num2str(t2(end) - t2(ei2(end))) 's \n']);

% Fill missing time in between intervals if necessary
[~, ~, ecogEnd, npEnd] = matchsyncevents(et1, np.SyncInfo.EventTime);
[ecogStart, npStart, ~, ~] = matchsyncevents(et2, np.SyncInfo.EventTime);
t_after_ecogEnd = t1(end) - t1(ecog1.SyncInfo.EventIdx(ecogEnd));
t_before_ecogStart = t2(ecog2.SyncInfo.EventIdx(ecogStart));
missing = (np.SyncInfo.EventIdx(npStart) - np.SyncInfo.EventIdx(npEnd)) / np.SamplingRate ...
            - (t_after_ecogEnd + t_before_ecogStart);
verboseprintf(['There is ' num2str(missing) 's data missing between the ECoG files \n']);

% Interpolating in case of different sampling rate
if Fs1 < Fs2
    verboseprintf('Sampling rate is different between ECoG files, interpolating... \n');
    t2 = 0 : 1/Fs1 : (length(data2)-1)/Fs2;
    data2 = interp1(ecog2.Time, data2, t2);
    ecog.SamplingRate = Fs1;
elseif Fs1 > Fs2
    verboseprintf('Sampling rate is different between ECoG files, interpolating... \n');
    t1 = 0 : 1/Fs2 : (length(data1)-1)/Fs1;
    data1 = interp1(ecog1.Time, data1, t1);
    ecog.SamplingRate = Fs2;
end

missingNaN = nan(round(missing * ecog.SamplingRate), ecog1.NChannels);
missingt = 1/ecog.SamplingRate * (1 : size(missingNaN, 1)) + t1(end);

ecog.Data = [data1 ; missingNaN ; data2];
ecog.Time = [t1, missingt, missingt(end) + 1/ecog.SamplingRate + t2];
ecog.Name = ecog1.Name(1:strfind(ecog1.Name, '_Part1')-1);
ecog.RawFile = {ecog1.RawFile, ecog2.RawFile};
ecog.NChannels = ecog1.NChannels;
ecog.Labels = ecog1.Labels;
ecog.BadChannels = unique([ecog1.BadChannels ecog2.BadChannels]);
ecog.StartTime = ecog1.StartTime;
ecog.EndTime = ecog1.StartTime + ecog2.EndTime;
ecog.Position = ecog1.Position;
ecog.PhysLim = ecog1.PhysLim;
ecog.GridChannels = ecog1.GridChannels;
ecog.Padding = [ecog1.Padding(1) ecog2.Padding(2)];
ecog.RebuildDate = datestr(now);
ecog.SyncInfo.Channel = ecog1.SyncInfo.Channel;
ecog.SyncInfo.EventTime = [ecog1.SyncInfo.EventTime  ; ecog2.SyncInfo.EventTime];
ecog.SyncInfo.EventIdx = [ecog1.SyncInfo.EventIdx  ; ecog2.SyncInfo.EventIdx];

end
