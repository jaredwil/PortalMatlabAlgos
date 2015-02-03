function out = CalcEnergy(ChList, PList, FileName, DoingSingle)
global eeghdr;
global results;
global statuswind;

% open the series of files
if ~exist('FileName') 
   FileName = 'file'; 
   out = GetEEGData;  % open the eeg file through the gui
else
   FileName(end-2:end) = 'bni';
   out = GetEEGData('init', FileName);
end
if isempty(out)
    fprintf('Unable to open %s. Exiting.\n', FileName);
    return
end


% default to do difference of two channels
if ~exist('DoingSingle') || isempty(DoingSingle)
    DoingSingle = 0;
end

% set the list of channels to run
if ~exist('ChList') || isempty(ChList)
    ChList = [3 4];
elseif strcmp(lower(ChList), 'all')
    ChList = [1:eeghdr.nchan-1; 2:eeghdr.nchan]';
end


% set the parameter list
if ~exist('PList') || isempty(PList)
  windsize = 60;
  overlap = 0.0;
elseif ~isempty(PList)
  windsize = PList(1);
  overlap = PList(3);
end

downsampleto = 200;
lpfilt = 70;
hunk = eeghdr.rate*windsize; 
olp = round(hunk*(1-overlap));
samp = round(eeghdr.rate/downsampleto);

fprintf('Session start: %s\n', datestr(eeghdr.PtIndx(1).startdatetimevec));
fprintf('Session stop: %s\n', datestr(eeghdr.PtIndx(end).enddatetimevec));

% save some info for the result file
results.DataFile = eeghdr.FileName(1:end-4);
results.DataPath = eeghdr.DataPath;
results.sessionstart = datestr(eeghdr.PtIndx(1).startdatetimevec);
results.sessionstop = datestr(eeghdr.PtIndx(end).enddatetimevec);
results.endtick = eeghdr.PtIndx(end).last;
results.analysistype = 'CalcEnergy';
results.analysislabel = 'Energy';
results.version = 1.0;
results.windowsecondsize = windsize;
results.analysiswindowoverlap = overlap;
results.analysissamplerate = downsampleto;
results.rate = eeghdr.rate;
results.lpfilter = lpfilt;
results.hpfilter = [];
results.channelstested = ChList;
results.events = [];

% events (each row): [ticktime chan(1) chan(2) threshvalue]
hours = zeros(ceil(eeghdr.PtIndx(end).last/(eeghdr.rate*60*60)),5);    % results buffer
min = zeros(60,5);          % temp results buffer

statuswind = waitbar(0,'Calculating energy.  Please wait...', 'Name', GetName('name', results.DataFile));
imin = 1;
ihours = 1;
% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    dat = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    for ch = 1:size(ChList,1);
        if DoingSingle
            d = dat(:, ChList(ch,1));
        else
            d = dat(:, ChList(ch,1)) - dat(:,ChList(ch,2));
        end
        d = detrend(d, 'constant');
        [f, x] = pwelch(d, [], [], round(eeghdr.rate),round(eeghdr.rate));
        min(imin, 1) = sum(f);         % total power
        min(imin, 2) = sum(f(7:13));   % 5.5-12.5Hz
        min(imin, 3) = sum(f(21:81));  % 19.5-80.5Hz
        min(imin, 4) = sum(f(101:201));% 99.5-200.5Hz
        min(imin, 5) = sum(f(202:401));% 200.5-400.5Hz
        
        imin = imin+1;
        if imin == 61
            imin = 1;
            hours(ihours, :) = mean(min); 
            waitbar(ihours/size(hours,1),statuswind);
            ihours = ihours+1;
        end
        
    end
end

if ihours <= size(hours,1)
    hours(ihours) = mean(min(1:imin));
    hours(ihours) = std(min(1:imin));
end
close(statuswind);
statuswind = [];
results.energy = hours;

% save the results
dp = GetResultsDataPath;
f = [dp GetName('name', eeghdr.FileName) '_' results.analysislabel '.mat'] ;
save(f, 'results');
fprintf('results saved to %s\n', f);

