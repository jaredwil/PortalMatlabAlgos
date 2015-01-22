function [eventTimesUSec, eventChannels] = f_burstDetection_linelength(dataset,params)
%Usage: burst_detector_v2(dataset, blockLenSecs, channels)
%This function will calculate bursts based on line length.
%Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset loaded within an IEEG Session
%   'channels'  -   [Nx1 integer array] : channels of interest

% Author: Hoameng Ung, Questions,comments,bugs : hoameng@upenn.edu

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright 2013 Trustees of the University of Pennsylvania
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
% http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

channels = params.channels;
blockDur = params.blockDur;
thres = params.minThresh;
maxThres = params.maxThresh;
minDur = params.minDur;
maxDur = params.maxDur;

%common params
fs = dataset.channels(channels(1)).sampleRate;
duration = dataset.channels(channels(1)).get_tsdetails.getDuration / 1e6;
blockLenSecs = blockDur*60*60;
numBlocks = 2; % ceil(duration/blockLenSecs);

dbstop in f_burstDetection_linelength at 103;
% edit so it can run 4 channels?
% edit so params is created in wrapper and passed to burst_detector?
% change duration of block to a passed parameter?
% why is the zeros vector needed in the diff in burst_detector?

% %burst params
% % the amount of padding before and after threshold onset/offset to use, in
% % seconds  
% params.plotsOn = 0;
% params.filt = filtFlag;
% params.padSecs = .02; % 0.02
% params.winSecs = minDur;   % winDur or 1; duration of the data window to calculate feature, sec; suggest setting this to minDur
% params.thres = thres;
% params.maxThres = maxThres;
% params.minDur = minDur;
% params.maxDur = maxDur;

%line length anonymous function
params.featFn = @(X, winLen) conv2(abs(diff(X,1)),repmat(1/winLen,winLen,1),'same');

%for each block
eventTimesUSec = [];
eventChannels = [];
totEvents = 0;
reverseStr = '';
for c = 1:numel(channels)
  for i = 1:numBlocks
    curPt = 1+ (i-1)*blockLenSecs*fs;
    endPt = (i*blockLenSecs)*fs;
    tmpData = dataset.getvalues(curPt:endPt,channels(c));  
%     if fs > 250
%       tmpData = decimate(tmpData,floor(fs/250),4);
%       fs = fs/floor(fs/250);
%     end

    %if not all nans
    if sum(isnan(tmpData)) ~= length(tmpData)
        %detect bursts
        [startTimesSec, endTimesSec, chan] = burstDetector(tmpData, fs, channels(c),params); 
        
        if ~isempty(startTimesSec)
            totEvents = totEvents + size(startTimesSec,1);
            startTimesUsec = ((i-1)*blockLenSecs + startTimesSec) * 1e6;
            endTimesUsec = ((i-1)*blockLenSecs + endTimesSec) * 1e6;
            toAdd = [startTimesUsec endTimesUsec];
            eventTimesUSec = [eventTimesUSec;toAdd];
            eventChannels = [eventChannels;chan'];
        end
    end
    percentDone = 100 * i / numBlocks;
    msg = sprintf('Channel %d. Percent done: %3.1f -- Bursts found: %d ',channels(c),percentDone,totEvents); %Don't forget this semicolon
    fprintf([reverseStr, msg]);
    reverseStr = repmat(sprintf('\b'), 1, length(msg));
  end
end
 
end


function [startTimesSec, endTimesSec, chan] = burstDetector(data, fs, channels, params)

orig = data;
%filter data
if ~isempty(params.filter)
    for i = 1:size(data,2);
%         dbstop in burst_detector_v2 at 95
%         [b, a] = butter(6,(30/(fs/2)),'low');
%         d1 = filtfilt(b,a,data(:,i));
        try
            [b, a] = butter(params.filtOrder,params.lowPass/(fs/2),'low');
            d1 = filtfilt(b,a,data(:,i));
            [b, a] = butter(params.filtOrder,params.highPass/(fs/2),'high');
            d1 = filtfilt(b,a,d1);
        catch
        end
%         [b, a] = butter(4,[58/(fs/2) 62/(fs/2)],'stop');  % line noise filter
%         d1 = filtfilt(b,a,d1);
        data(:,i) = d1;
    end
end

featWinLen = round(params.winSecs * fs);
featVals = params.featFn(data, featWinLen);
avgFeatVal = mean(featVals);
avgFeatVal = repmat(avgFeatVal,size(featVals,1),1);
nfeatVals = featVals./avgFeatVal; % normalize the curve length calculation

% get the time points where the feature is above the threshold (and it's not
% NaN)
aboveThresh = ~isnan(nfeatVals) & nfeatVals > params.minThresh & nfeatVals<params.maxThresh;

% create the pad filter
numPad = round(params.padSecs*fs);
%pad numPad on each side
padFilt = ones(numPad*2+1,1);
% pad/smear threshold crossings
%aboveThreshPad = conv(double(aboveThresh), padFilt, 'same') > 0;
aboveThreshPad = conv2(double(aboveThresh), padFilt, 'same') > 0;
% aboveThreshPad = aboveThresh;

%get event start and end window indices - modified for per channel
%processing; using the zeros(1,#channels) inserts zeros at the beg/end
[evStartIdxs, chan] = find(diff([zeros(1,size(aboveThreshPad,2)); aboveThreshPad]) == 1);
[evEndIdxs, ~] = find(diff([aboveThreshPad; zeros(1,size(aboveThreshPad,2))]) == -1);
evEndIdxs = evEndIdxs + 1;

startTimesSec = evStartIdxs/fs;
endTimesSec = evEndIdxs/fs;

if numel(channels) == 1
    channels = [channels channels];
end
%map chan idx back to channels
chan = channels(chan);

%   %remove spikes by thresholding max line length
%   idx = [];
%   for i = 1:size(evStartIdxs,1)
%       maxFeat = max(max(featVals(evStartIdxs(i):evEndIdxs(i),:)));
%       if maxFeat>maxfeatThresh
%           idx = [idx i];
%       end
%   end
%   startTimesSec(idx) = [];
%   endTimesSec(idx) = [];
%   chan(idx) = [];
  
duration = endTimesSec - startTimesSec;
idx = (duration<(params.minDur) | (duration>params.maxDur));
startTimesSec(idx) = [];
endTimesSec(idx) = [];
chan(idx) = [];
if params.plotData
    subplot(3,1,1);plot((1:1:length(orig))*1/fs/60,orig(:,1));  % original
    subplot(3,1,2);plot((1:1:length(data))*1/fs/60,data(:,1)); % filtered
    subplot(3,1,3);plot((1:1:length(nfeatVals))*1/fs/60,nfeatVals(:,1));  % curve length
    if ~isempty(startTimesSec)
        subplot(3,1,3); line([startTimesSec./60 endTimesSec./60],[5 5],'Color','r');
    end
    linkaxes(get(gcf,'children'),'x');
    keyboard;
end

end

