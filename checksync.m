function checksync(obj, ecogCh, npCh)

% This function plots a series of plots of the sync channels of ECoG and
% Neuroport to check how big the sync errors are around each common sync
% events, plus plots an example of combined plot of one ECoG channel ECOGCH
% (default 35) and one Neuroport channel NPCH (default 48).
% 
% Part of the MGH/BU data analysis toolbox 
% Authors: Louis Emmanuel Martinet [LEM] <louis.emmanuel.martinet@gmail.com>

if nargin == 1
    ecogCh = 35;
    npCh = 48;
end

% Generating artificial sync channels based on sync event times
npRef = zeros(1, length(obj.Neuroport.Data));
npRef(obj.Neuroport.SyncInfo.EventIdx) = 2;
npRef(obj.Neuroport.SyncInfo.EventIdx - 1) = 1;
npRef(obj.Neuroport.SyncInfo.EventIdx + 1) = 1;
ecogRef = zeros(1, length(obj.ECoG.Data));
ecogRef(obj.ECoG.SyncInfo.EventIdx) = 2;
ecogRef(obj.ECoG.SyncInfo.EventIdx - 1) = 1;
ecogRef(obj.ECoG.SyncInfo.EventIdx + 1) = 1;
edt = 1/obj.ECoG.SamplingRate;

[ecogStart, npStart, ecogEnd, npEnd] = ...
    matchsyncevents(obj.ECoG.SyncInfo.EventTime, obj.Neuroport.SyncInfo.EventTime);
ecogIdx = obj.ECoG.SyncInfo.EventIdx(ecogStart : ecogEnd);
npIdx = obj.Neuroport.SyncInfo.EventIdx(npStart : npEnd);

figure; ax = plotyy(obj.ECoG.Time, ecogRef, obj.Neuroport.Time, npRef);
set(get(ax(1),'Ylabel'),'String','Amplitude');
set(get(ax(2),'Ylabel'),'String','Amplitude');
legend('ECoG sync event', 'Neuroport  sync event');
xlabel('time (s)');
xlimAll = xlim;
errorSync = zeros(1, length(ecogIdx));
for i = 1:length(ecogIdx)
    evtEcog = obj.ECoG.Time(ecogIdx(i));
    evtNp = obj.Neuroport.Time(npIdx(i));
    xlim(ax(1), [evtEcog - 2*edt evtEcog + 2*edt]);
    xlim(ax(2), [evtEcog - 2*edt evtEcog + 2*edt]);
    errorSync(i) = abs(evtEcog - evtNp);
    title(['Sync event ' num2str(i) '. Error: ' num2str(errorSync(i)) ' sec']);
    pause;
end

xlim(ax(1), xlimAll);
xlim(ax(2), xlimAll);
title({['All sync events. Average error: ' num2str(mean(errorSync)) ' sec'],...
       ['Errors: ' num2str(errorSync)]});
pause;

ax = plotyy(obj.ECoG.Time, obj.ECoG.Data(:,ecogCh), obj.Neuroport.Time, obj.Neuroport.Data(:,npCh));
legend(['ECoG Channel ' num2str(ecogCh)], ['Neuroport Channel ' num2str(npCh)]);
xlabel('time (s)');
set(get(ax(1),'Ylabel'),'String','Amplitude');
set(get(ax(2),'Ylabel'),'String','Amplitude');

end
