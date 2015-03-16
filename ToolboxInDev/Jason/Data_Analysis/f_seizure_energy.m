function f_seizure_energy(dataset,params)
% Usage: f_feature_energy(dataset, params)
% Input: 
%   'dataset'   -   [IEEGDataset]: IEEG Dataset, eg session.data(1)
%   'params'    -   Structure containing parameters for the analysis
% 
%   dbstop in f_seizure_energy at 70

% optimize: upload annotations can be optimized, I think; could make this a
% separate file that either uploads or saves to disk
% need to finish the leftovers part
% convert indexes to microseconds to make things easier
% is normalize by RMS really helping?  Also, it's slow
% Add ability to append annotations?  Append them to the file...then
% reupload.  This could save a lot of time...
% look into downsampling data?
% pad seizures for some percentage of their duration on either side?
% area is very sensitive to large artifacts and fluctuations in the
% baseline - could use a dc filter, or just deal with it in clustering

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

  % save annotations out to a file so addAnnotations can upload them all at
  % once
  annotFile = sprintf('../Output/%s-annot-%s-%s',dataset.snapName,params.label,params.technique);
  ftxt = fopen([annotFile '.txt'],'w');
  fclose(ftxt);  % this flushes the file
  save([annotFile '.mat'],'params');

  if params.saveToDisk
    featureFile = sprintf('../Output/%s-feature-%s-%s',dataset.snapName,params.label,params.technique);
    ftxt = fopen([featureFile '.txt'],'w');
    fclose(ftxt);  % this flushes the file
  end

  for b = 1: numBlocks
    curPt = params.startSample + (b-1)*blockSize;
    endPt = min([b*blockSize+params.startSample-1 params.endSample]);
    data = dataset.getvalues(curPt:endPt,params.channels);
    nw = int64(NumWins(length(data), fs, params.windowLength, params.windowDisplacement));
    idxOut = zeros(nw,1);
