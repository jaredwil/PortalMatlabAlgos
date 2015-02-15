function [idxOut, featureOut] = f_feature_energy_linelength(dataset,channels,params)
% Usage: burst_detector_v2(dataset, blockLenSecs, channels)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'channels'  -   [Nx1 integer array] : channels to process
%   'params'    -   Structure containing parameters for the analysis

  fs = dataset.sampleRate;
  timeValue = sscanf(params.startTime,'%d:');
  startSample = int64(timeValue(1)*24*60*60*fs + timeValue(2)*60*60*fs + ...
    timeValue(3)*60*fs + timeValue(4)*fs + 1); % days:minutes:hours:seconds
  timeValue = sscanf(params.stopTime,'%d:');
  endSample = int64(timeValue(1)*24*60*60*fs + timeValue(2)*60*60*fs + ...
    timeValue(3)*60*fs + timeValue(4)*fs); % days:minutes:hours:seconds
  if endSample == 0 || or endSample > dataset.duration
    endSample = dataset.duration;
  end
  
  durationHrs = (endSample - startSample)*fs*3600;    % duration in hrs
  numBlocks = ceil(duratioHrsn/params.blockDurHr);
  NumWins = @(xLen, fs, winLen, winDisp) (xLen/fs)/winDisp-(winLen/winDisp-1);
  for b = 1: numBlocks
    curPt = (b-1);
    endPt = min([curPt + winLen * fs - 1 length(x)]);
    data = dataset.getvalues(startSample:endSample,channels);
    nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
    [idxOut, featureOut]
  end

  for i = 1: nw
    data = x(curPt+1:endPt);
    idxOut(i) = endPt;
    featureOut(i) = featFn(data);
  end

end


