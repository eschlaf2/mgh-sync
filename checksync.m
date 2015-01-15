function checksync(syncInfo, ecogCh, lfpCh, lfpFs)

lfpSyncCh = syncInfo.LFP.Data;
lfpIdx = syncInfo.LFP.EventIdx;
ecogSyncCh = syncInfo.ECoG.Data;
ecogIdx = syncInfo.ECoG.EventIdx;

edt = 1/sync.FsECoGNew;
ldt = 1/lfpFs;
eTimes = 0:edt:(length(ecogSyncCh)-1)*edt;
elast = eTimes(ecogIdx(end));
efirst = eTimes(ecogIdx(1));
lTimes = 0:ldt:(length(lfpSyncCh)-1)*ldt;
llast = lTimes(lfpIdx(end)-lfpSzOn);
lfirst = lTimes(lfpIdx(1)-lfpSzOn+1);

figure; ax = plotyy(eTimes, ecogSyncCh, 0:ldt:(length(lfpSyncCh)-1)*ldt, lfpSyncCh);
legend('ECoG sync event', 'LFP  sync event');
xlabel('time (s)');
axes(ax(1)); xlim([efirst - 2*edt efirst + 2*edt]); ylabel('Amplitude'); %#ok<*MAXES>
axes(ax(2)); xlim([efirst - 2*edt efirst + 2*edt]); ylabel('Amplitude');
title(['First sync event. Error: ' num2str(abs(efirst-lfirst)) ' sec']);

figure; ax = plotyy(eTimes, ecogSyncCh, 0:ldt:(length(lfpSyncCh)-1)*ldt, lfpSyncCh);
legend('ECoG sync event', 'LFP  sync event');
xlabel('time (s)');
axes(ax(1)); xlim([elast - 2*edt elast + 2*edt]); ylabel('Amplitude');
axes(ax(2)); xlim([elast - 2*edt elast + 2*edt]); ylabel('Amplitude');
title(['Last sync event. Error: ' num2str(abs(elast-llast)) ' sec']);

figure; ax = plotyy(0:edt:(length(ecogCh)-1)*edt, ecogCh, ...
                    0:ldt:(length(lfpCh)-1)*ldt, lfpCh);
legend('ECoG Channel', 'LFP Channel');
xlabel('time (s)');
set(get(ax(1),'Ylabel'),'String','Amplitude');
set(get(ax(2),'Ylabel'),'String','Amplitude');

end