%     featureOut = zeros(nw,length(params.channels));
    fprintf('%s: Processing block %d of %d\n', dataset.snapName, b, numBlocks);

    %%-----------------------------------------
    %%---  feature creation and data processing
    normalizer = max(std(data)) ./ std(data);
    for c = 1: length(params.channels)
      data(:,c) = data(:,c) .* normalizer(c);
    end
    
    filtOut = high_pass_filter(data); % Fc = 2 Hz, see below

    featureOut = zeros(nw, length(params.channels));
    for w = 1: nw
      winBeg = params.windowDisplacement * fs * (w-1) + 1;
      winEnd = min([winBeg+params.windowLength*fs-1 length(filtOut)]);
      idxOut(w) = winEnd + curPt - 1; % right-aligned
      featureOut(w,:) = params.function(filtOut(winBeg:winEnd,:)); % right-aligned, = time in usecs from start of data 
    end
    
    % sampling frequency of feature = 1/params.windowDisplacement
    % length of smoother = fsFt * width of smoothing window
    if params.smoothDur > 0
      smoothLength = 1/params.windowDisplacement * params.smoothDur; % in samples of data signal
      smoother =  1 / smoothLength * ones(1,smoothLength);
   %     featureOut = zeros(size(featureOut,1), size(featureOut,2));
      for c = 1: length(params.channels)
        featureOut(:,c) = conv(featureOut(:,c),smoother,'same');
      end
    end
    output = [idxOut featureOut]';
    %%---  feature creation and data processing
    %%-----------------------------------------
   
    % save feature data to file
    if params.saveToDisk
      try
        ftxt = fopen([featureFile '.txt'],'a');  % append rather than overwrite
        fwrite(ftxt,output,'single');
        fclose(ftxt);  
      catch err
        fclose(ftxt);
        rethrow(err);
      end
    end
    
    if params.viewData % plot data?
      plotWidth = 1; % minutes to plot at a time
      day = floor(output(1,1)/24/60/60/fs) + 1;
      leftSamps = output(1,1) - (day-1)*24*60*60*fs;
      hour = floor(leftSamps/60/60/fs);
      numPlots = blockSize/plotWidth/60/fs;
      p = 1;
      while (p <= numPlots)
        curPlot = 1 + (p-1)*plotWidth*60*fs;
        endPlot = min([curPlot+plotWidth*60*fs-1 endPt]);
        curPlotFt = ceil(curPlot/fs);
        endPlotFt = floor(endPlot/fs*1/params.windowDisplacement);
        timeFt = ((double(output(1,:)) - double((day-1)*24*60*60*fs) - double(hour*60*60*fs))) / fs / 60;
        time = ((double(curPt:endPt) - double((day-1)*24*60*60*fs) - double(hour*60*60*fs))) / fs / 60;
        for c = 1: length(params.channels)
          figure(1); subplot(2,2,c); hold on;
          plot(time(curPlot:endPlot),data(curPlot:endPlot,c)/max(data(curPlot:endPlot,c)),'k');
          plot(timeFt(curPlotFt:endPlotFt),output(c+1,curPlotFt:endPlotFt)/max(output(c+1,curPlotFt:endPlotFt)),'r');   
          xlim([floor(plotWidth*(p-1)+time(1)) floor(plotWidth*p+time(1))]);
          ylim([-1 1]);
          xlabel(sprintf('Day %d, Hour %d',day,hour));
          title(sprintf('Channel %d',c));
          line([plotWidth*(p-1) plotWidth*p],[params.minThresh/max(output(c+1,curPlotFt:endPlotFt)) ...
            params.minThresh/max(output(c+1,curPlotFt:endPlotFt))],'Color','r');
          hold off;
        end
        p = p + 1;
        pause
      end
    end

    % find elements of featureOut that are over threshold and convert to
    % start/stop time pairs (in usec)
    % end time is one window off because of the diff above - correct it below
    annotChannels = [];
    annotUSec = [];
    [idx, chan] = find([zeros(1,length(params.channels)); diff((featureOut > params.minThresh))]);
    i = 1;
    while i < length(idx)
      if (chan(i+1) == chan(i))
        if ( (idxOut(idx(i+1)) - idxOut(idx(i)))/fs >= params.minDur )
          annotChannels = [annotChannels; chan(i)];
          annotUSec = [ annotUSec; ...
          [idxOut(idx(i))/fs*1e6 ((idxOut(idx(i+1))/fs-params.windowDisplacement))*1e6] ];
        end
      else
        % insert a NaN as a placeholder? Can weed them out in
        % f_addAnnotationss
        % keyboard;
      end
      i = i + 2;
    end
    annotOutput = [annotChannels annotUSec]';

    try
      ftxt = fopen([annotFile '.txt'],'a'); % append rather than overwrite
      fwrite(ftxt,annotOutput,'single');
      fclose(ftxt);
    catch err
      fclose(ftxt);
      rethrow(err);
    end
  end
end


function y = high_pass_filter(x)
  %HIGH-PASS-CODE Filters input x and returns output y.
  % MATLAB Code
  % Generated by MATLAB(R) 8.2 and the DSP System Toolbox 8.5.
  % Generated on: 26-Feb-2015 13:22:37
  %#codegen
  % To generate C/C++ code from this function use the codegen command.
  % Type 'help codegen' for more information.

  persistent Hd;
  if isempty(Hd)
    % The following code was used to design the filter coefficients:
    %
    % Fstop = 0.1;   % Stopband Frequency
    % Fpass = 2;     % Passband Frequency
    % Astop = 50;    % Stopband Attenuation (dB)
    % Apass = 1;     % Passband Ripple (dB)
    % Fs    = 2000;  % Sampling Frequency
    %
    % h = fdesign.highpass('fst,fp,ast,ap', Fstop, Fpass, Astop, Apass, Fs);
    %
    % Hd = design(h, 'butter', 'MatchExactly', 'stopband', 'SystemObject', true);
    Hd = dsp.BiquadFilter( ...
      'Structure', 'Direct form II', ...
      'SOSMatrix', [1 -2 1 1 -1.99785737576574 0.997861951912608; 1 -1 0 1 ...
      -0.9978619494666 0], ...
      'ScaleValues', [0.998929831919586; 0.9989309747333; 1]);
  end
  try
    y = step(Hd,x);
  catch
    release(Hd);
    Hd = dsp.BiquadFilter( ...
      'Structure', 'Direct form II', ...
      'SOSMatrix', [1 -2 1 1 -1.99785737576574 0.997861951912608; 1 -1 0 1 ...
      -0.9978619494666 0], ...
      'ScaleValues', [0.998929831919586; 0.9989309747333; 1]);
    y = step(Hd,x);
  end
end
