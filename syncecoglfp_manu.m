function [ecogIdx, lfpIdx, ecogRealFs] = syncecoglfp_sz(ecogRef, ecogFs, lfpRef, lfpFs)

% [ECOGIDX, LFPIDX, ECOGREALFS] = SYNCECOGLFP(ECOGREF, ECOGFS, LFPREF,
% LFPFS) uses ECoG and LFP special channels (resp. ECOGREF and LFPREF)
% containing synchronization events to find the corresponding indexes in
% the data (ECOGIDX and LFPIDX), as well as an estimation of the ECoG
% sampling rate ECOGREALFS, assuming that the LFP sampling rate LFPFS is
% correct. ECOGFS is the sampling rate estimated by the recording
% device. Usually ECoG sync events are digitally encoded whereas LFP sync
% events are encoded thanks to pulses. In any cases, a sync event is made
% of a triplet of pulses, the time between pulses within a triplet
% representing a timestamp hh:mm.
% 
% Note: Fs = 500.0056 is perfect for MG49 ecog according to Omar
% This function gives 500.0058 (i.e. 1.4ms difference after 1h) for MG49
% seizure 36
%
% Example
%   [ecogRef, ecogProp] = openEDF(1); % channel 1 in ECoG carries sync events
%   ecogFs = ecogProp.SampleRate(1);
%   lfpProp = NSX_open();
%   lfpRef = NSX_read(lfpProp, 97, 1, 0, Inf)'; % channel 97 in Neuroport LFP
%   lfpFs = 1/lfpProp.Period;
%   [ecogIdx, lfpIdx, ecogRealFs] = syncecoglfp(ecogRef, ecogFs, lfpRef, lfpFs)
% 
% See also: GETSYNCSTAMPS, BUILDSYNCDATASET
%
% Author: Louis-Emmanuel Martinet <louis.emmanuel.martinet@gmail.com>

% Get the timestamps
[ecogStamps, ecogStampsIdx] = getsyncstamps(ecogRef, ecogFs, 0);
z = zeros(length(ecogStamps), 1);
ecogT = datenum([z z z ecogStamps z]);

thresh =  mean(abs(lfpRef)) * 10;
[lfpStamps, lfpStampsIdx] = getsyncstamps(lfpRef, lfpFs, thresh);
z = zeros(length(lfpStamps), 1);
lfpT = datenum([z z z lfpStamps z]);

% Find where is the LFP compared to ECoG
% Be careful that some timestamps are not unique (because every ~30s)

% Which file is starting first between lfp and ecog?
if ecogT(1) < lfpT(1)
    lfpStart = 1;
    ecogStart = find(ecogT == lfpT(lfpStart));
    if length(ecogStart) == 2 && lfpT(lfpStart) ~= lfpT(lfpStart + 1)
        ecogStart = ecogStart(2);
    else 
        ecogStart = ecogStart(1);
    end
