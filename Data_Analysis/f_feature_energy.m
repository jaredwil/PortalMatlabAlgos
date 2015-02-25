function [idxOut, featureOut] = f_feature_energy(dataset,params)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_feature_energy at 59

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
    
    if ~params.uploadAnnotations % save to file
      output = [idxOut convOut]';
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
      plotWidth = 5; % minutes to plot at a time
      day = floor(output(1,1)/24/60/60/fs) + 1;
      leftSamps = output(1,1) - (day-1)*24*60*60*fs;
      hour = floor(leftSamps/60/60/fs);
      numPlots = blockSize/plotWidth/60/fs;
      for p = 1:numPlots
        curPlot = 1 + (p-1)*plotWidth*60*fs;
        endPlot = min([curPlot+plotWidth*60*fs-1 endPt]);
        curPlotFt = ceil(curPlot/fs);
        endPlotFt = floor(endPlot/fs);
        timeFt = ((double(output(1,:)) - double((day-1)*24*60*60*fs) - double(hour*60*60*fs))) / fs / 60;
        time = ((double(curPt:endPt) - double((day-1)*24*60*60*fs) - double(hour*60*60*fs))) / fs / 60;
        for c = 1: length(params.channels)
          figure(1); subplot(2,2,c); hold on;
          plot(time(curPlot:endPlot),data(curPlot:endPlot,c)/max(data(curPlot:endPlot,c)),'k');
          plot(timeFt(curPlotFt:endPlotFt),output(c+1,curPlotFt:endPlotFt)/max(output(c+1,curPlotFt:endPlotFt)),'r');   
          xlim([plotWidth*(p-1) plotWidth*p]);
          ylim([-1 1]);
          xlabel(sprintf('Day %d, Hour %d',day,hour));
          title(sprintf('Channel %d',c));
          line([plotWidth*(p-1) plotWidth*p],[params.minThresh/max(output(c+1,curPlotFt:endPlotFt)) ...
            params.minThresh/max(output(c+1,curPlotFt:endPlotFt))],'Color','r');
          hold off;
        end
        pause;
      end
    end
  end
end

