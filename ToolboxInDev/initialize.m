% Initialize variables


params.datasets = {
    'I010_A0001_D001'
    };
params.preprocess = 1;


switch params.label
case 'spike'              % spike-threshold
  switch params.technique
    case 'threshold'
      params.blockDur = 1;  % hours; amount of data to pull at once
  end
case 'burst'
  switch params.technique
    case 'linelength'     % burst-linelength
      params.function = @(x) sum(abs(diff(x))); % sum(x.*x); % feature function
      params.windowLength = 1;         % sec, duration of sliding window
      params.windowDisplacement = 0.5;    % sec, amount to slide window
      params.blockDurHr = 1;            % hours; amount of data to pull at once
      params.smoothDur = 0;   % sec; width of smoothing window
      params.minThresh = 2e5;    % X * stdev(signal); minimum threshold to detect burst; 
      params.minDur = 2;    % sec; min duration of the seizures
      params.addAnnotations = 1; % upload annotations to portal
      params.viewData = 1;  % look at the data while it's running?
      params.saveToDisk = 0;  % save calculations to disk?
  end
case 'seizure'
  switch params.technique
    case 'energy'     % seizure-area
      params.function = @(x) sum(x.*x); % feature function
      params.windowLength = 2;         % sec, duration of sliding window
      params.windowDisplacement = 1;    % sec, amount to slide window
      params.blockDurHr = 1;            % hours; amount of data to pull at once
      params.smoothDur = 30;   % sec; width of smoothing window
      params.minThresh = 15e8;    % X * stdev(signal); minimum threshold to detect burst; 
      params.minDur = 10;    % sec; min duration of the seizures
      params.addAnnotations = 1; % upload annotations to portal
      params.viewData = 0;  % look at the data while it's running?
      params.saveToDisk = 0;  % save calculations to disk?
  end
end


