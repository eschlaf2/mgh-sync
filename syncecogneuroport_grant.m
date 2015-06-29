function obj = syncecogneuroport_grant(obj)

% Author: Louis-Emmanuel Martinet <louis.emmanuel.martinet@gmail.com>
% Modified by Grant Fiddyment (Jun 18 2015)

warning('mgh:syncecogneuroport_grant', 'Deprecated');

PLOTCHECK = true;
SYNCVERSION = '18-Jun-2015, unmerged Grant/Manu version 0.9';
%#ok<*MCNPR>

[ecogSync,ecogProp] = openEDF(obj.ECoG.RawFile,obj.ECoG.SyncChannel);
Nchannels = size(ecogProp.Label,1);
ecogData = openEDF(obj.ECoG.RawFile,setdiff(1:Nchannels,obj.ECoG.SyncChannel)); % get just channels selected...?
fclose(ecogProp.FILE.FID);
lfpSync = openNSx('read', obj.Neuroport.RawFile, 'precision', 'double',...
    ['c:' num2str(obj.Neuroport.SyncChannel) ':' num2str(obj.Neuroport.SyncChannel)], ...
    ['t:' num2str(round((obj.Neuroport.StartTime-obj.Neuroport.Padding(1))*obj.Neuroport.SamplingRate)) ':' num2str(round((obj.Neuroport.EndTime+obj.Neuroport.Padding(2))*obj.Neuroport.SamplingRate+1))]);

% Get sampling rates
ecogFs = obj.ECoG.SamplingRate;
lfpFs = obj.Neuroport.SamplingRate;

% Get the timestamps
% note: threshold of 1e3 for LFP stamps is arbitrary but seems to work
[stamp1, ecogSyncIdx] = getsyncstamps(ecogSync, obj.ECoG.SamplingRate, 0);
[stamp2, lfpSyncIdx] = getsyncstamps(lfpSync.Data,obj.Neuroport.SamplingRate,1e3);

% Trim (ECoG) time stamps to keep only those within seizure
[~,iStart] = ismember(stamp1,stamp2(1,:),'rows'); 
iStart=find(iStart,1,'first');
if stamp1(iStart+1,1)~=stamp2(2,1) || stamp1(iStart+1,2)~=stamp2(2,2)
    iStart=iStart+1;
end
[~,iEnd] = ismember(stamp1,stamp2(end,:),'rows'); 
iEnd=find(iEnd,1,'last');
if stamp1(iEnd-1,1)~=stamp2(end-1,1) || stamp1(iEnd-1,2)~=stamp2(end-1,2)
    iEnd=iEnd-1;
end
stamp1 = stamp1(iStart:iEnd,:); 
ecogSyncIdx = ecogSyncIdx(iStart:iEnd);

% Compute real time passed, ECoG sampling rate
sync.ECoG.EventTimes = stamp1;
sync.Neuroport.EventTimes = stamp2;
sync.ECoG.SamplingRateOld = ecogFs;
sync.Neuroport.SamplingRate = lfpFs;
lfpTime = (1:length(lfpSync.Data))/lfpFs - obj.Neuroport.Padding(1);
ecogFs = (ecogSyncIdx(end)-ecogSyncIdx(1)) / ((lfpSyncIdx(end)-lfpSyncIdx(1))/lfpFs); 
tStart = ecogSyncIdx(1) - round((lfpTime(lfpSyncIdx(1)) + obj.ECoG.Padding(1)) * ecogFs);
tEnd = ecogSyncIdx(end) + round((lfpTime(end) - obj.Neuroport.Padding(2) - lfpTime(lfpSyncIdx(end)) + obj.ECoG.Padding(2)) * ecogFs);
sync.ECoG.EventIdx = ecogSyncIdx - tStart + 1;
sync.Neuroport.EventIdx = lfpSyncIdx;
ecogTime = (1:tEnd-tStart+1) / ecogFs - obj.ECoG.Padding(1);
ecogTime(sync.ECoG.EventIdx) - lfpTime(sync.Neuroport.EventIdx)
dt_shift = mean( ecogTime(sync.ECoG.EventIdx) - lfpTime(sync.Neuroport.EventIdx) ) ;
ecogTime = ecogTime - dt_shift;           
obj.ECoG.SamplingRate = ecogFs;
sync.ECoG.SamplingRateNew = obj.ECoG.SamplingRate;
sync.ECoG.Data = ecogSync(tStart:tEnd);
sync.ECoG.Time = ecogTime;
obj.ECoG.Time = ecogTime;
obj.ECoG.Data = ecogData(tStart:tEnd,:);
obj.Neuroport.Time = lfpTime;
sync.Neuroport.Time = lfpTime;
sync.Neuroport.Data = lfpSync.Data;

obj.addprop('Sync');
obj.Sync = sync;

if PLOTCHECK
%                 checksync(sync, obj.ECoG.Data(:,35), obj.LFP.Data(:,48), obj.LFP.SamplingRate);  
  plot(sync.ECoG.Time,normalize(sync.ECoG.Data),'b',sync.Neuroport.Time,normalize(sync.Neuroport.Data),'r');
  pause;
  for i = 1:length(stamp1)
    xlim(sync.ECoG.Time(sync.ECoG.EventIdx(i)) + [ -0.005 0.005 ]);
    pause;
  end
end

obj.Sync.RebuildDate = datestr(now);
obj.Sync.Version = SYNCVERSION;

end