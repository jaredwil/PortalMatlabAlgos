function DownSampleEEG(InFile, OutRate);
global eeghdr;

%InName = GetName('full',InFile);   % file name with extensions

out = GetEEGData('init', InFile);

if isempty(out)
    fprintf('Can''t open %s.  Aborting.\n', InFile);
    out = 0;
    return
else
    out = 1;
end


CreateEEG('init', 'fromEEG');

if ~exist('OutRate') | isempty(OutRate) 
    CreateEEG('setrate', 250);
    OutRate = 250;
else
    CreateEEG('setrate', OutRate);
end

% write to output files
hunk = 1000000;
i = 0;
while 1
    dat = GetEEGData('ticks',[i, hunk]);
    if isempty(dat)
        break
    end
    data = [];
    for k = 1:size(dat,2)
         data(:,k) = resample(double(dat(:,k)), OutRate, eeghdr.rate);
    end

    CreateEEG('data', data);
    i = i+hunk; 
end

CreateEEG('close');  % close last output data file
GetEEGData('closedatafile'); % close last input data file

