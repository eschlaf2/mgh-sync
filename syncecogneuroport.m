function obj = syncecogneuroport(obj)

% This function uses ECoG and Neuroport special channels 
% containing synchronization events to find the corresponding time indexes in
% the data, as well as an estimation of the ECoG
% sampling rate, assuming that the Neuroport sampling rate is more
% reliable. Usually ECoG sync events are digitally encoded whereas NP sync
% events are encoded thanks to pulses. In any cases, a sync event is made
% of a triplet of pulses, the time between pulses within a triplet
% representing a timestamp hh:mm (see GETSYNCSTAMPS for more details).
% 
% See also: GETSYNCSTAMPS
%
% Part of the MGH/BU data analysis toolbox 
% Authors: Louis Emmanuel Martinet [LEM] <louis.emmanuel.martinet@gmail.com>
%          Grant Fiddyment [GMF] <gfiddyment@gmail.com>

SYNCVERSION = '26-Jun-2015, merged Grant/Manu version 1.0 beta';

% Step 1: Find the matching sync events for ECoG and NP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[ecogStart, npStart, ecogEnd, npEnd] = ...
    matchsyncevents(obj.ECoG.SyncInfo.EventTime, obj.Neuroport.SyncInfo.EventTime);

% Step 2: Estimate the new ECoG sampling rate and Padding 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ecogFs = obj.ECoG.SamplingRate;
npFs = obj.Neuroport.SamplingRate;
ecogIdx = obj.ECoG.SyncInfo.EventIdx(ecogStart : ecogEnd);
npIdx = obj.Neuroport.SyncInfo.EventIdx(npStart : npEnd);
% Update ECoG sampling rate assuming NP one is correct
ecogRealFs = (ecogIdx(end) - ecogIdx(1)) / (npIdx(end) - npIdx(1)) * npFs;
obj.ECoG.SyncInfo.OldSampligRate = ecogFs;
obj.ECoG.SamplingRate = ecogRealFs;
% Update padding so that t=0s is centered correctly on sz onset
obj.ECoG.Padding = obj.ECoG.Padding * ecogFs / ecogRealFs;
obj.ECoG.inittime();

% Step 3: Find the new data start and end times for the Neuroport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Time difference between ECoG/NP data start and the first sync event
dtStartEcog = (ecogIdx(1) - 1) / ecogRealFs;
dtStartNp = (npIdx(1) - 1) / npFs;
% Same for the end
dtEndEcog = (length(obj.ECoG.Data) - ecogIdx(end)) / ecogRealFs;
dtEndNp = (length(obj.Neuroport.Data) - npIdx(end)) / npFs;
% Time difference between ECoG/NP seizure onset and the first sync event
dtOnsetEcog = dtStartEcog - obj.ECoG.Padding(1);
dtOnsetNp = dtStartNp - obj.Neuroport.Padding(1);
% Time difference between ECoG/NP seizure end (=offset) and the last sync event
dtOffsetEcog = dtEndEcog - obj.ECoG.Padding(2);
dtOffsetNp = dtEndNp - obj.Neuroport.Padding(2);
% Because we trust ECoG start/end times, we update NP ones
obj.Neuroport.StartTime = obj.Neuroport.StartTime - (dtOnsetEcog - dtOnsetNp);
obj.Neuroport.EndTime = obj.Neuroport.EndTime + (dtOffsetEcog - dtOffsetNp);
% Update NP padding too so that t=0s is centered correctly on sz onset
obj.Neuroport.Padding(1) = obj.Neuroport.Padding(1) - (dtOnsetEcog - dtOnsetNp);
obj.Neuroport.Padding(2) = obj.Neuroport.Padding(2) - (dtOffsetEcog - dtOffsetNp);
obj.Neuroport.inittime();

% Step 4: Build a common axis restricted to available data in both ECoG & NP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

commonStart = max(obj.ECoG.Time(1), obj.Neuroport.Time(1));
commonEnd = min(obj.ECoG.Time(end), obj.Neuroport.Time(end));
obj.ECoG.SyncInfo.CommonIdx = find(obj.ECoG.Time >= commonStart& obj.ECoG.Time <= commonEnd);
% For example, obj.ECoG.Times(obj.ECoG.SyncInfo.CommonIdx) gives the
% restricted common time axis sampled for the ECoG
obj.Neuroport.SyncInfo.CommonIdx = find(obj.Neuroport.Time >= commonStart& obj.Neuroport.Time <= commonEnd);

% Step 4: Save some sync info
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isprop(obj, 'Sync')
    obj.addprop('Sync');
end
obj.Sync.RebuildDate = datestr(now);
obj.Sync.Version = SYNCVERSION;
obj.ECoG.SyncInfo.RebuildDate = obj.Sync.RebuildDate;
obj.ECoG.SyncInfo.Version = obj.Sync.Version;
obj.Neuroport.SyncInfo.RebuildDate = obj.Sync.RebuildDate;
obj.Neuroport.SyncInfo.Version = obj.Sync.Version;

end