else
    ecogStart = 1;
    lfpStart = find(lfpT == ecogT(ecogStart));
    if length(lfpStart) == 2 && ecogT(ecogStart) ~= ecogT(ecogStart + 1)
        lfpStart = lfpStart(2);
    elseif length(lfpStart) == 1 && ecogT(ecogStart) == ecogT(ecogStart + 1)
        ecogStart = 2;
    elseif isempty(lfpStart)
        fprintf('ECoG: %02dh%02d -> %02dh%02d\n', ecogStamps([1 end], :)');
        fprintf('LFP: %02dh%02d -> %02dh%02d\n', lfpStamps([1 end], :)');
        error('No common section in ECoG and LFP data');
    else
        lfpStart = lfpStart(1);
    end
end

% Which file is ending first between lfp and ecog?
if lfpT(end) < ecogT(end)
    lfpEnd = length(lfpT);
    ecogEnd = find(ecogT == lfpT(lfpEnd));
    if length(ecogEnd) == 2 && lfpT(lfpEnd) ~= lfpT(lfpEnd - 1)
        ecogEnd = ecogEnd(1);
    else 
        ecogEnd = ecogEnd(end);
    end
else
    ecogEnd = length(ecogT);
    lfpEnd = find(lfpT == ecogT(ecogEnd));
    if length(lfpEnd) == 2 && ecogT(ecogEnd) ~= ecogT(ecogEnd - 1)
        lfpEnd = lfpEnd(1);
    elseif length(lfpEnd) == 1 && ecogT(ecogEnd) == ecogT(ecogEnd - 1)
        ecogEnd = ecogEnd - 1;
    else
        lfpEnd = lfpEnd(end);
    end
end

ecogIdx = ecogStampsIdx(ecogStart : ecogEnd);
lfpIdx = lfpStampsIdx(lfpStart : lfpEnd);
ecogRealFs = (ecogStampsIdx(ecogEnd) - ecogStampsIdx(ecogStart)) / ...
    (lfpStampsIdx(lfpEnd) - lfpStampsIdx(lfpStart)) * lfpFs;


%%% TODO: integrate code from buildsyncdataset
CHECK = true;

fprintf(['Working on ' patient ' ' seizure '\n']);
timer = tic;

info = szinfo(patient, seizure);
if isempty(info)
    error(['No seizure information for ' patient seizure '.']);
end
ecogCh = info.ECoG.Channels;
lfpCh = info.LFP.Channels;
ecogSyncCh = info.ECoG.SyncCh;
lfpSyncCh = info.LFP.SyncCh;

[ecogRef, ecogProp] = openEDF(info.ECoG.EdfFile, ecogSyncCh); 
fclose(ecogProp.FILE.FID);
ecogFs = ecogProp.SampleRate(1);
ecogSzOn = max([1, round((info.StartTime - onset) * ecogFs)]);
ecogSzOff = min([round((info.EndTime + offset) * ecogFs), length(ecogRef)]);
ecogRef = ecogRef(ecogSzOn:ecogSzOff);
fprintf('ECoG sync channel loaded (%.2f sec)\n', toc(timer));

lfpRef = openNSx('read', info.LFP.Ns5File, ['c:' num2str(lfpSyncCh)]);%, 'precision', 'double');
lfpFs = lfpRef.MetaTags.SamplingFreq;
lfpRef = lfpRef.Data';
lfpMaxIdx = length(lfpRef);
fprintf('LFP sync channel loaded (%.2f sec)\n', toc(timer));

% Align the sync events with the proper ecogRealFs
[ecogIdx, lfpIdx, ecogRealFs] = syncecoglfp(ecogRef, ecogFs, lfpRef, lfpFs);
% Time difference between ecogSzOn and the first sync event
dtStartSz = (ecogIdx(1)-1) / ecogRealFs;
% Use that to find lfpSzOn
lfpSzOn = round(lfpIdx(1) - dtStartSz * lfpFs);

% Same for the end
dtEndSz = (ecogSzOff - ecogIdx(end) - ecogSzOn) / ecogRealFs;
lfpSzOff = round(lfpIdx(end) + dtEndSz * lfpFs);
if lfpSzOn < 1 || lfpSzOff > lfpMaxIdx
    error('LFP data are truncated compared to ECoG data.');
end

% Plot some checks
if CHECK
    lfpRef = lfpRef(lfpSzOn:lfpSzOff);
    edt = 1/ecogRealFs;
    ldt = 1/lfpFs;
    eTimes = 0:edt:(length(ecogRef)-1)*edt;
    elast = eTimes(ecogIdx(end));
    efirst = eTimes(ecogIdx(1));
    lTimes = 0:ldt:(length(lfpRef)-1)*ldt;
    llast = lTimes(lfpIdx(end)-lfpSzOn);
    lfirst = lTimes(lfpIdx(1)-lfpSzOn+1);
    
    figure; ax = plotyy(eTimes, ecogRef, 0:ldt:(length(lfpRef)-1)*ldt, lfpRef);
    legend('ECoG sync event', 'LFP  sync event');
    xlabel('time (s)');
    axes(ax(1)); xlim([efirst - 2*edt efirst + 2*edt]); ylabel('Amplitude'); %#ok<*MAXES>
    axes(ax(2)); xlim([efirst - 2*edt efirst + 2*edt]); ylabel('Amplitude');
    title(['First sync event. Error: ' num2str(abs(efirst-lfirst)) ' sec']);
    
    figure; ax = plotyy(eTimes, ecogRef, 0:ldt:(length(lfpRef)-1)*ldt, lfpRef);
    legend('ECoG sync event', 'LFP  sync event');
    xlabel('time (s)');
    axes(ax(1)); xlim([elast - 2*edt elast + 2*edt]); ylabel('Amplitude');
    axes(ax(2)); xlim([elast - 2*edt elast + 2*edt]); ylabel('Amplitude');
    title(['Last sync event. Error: ' num2str(abs(elast-llast)) ' sec']);
    drawnow;
end

% Create structure with syncing information and clear
syncCheck = struct('ecogRef', ecogRef, 'lfpRef', lfpRef, 'ecogIdx', ecogIdx, 'lfpIdx', lfpIdx, 'lfpSzOn', lfpSzOn, 'lfpSzOff', lfpSzOff);
clear ecogRef lfpRef;
fprintf('Synchronized indexes built (%.2f sec)\n', toc(timer));

% Load only the ecogCh ECoG channels (there are also EEG data) 
[d, ecogProp] = openEDF(info.ECoG.EdfFile, ecogCh(1));
fclose(ecogProp.FILE.FID);
dECoG = zeros(ecogSzOff - ecogSzOn + 1, length(ecogCh));
dECoG(:,1) = d(ecogSzOn : ecogSzOff); clear d;
edfFile = info.ECoG.EdfFile;
parfor i = 2:length(ecogCh)
    [di, prop] = openEDF(edfFile, ecogCh(i));
    dECoG(:,i) = di(ecogSzOn : ecogSzOff); 
    di = []; %#ok<NASGU> % force free memory
    fclose(prop.FILE.FID);
end
fprintf('ECoG loaded (%.2f sec)\n', toc(timer));

% Now get the original LFP data 
% !! loading in int16 for reduce memory !!
dLFP = openNSx('read', info.LFP.Ns5File, ['c:' num2str(lfpCh(1)) ':' num2str(lfpCh(end))], ...
                ['t:' num2str(lfpSzOn)  ':' num2str(lfpSzOff)]);
dLFP = dLFP.Data';
fprintf('LFP loaded (%.2f sec)\n', toc(timer));

% Plot more checks
if CHECK
    figure; ax = plotyy(0:edt:(length(dECoG)-1)*edt, dECoG(:,35), ...
                0:ldt:(length(dLFP)-1)*ldt, dLFP(:,48));
    legend('ECoG Channel 35', 'LFP Channel 48');
    xlabel('time (s)');
    set(get(ax(1),'Ylabel'),'String','Amplitude');
    set(get(ax(2),'Ylabel'),'String','Amplitude');
    drawnow;
end

% Create structures with synced data and its meta-data
ecog = struct('Name', 'ecog', 'File', info.ECoG.EdfFile, 'SamplingRate', ecogRealFs, ...
    'NbChannels', length(ecogCh), 'StartTime', ecogSzOn / ecogFs, ...
    'EndTime', ecogSzOff / ecogFs, 'Labels', ecogProp.Label(ecogCh, :), ...
    'PhysLim', struct('PhysMin', ecogProp.PhysMin(ecogCh), 'PhysMax', ecogProp.PhysMax(ecogCh)), ...
    'Data', dECoG);
lfpLabels = cell2mat(arrayfun(@(i) num2str(i, '%02d'), lfpCh, 'UniformOutput', false)');
lfp = struct('Name', 'lfp', 'File', info.LFP.Ns5File, 'SamplingRate', lfpFs, ...
    'NbChannels', length(lfpCh), 'StartTime', lfpSzOn / lfpFs, ...
    'EndTime', lfpSzOff / lfpFs, 'Labels', lfpLabels, ...
    'Data', dLFP);
sz = struct('Patient', patient, 'Seizure', seizure, 'Onset', onset, ...
            'Offset', offset, 'ECoG', ecog, 'LFP', lfp, 'Sync', syncCheck);

% Load EEG (if it exists)
if isfield(info, 'EEG')
    if isfield(info.EEG, 'Labels') && ~isempty(info.EEG.Labels)
        eegCh = label2index(info.EEG.Labels, ecogProp.Label);
        [dEEG, ~] = openEDF(info.ECoG.EdfFile, eegCh);
        dEEG = dEEG(ecogSzOn : ecogSzOff, :);
        fprintf('EEG loaded (%.2f sec)\n', toc(timer));
        eeg = struct('Name', 'eeg', 'File', ecogProp.FileName, 'SamplingRate', ecogRealFs, ...
        'NbChannels', length(eegCh), 'StartTime', ecogSzOn / ecogFs, ...
        'EndTime', ecogSzOff / ecogFs, 'Labels', ecogProp.Label(eegCh, :), ...
        'PhysLim', struct('PhysMin', ecogProp.PhysMin(eegCh), 'PhysMax', ecogProp.PhysMax(eegCh)), ...
        'Data', dEEG);
        sz.EEG = eeg;
    else
        fprintf('EEG info incomplete\n');
    end
else
    fprintf('No EEG info found\n');
end

fprintf('Saving... ');
global SZSHAREDPATH;
save([SZSHAREDPATH patient '/' patient '_' seizure '_sync.mat'], '-v7.3', 'sz');
fprintf('Done (%.2f sec).\n', toc(timer));

end


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
t2t1 = onsetTimes(2 : 3 : end) - onsetTimes(1:3:end);
t3t1 = onsetTimes(3 : 3 : end) - onsetTimes(1:3:end);
hour = round((t2t1 * 1000 - 100) / 50);
min = round((t3t1 * 1000 - 1500) / 50);
stamps = [hour min];

stampsIdx = onsetBins(diff([onsetTimes(1) - itv ; onsetTimes]) > 0.9 * itv);

end
