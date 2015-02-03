function out = LineLength(ChList, PList, FileName, SingleChan);
global eeghdr;
global results;

SingleChan = 1;
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

if ~exist('SingleChan') || isempty(SingleChan)
        SingleChan = 0;
    end

% set the list of channels to run
if ~exist('ChList') || isempty(ChList)
    ChList = [1 2];
elseif strcmp(lower(ChList), 'all')
    ChList = [1:eeghdr.nchan-1; 2:eeghdr.nchan]';
end


% set the parameter list
if ~exist('PList') || isempty(PList)
  windsize = 15;
  thresh = 1.4;
  overlap = 0.2;
  baseperiods = 5 +2;
elseif ~isempty(PList)
  windsize = PList(1);
  thresh = PList(2);
  overlap = PList(3);
  baseperiods = PList(4) +2;
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
results.analysistype = 'linelength';
results.analysislabel = 'Seizures';
results.version = 1.0;
results.windowsecondsize = windsize;
results.analysiswindowoverlap = overlap;
results.baselineperiods = baseperiods;
results.analysissamplerate = downsampleto;
results.rate = eeghdr.rate;
results.lpfilter = lpfilt;
results.hpfilter = [];
results.testthresold = thresh;
results.channelstested = ChList;
results.events = [];

% set up the buffers
Buff = ones(size(ChList,1), baseperiods)*100000;
sBuff = ones(size(ChList,1), baseperiods);
iBuff = 1;

% events (each row): [ticktime chan(1) chan(2) threshvalue]
events = [];


% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    dat = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    for ch = 1:size(ChList,1);
        if SingleChan
            d = dat(:, ChList(ch,1));
        else
            d = dat(:, ChList(ch,1)) - dat(:,ChList(ch,2));
        end
        d = eegfilt(d, lpfilt, 'lp');
        d = d(1:samp:end);
        m = mean(abs(diff(d)));

        if m > thresh*mean(Buff(ch,1:end-2))
            %then seizure
            events(end+1, :) = [i ChList(ch,1) ChList(ch,2) m/mean(Buff(ch,1:end-2))];
            st = datestr(GetEEGData('tick2datetime', i));
            fprintf('event detection (%1.1f, %1.1f) at %s (%s)\n', m/mean(Buff(ch,1:end-2)), std(d)/mean(sBuff(ch,1:end-2)), st, eeghdr.fname);
        end

        Buff(ch,iBuff) = m;
        sBuff(ch,iBuff) = std(d);

    end
    iBuff = iBuff+1;
    if iBuff > baseperiods
        iBuff = 1;
    end
end

results.eventticktimes = events;

% save the results
dp = GetResultsDataPath;
f = [dp GetName('name', eeghdr.FileName) '_' results.analysislabel '.mat'];
save(f, 'results');
fprintf('results saved to %s\n', f);

% now go through and look at which might be seizures
%SeizureFinder('init', results);