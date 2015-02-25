function [szrUSec, szrChannels] = f_seizure_energy(dataset,params)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_seizure_energy at 93

% optimize: upload annotations can be optimized, I think; could make this a
% separate file that either uploads or saves to disk
% need to finish the leftovers part
% convert indexes to microseconds to make things easier

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

  fname = sprintf('../Output/%s-%s-%s',dataset.snapName,params.label,params.technique);
  save([fname '.mat'],'params');
  ftxt = fopen([fname '.txt'],'w');
  fclose(ftxt);  % this flushes the file
  
  for b = 1: numBlocks
    curPt = params.startSample + (b-1)*blockSize;
    endPt = min([b*blockSize+params.startSample-1 params.endSample]);
    data = dataset.getvalues(curPt:endPt,params.channels);
    nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
    idxOut = zeros(nw,1);
    featureOut = zeros(nw,length(params.channels));
    fprintf('%s: Processing block %d of %d\n', dataset.snapName, b, numBlocks);

    %%---  feature creation and data processing
    normalizer = max(std(data)) ./ std(data);
    for c = 1: length(params.channels)
      data(:,c) = data(:,c) .* normalizer(c);
    end
    
    for w = 1: nw
      winBeg = params.windowDisplacement * fs * (w-1) + 1;
      winEnd = min([winBeg+params.windowLength*fs-1 length(data)]);
      idxOut(w) = winEnd + curPt - 1; % right-aligned
      featureOut(w,:) = params.function(data(winBeg:winEnd,:)); % right-aligned, = time in usecs from start of data 
    end
    
    % sampling frequency of feature = 1/params.windowDisplacement
    % length of smoother = fsFt * width of smoothing window
    smoothLength = 1/params.windowDisplacement * params.smoothDur; % in samples of data signal
    smoother =  1 / smoothLength * ones(1,smoothLength);
    convOut = zeros(size(featureOut,1), size(featureOut,2));
    for c = 1: length(params.channels)
      convOut(:,c) = conv(featureOut(:,c),smoother,'same');
    end
    %%--- end feature creation and data processing
   
    % find elements of convOut that are over threshold and convert to
    % start/stop time pairs (in usec)
    % end time is one window off because of the diff above - correct it below
    szrChannels = [];
    szrUSec = [];
    [idx, chan] = find([zeros(1,length(params.channels)); diff((convOut > params.minThresh))]);
    i = 1;
    while i < length(idx)
      if (chan(i+1) == chan(i))
        if ( (idxOut(idx(i+1)) - idxOut(idx(i)))/fs >= params.minDur ) 
          szrChannels = [szrChannels; chan(i)];
          szrUSec = [ szrUSec; ...
            [idxOut(idx(i))/fs*1e6 ((idxOut(idx(i+1))/fs-params.windowDisplacement))*1e6] ];  
        end
      else
        % insert a NaN as a placeholder?  Can weed them out in
        % f_addAnnotationss
        keyboard;
      end
      i = i + 2;
    end
        
    output = [szrChannels szrUSec]';
    try
      ftxt = fopen([fname '.txt'],'a');  % append rather than overwrite
      fwrite(ftxt,output,'single');
      fclose(ftxt);  
    catch err
      fclose(ftxt);
      rethrow(err);
    end
  end
end

%     if params.uploadAnnotations % upload to portal
%       if b == 1  % remove existing layer if this is the first block
%         layerName = sprintf('%s-%s',params.label,params.technique);
%         try 
%             dataset.removeAnnLayer(layerName);
%             fprintf('\nRemoving existing layer\n');
%         catch 
%             fprintf('No existing layer\n');
%         end
%       end
%       annLayer = dataset.addAnnLayer(layerName);
%       uniqueAnnotChannels = unique(szrChannels);
%       ann = [];
%       fprintf('Creating annotations...');
%       for i = 1:numel(uniqueAnnotChannels)
%           tmpChan = uniqueAnnotChannels(i);
%           ann = [ann IEEGAnnotation.createAnnotations(szrUSec(szrChannels==tmpChan,1),szrUSec(szrChannels==tmpChan,2),'Event',params.label,dataset.channels(tmpChan))];
%       end
%       fprintf('done!\n');
%       numAnnot = numel(ann);
%       startIdx = 1;
%       %add annotations 5000 at a time (freezes if adding too many)
%       fprintf('Adding annotations...\n');
%       for i = 1:ceil(numAnnot/5000)
%           fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
%           annLayer.add(ann(startIdx:min(startIdx+5000,numAnnot)));
%           startIdx = startIdx+5000;
%       end
%       fprintf('done!\n');
%     else   % save to file
