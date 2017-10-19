function [start_matched_trig_NEV1, start_matched_trig_NEV2, mindist] = match_triggers_black_box(NEV1, NEV2, itv_start, itv_size, padding)

% This code is looking at the data in two NEV files loaded as NEV1 and NEV2
% and matches the time of interest in the first one to the second and give
% you the indexes that  you need to subtract from your events in your NS3
% files to synchronize them. We try to match the trigger pattern sequence
% from ITV_START - PADDING (both in sec) to ITV_START + ITV_SIZE (in sec).
% We start looking for this pattern in NEV2 from ITV_START - 2*PADDING to
% ITV_START + ITV_SIZE + PADDING to be sure that the pattern from NEV1 will
% be contained in that subpart of NEV2.

% Show some plots after the computation
VALIDATION = true;

if isempty(NEV1.Data.SerialDigitalIO.TimeStamp) || isempty(NEV2.Data.SerialDigitalIO.TimeStamp)
    error('No triggers found');
end

if nargin < 4 % default values if not provided
    itv_size = 2*60;
    padding = 5*60; 
end

% For NEV1, we select the triggers from itv_start to itv_start + itv_size
NEV1_start = find(NEV1.Data.SerialDigitalIO.TimeStampSec >= itv_start , 1);
NEV1_end = find(NEV1.Data.SerialDigitalIO.TimeStampSec >= (itv_start + itv_size) , 1);
if isempty(NEV1_start)
    error('itv_start is too large for NEV1')
end
if isempty(NEV1_end)
    error('itv_start + itv_size is too large for NEV1')
end

% For NEV2, we select the triggers from itv_start-padding to
% itv_start+itv_size+padding to be sure to find the seq from NEV1
if itv_start < padding 
    warning('itv_start smaller than padding, using NEV2 from the beginning');
    NEV2_start = find(NEV2.Data.SerialDigitalIO.TimeStampSec >= 0 , 1);
else
    NEV2_start = find(NEV2.Data.SerialDigitalIO.TimeStampSec >= (itv_start - padding) , 1);
end
NEV2_end = find(NEV2.Data.SerialDigitalIO.TimeStampSec > (itv_start + itv_size + padding) , 1);
if isempty(NEV2_start)
    error('itv_start - padding is too large for NEV2')
end
if isempty(NEV2_end)
    error('itv_start + itv_size + padding is too large for NEV2')
end

% Extracting the inter-trigger intervals and removing the triggers too
% close to each other (one sample apart)
iti_NEV1 = diff(NEV1.Data.SerialDigitalIO.TimeStamp(NEV1_start:NEV1_end));
iti_NEV2 = diff(NEV2.Data.SerialDigitalIO.TimeStamp(NEV2_start:NEV2_end));
v = 1:length(iti_NEV2);
iti_NEV1(iti_NEV1 == 1) = [];
v(iti_NEV2 == 1) = [];
iti_NEV2(iti_NEV2 == 1) = [];
% % converting to 2k to deal with missing samples
% iti_NEV1 = floor(iti_NEV1 / 15); 
% iti_NEV2 = floor(iti_NEV2 / 15);

% Looking for the smallest distance between trigger sequences in NEV1 and 2
dist = Inf(1, length(iti_NEV2)-length(iti_NEV1));
for i = 1 : length(iti_NEV2)-length(iti_NEV1)
    dist(i) = sum((iti_NEV2(i:i+length(iti_NEV1)-1) - iti_NEV1) .^ 2);
end
[mindist, start_matched_trig_NEV2] = min(dist);
% % Previous method using strfind, faster but less robust?
% start_matched_trig_NEV2 = strfind(isi_NEV2, isi_NEV1);

if dist(start_matched_trig_NEV2) > 10
    warning('Closest trigger pattern not very similar');
end
start_matched_trig_NEV1 = NEV1_start;
start_matched_trig_NEV2 = NEV2_start + v(start_matched_trig_NEV2) - 1;

if VALIDATION
    figure, plot(dist, '+')
    ylabel('Distance')
    xlabel('shift on the reduced iti\_NEV2')
    title(['NEV2 shift: ' num2str(start_matched_trig_NEV2) ', dist: ' num2str(mindist)])
    
    figure, plot_triggers(NEV1, start_matched_trig_NEV1, NEV1_end, 'b+', 0.51);
    hold on
    plot_triggers(NEV2, start_matched_trig_NEV2, NEV1_end, 'r+', 0.49);
    legend('NEV1 triggers','NEV2 triggers')
    xlabel('Time (s)')
    ylim([0 1]);
    title('Aligned NEV1 and NEV2 triggers based on the computed shift')
end


end

function plot_triggers(NEV, idx_start, idx_end, style, level)

if nargin < 4
    style = '+';
    level = 1;
end

ts = NEV.Data.SerialDigitalIO.TimeStamp(idx_start:idx_end);
plot((ts - ts(1)) / NEV.MetaTags.SampleRes, level*ones(1,length(ts)), style);

end

