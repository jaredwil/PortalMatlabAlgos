function [idxOut, featureOut] = f_feature_meancrossings(dataset,params)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_feature_meancrossings at 46

  fs = dataset.sampleRate;
  timeValue = sscanf(params.startTime,'%d:');
  params.startSample = int64((timeValue(1)-1)*24*60*60*fs + timeValue(2)*60*60*fs + ...
    timeValue(3)*60*fs + timeValue(4)*fs + 1); % days:minutes:hours:seconds
  timeValue = sscanf(params.stopTime,'%d:');
  params.endSample = int64((timeValue(1)-1)*24*60*60*fs + timeValue(2)*60*60*fs + ...
    timeValue(3)*60*fs + timeValue(4)*fs); % days:minutes:hours:seconds
  if params.endSample == 0 || params.endSample > dataset.channels(1).getNrSamples
    params.endSample = dataset.channels(1).getNrSamples;
  end
  
  % calculate number of blocks = # of times to pull data from portal
  % calculate number of windows = # of windows over which to calc feature
  durationHrs = (params.endSample - params.startSample)/fs/3600;    % duration in hrs
  numBlocks = ceil(durationHrs/params.blockDurHr);    % data processed in blocks
  blockSize = params.blockDurHr * 3600 * fs;
  NumWins = @(xLen, fs, winLen, winDisp) (xLen/fs)/winDisp-(winLen/winDisp-1); 

  if ~params.uploadAnnotations % save to file
    fname = sprintf('../Output/%s-%s-%s',dataset.snapName,params.label,params.technique);
    save([fname '.mat'],'params');
    ftxt = fopen([fname '.txt'],'w');
    fclose(ftxt);  % this flushes the file
  end
  
  for b = 1: numBlocks
    curPt = params.startSample + (b-1)*blockSize;
    endPt = min([b*blockSize+params.startSample-1 params.endSample]);
    data = dataset.getvalues(curPt:endPt,params.channels);
    nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
    idxOut = zeros(nw,1);
    featureOut = zeros(nw,length(params.channels));

    for w = 1: nw
      winBeg = params.windowDisplacement * fs * (w-1) + 1;
      winEnd = min([winBeg+params.windowLength*fs-1 length(data)]);
      idxOut(w) = winEnd + curPt - 1; % right-aligned
      x = data(winBeg:winEnd,:);
      %       fromAbove = (x(1:end-1,:) - repmat(mean(x),[size(x,1)-1 1]) > 0) & (x(2:end,:) - repmat(mean(x),[size(x,1)-1 1]) <= 0);
      %       fromBelow = (x(1:end-1,:) - repmat(mean(x),[size(x,1)-1 1]) < 0) & (x(2:end,:) - repmat(mean(x),[size(x,1)-1 1]) >= 0);
      %       zeroXings = fromAbove | fromBelow;
      %       featureOut(w,:) = zeroXings;
      % @(x) sum( (x(1:end-1) - mean(x) > 0) & (x(2:end) - mean(x) < 0) | (x(1:end-1) - mean(x) < 0) & (x(2:end) - mean(x) > 0) );
      featureOut(w,:) = params.function(data(winBeg:winEnd,:));
    end

    if ~params.uploadAnnotations % save to file
      output = [idxOut featureOut]';
      try
        ftxt = fopen([fname '.txt'],'a');  % append rather than overwrite
        fwrite(ftxt,output,'single');
        fclose(ftxt);  
      catch err
        fclose(ftxt);
        rethrow(err);
      end
    end
    
    if params.viewData % plot data?
      time = params.startSample:params.endSample;
      figure(1); subplot(211);
      plot(time,data,'k');
      subplot(212);
      plot(idxOut,featureOut,'k');
      keyboard;
    end
  end
end

