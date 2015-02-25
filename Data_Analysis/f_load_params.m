function params = f_load_params(params)

  switch params.label
    case 'feature'
      switch params.technique
        case 'energy'
          params.function = @(x) sum(x.*x); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once
          params.smoothDur = 30;   % sec; width of smoothing window
          params.minThresh = 15e8;    % X * stdev(signal); minimum threshold to detect burst; 
          params.minDur = 10;    % sec; min duration of the seizures
          params.saveToFile = 1;  % saves annotations to file for upload
          params.addAnnotations = 1; % uploads annotations to portal
          params.viewData = 0;  % look at the data while it's running?
        case 'linelength'
          params.function = @(x) sum(abs(diff(x))); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once
        case 'meancrossings'
          params.function =  @(x) (sum( (x(1:end-1,:) - repmat(mean(x),[size(x,1)-1 1]) > 0) & (x(2:end,:) - repmat(mean(x),[size(x,1)-1 1]) <= 0) ...
            | (x(1:end-1,:) - repmat(mean(x),[size(x,1)-1 1]) < 0) & (x(2:end,:) - repmat(mean(x),[size(x,1)-1 1]) >= 0) )); % feature function
          params.windowLength = 5;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once
        case 'selfconv'
          params.function =  @(x) (conv(x,x,'same')); % feature function
          params.windowLength = 5;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once          
        case 'diff'
          params.function =  @(x) (diff(x)); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once          
      end
    case 'spike'              % spike-threshold
      switch params.technique
        case 'threshold'
          params.blockDur = 1;  % hours; amount of data to pull at once
      end
    case 'burst'
      switch params.technique
        case 'linelength'     % burst-linelength
          params.blockDur = 1;  % hours; amount of data to pull at once
          params.minThresh = 2;    % X * stdev(signal); minimum threshold to detect burst; 
          params.maxThresh = 6;  % X * stdev(signal); maximum threshold;
          params.minDur = 1.5;    % sec; min duration of the burst
          params.maxDur = 10;       % sec; max duration of the burst
          params.winSecs = params.minDur; % sec; size of the window for feature detection
          params.padSecs = 1;   %  sec; amount to pad around the edges of the returned features
          params.filter = 'butter';  % 'butterworth'; if filled, will filter data
          params.highPass = 5;    % Hz; high pass cutoff freq for filter
          params.lowPass = 30;    % Hz; low pass cutoff freq for filter
          params.filtOrder = 5;   % order of the filter to use
          params.downSample = 250; % if >0, will downsample data before analysis
          params.plotData = 0;  % plot data, yes or no
      end
    case 'seizure'
      switch params.technique
        case 'linelength'     % seizure-linelength
          params.blockDur = 1;  % hours; amount of data to pull at once
          params.minThresh = 2;    % X * stdev(signal); minimum threshold to detect burst; 
          params.maxThresh = 6;  % X * stdev(signal); maximum threshold;
          params.minDur = 10;    % sec; min duration of the burst
          params.maxDur = 1000;       % sec; max duration of the burst
          params.winSecs = params.minDur; % sec; size of the window for feature detection
          params.padSecs = 1;   %  sec; amount to pad around the edges of the returned features
          params.filter = 'butter';  % 'butterworth'; if filled, will filter data
          params.highPass = 5;    % Hz; high pass cutoff freq for filter
          params.lowPass = 30;    % Hz; low pass cutoff freq for filter
          params.filtOrder = 5;   % order of the filter to use
          params.downSample = 250; % if >0, will downsample data before analysis
          params.plotData = 0;  % plot data, yes or no
        case 'energy'     % seizure-area
          params.function = @(x) sum(x.*x); % feature function
          params.windowLength = 2;         % sec, duration of sliding window
          params.windowDisplacement = 1;    % sec, amount to slide window
          params.blockDurHr = 1;            % hours; amount of data to pull at once
          params.smoothDur = 30;   % sec; width of smoothing window
          params.minThresh = 15e8;    % X * stdev(signal); minimum threshold to detect burst; 
          params.minDur = 10;    % sec; min duration of the seizures
          params.saveToFile = 1;  % saves annotations to file for upload
          params.addAnnotations = 1; % uploads annotations to portal
          params.viewData = 0;  % look at the data while it's running?
      end
  end
end