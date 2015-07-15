function s = interpolateneuroport(s)

% Interpolate synced ECoG and Neuroport data to have the same sampling rate
% (near 500 Hz) of the ECoG.
% Be patient! Running time was 265 seconds for MG45 Seizure36 using 8 cores
%
% MAK, July 2015.


s = syncecogneuroport(s);
fprintf(['Times ' num2str(s.ECoG.Time(1),3) ' ' num2str(s.ECoG.Time(end),3) '\n']);

%Build filter for LFP [< ECoG.SamplingRate/2 Hz].
fNQ = s.Neuroport.SamplingRate/2;
hicutoff  = s.ECoG.SamplingRate/2;
filtorder = 1000;
MINFREQ   = 0;
trans     = 0.15; % fractional width of transition zones
f=[MINFREQ hicutoff/fNQ (1+trans)*hicutoff/fNQ 1];
m=[1       1                      0            0];
b_LFP = firls(filtorder,f,m);

%Filter and interpolate the LFP, and filter the ECoG.
tECoG = s.ECoG.Time;                %Get ECoG time axis.
tLFP  = s.Neuroport.Time;           %Get LFP time axis.

data = double(s.Neuroport.Data);
iLFP = zeros(length(tECoG), s.Neuroport.NChannels);
% fprintf('Channels done: ');
fprintf('Progress:\n');
fprintf([repmat('.',1,s.Neuroport.NChannels) '\n\n']);
parfor k = 1:s.Neuroport.NChannels          %For each LFP channel,
    dLFP = filtfilt(b_LFP,1,data(:,k));     %... filter neuroport data,
    iLFP(:,k) = interp1(tLFP, dLFP, tECoG); %... interpolate to ECoG.SamplingRate Hz.
%     fprintf([num2str(k) ', ']);
    fprintf('\b|\n');
end
clear data;

%Update object to hold interpolated & synced data.
s.Neuroport.SamplingRate = s.ECoG.SamplingRate;
s.Neuroport.Data = iLFP;
s.Neuroport.Time = tECoG;

%Save the results.
fName = [s.MatFile(1:end-4) '_interpolated.mat'];
fprintf(['Saving file: ' fName ' ... ']);
s.save(fName);
fprintf(' Saved.\n');

end
