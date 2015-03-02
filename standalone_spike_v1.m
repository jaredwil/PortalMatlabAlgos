function standalone_spike_final(snapshot, layerName,blockLenSecs, channels)
% Usage: standalone_spike_final(snapshot, layerName,blockLenSecs, channels)
% 
% This function will calculate 300 ms spike windows and upload annotations
% to the dataset on the portal. Spike calculation is based on a set
% threshold based on the standard deviation within each blockLenSecs. 
% Other parameters can be specified
% 
% Input: 
% 'snapshot	[IEEGDataset]: IEEG Dataset loaded within an IEEG Session
% 'layerName	[string]: String containing name of new layer to be added
% 'blockLenSecs' 	[integer]: length (in seconds) of each block to process
%             standard deviation threshold is calculated relative to the length of blockLenSecs
% 'channels' 	[Nx1 integer array] : channels of interest
% 
% Options: 
% 'spike.sepSpkDur' 	: minimum distance between spike peaks
% 'spike.mult' 		: threshold multiplier
% 'spike.filt' 		: filter toggle
% 'spike.frontPad' 	: padding before peak
% 'spike.backPad' 	: padding after peak
% 
% To be implemented
% 'spike.spatial		: use spatial features (field effect)
% 
% Example:
% session = IEEGSession('dataset',Username,PW_bin);
% standalone_spike_v1(session.data,'spikes',30,1:10);
% 
% Update History:
% v1. 3/24/2014 - changed input to IEEGdataset, various other updates
%common params
rate = snapshot.channels(channels(1)).sampleRate;
duration = snapshot.channels(channels(1)).get_tsdetails.getDuration / 1e6;
numBlocks = ceil(duration/blockLenSecs);

%spike params
spike.sepSpkDur = 0.2;
spike.mult = 6; %mult*SD is threshold
spike.filt = 1; %filter toggle
spike.spatial = 0;
spike.frontPad = .100; %100 ms padding on front, 200 ms on back
spike.backPad = .200;

%for each block
spikeTimes = [];
spikeChannels = [];
j = 1;
while j < numBlocks
    curPt = 1+ (j-1)*blockLenSecs*rate;
    endPt = (j*blockLenSecs)*rate;
    tmpData = snapshot.getvalues(curPt:endPt,channels);
    %if not all nans
    if sum(isnan(tmpData)) ~= length(tmpData)
        %detect spikes
        [startTimesSec, chan] = spikeDetector(tmpData, rate, channels, spike);
        disp(['Found ' num2str(size(startTimesSec,1)) ' spikes']);
        if ~isempty(startTimesSec)
            startTimesUsec = ((j-1)*blockLenSecs + startTimesSec(:,1)) * 1e6 - (spike.frontPad*1e6);
            endTimesUsec = ((j-1)*blockLenSecs + startTimesSec(:,1)) * 1e6 + (spike.backPad * 1e6);
            toAdd = [startTimesUsec endTimesUsec];
            spikeTimes = [spikeTimes;toAdd];
            spikeChannels = [spikeChannels;chan];
        end
    end
    disp(['Processed block ' num2str(j) ' of ' num2str(numBlocks)]);
    j = j + 1;
end
disp(['Total spikes found: ' num2str(size(spikeTimes,1))]);

%Removing out of bound spikes
[a, ~] = find(spikeTimes<0);
spikeTimes(unique(a),:) = [];
spikeChannels(unique(a)) = [];

if ~isempty(spikeTimes)
    foundLayer = find(strcmp(layerName,{snapshot.annLayer.name}),1);
    if ~isempty(foundLayer)
        disp('Removing existing spike layer');
        snapshot.removeAnnLayer(layerName);
    end
    spikeLayer = snapshot.addAnnLayer(layerName);
    spikeAnn = [];
    for i = 1:length(spikeChannels)
        spikeAnn = [spikeAnn IEEGAnnotation.createAnnotations(spikeTimes(i,1),spikeTimes(i,2),'Event','Spike',snapshot.channels(spikeChannels(i)))];
    end
    spikeLayer.add(spikeAnn);
    disp('Spike layer added!');
end
end



function [spiketimes, finalChannels] = spikeDetector(data, rate, channels, params)
%Detects spikes in data and returns time of spikes in spikeData. Currently
%only uses an amplitude threshold as a function of standard deviation.
%Improvements pending.
%Input: Timeseries (TxP) with p(p>1) channels, sample rate, channels,
%params.
%Params:
%   1. params.filt: if == 1, will filter data with
%       i. high pass filter at 2 hz
%       ii. low pass filter at 70 hz
%       iii. band gap filter at 58 - 62 hz
%   2. params.mult: set threshold as a multiple of standard deviation
%   3. params.sepSpkDur: time (s) required to distinguish between two
%   spikes

warning('off')

%filter data
if params.filt == 1
    for i = 1:size(data,2);
        L = size(data(:,i),1);
        NFFT = length(data(:,i));%2^nextpow2(L);
        Y = fft(data(:,i),NFFT)/L;
        F = ((0:1/NFFT:1-1/NFFT)*rate).';
        % plot(f,2*abs(Y(1:NFFT/2+1)))
        % xlabel('freq (Hz')
       
        Y(F<=4 | F>=rate-4) = 0;
        Y(F>=70 & F<=rate-70) = 0;
        Y(F>=58 & F<=62) = 0;
        Y(F>=rate-62 & F<=rate-58) = 0;
        %plot(F,abs(Y));
        
        reconY = ifft(Y,NFFT,'symmetric')*L;
        data(:,i) = reconY;
        
%         [b a] = butter(3,[2/(rate/2)],'high');
%         d1 = filtfilt(b,a,data(:,i));
%         [b a] = butter(3,[70/(rate/2)],'low');
%         d1 = filtfilt(b,a,d1);
%         [b a] = butter(3,[55/(rate/2) 65/(rate/2)],'stop');
%         d1 = filtfilt(b,a,d1);
    end
end

numChan = size(data,2);
%sd = median(abs(data)./.6795); %(Quiroga 2004, multiunit spike)
sd = std(data);

x = cell(numChan,1);
for i = 1:numChan
    %find timepoints where value is > than mult*sd for that channel
    tmpData = data(:,i) - repmat(mean(data(:,i)),size(data,1),1);
    [~, x{i}] = findpeaks(abs(tmpData),'MinPeakHeight',params.mult*sd(i),'MinPeakDistance',params.sepSpkDur*rate); 
    %find(abs(data(:,i))>mult*sd(i));
end

%map back to time
spiketimes = [];
finalChannels = [];
for i = 1:size(x,1)
    if ~isempty(x{i})
        [finalspikes, ~]= sort(x{i});
        spkChan = ones(length(finalspikes),1)*channels(i);
        spiketimes = [spiketimes; finalspikes/rate];
        finalChannels = [finalChannels; spkChan];
    end
end

end

