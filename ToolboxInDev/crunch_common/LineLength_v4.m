function out = LineLength(FileName);
global eeghdr;
global results;

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



windsize = 1;
thresh = 5;
binthresh = 4;
overlap = 0;
basebins = 10;
delaybins = binthresh + 2;

hunk = eeghdr.rate*windsize;
olp = round(hunk*(1-overlap));
high = 70;
low = 30;

fprintf('Session start: %s\n', datestr(eeghdr.PtIndx(1).startdatetimevec));
fprintf('Session stop: %s\n', datestr(eeghdr.PtIndx(end).enddatetimevec));

% save some info for the result file
results.DataFile = eeghdr.FileName(1:end-4);
results.DataPath = eeghdr.DataPath;
results.sessionstart = datestr(eeghdr.PtIndx(1).startdatetimevec);
results.sessionstop = datestr(eeghdr.PtIndx(end).enddatetimevec);
results.endtick = eeghdr.PtIndx(end).last;
results.analysistype = 'v4linelength';
results.analysislabel = 'v4Seizures';
results.version = 1.0;
results.windowsecondsize = windsize;
results.analysiswindowoverlap = overlap;
results.baselineperiods = basebins;
results.rate = eeghdr.rate;
results.lpfilter = low;
results.hpfilter = high;
results.testthresold = thresh;
results.events = [];

% set up the buffers
binx = 1;
basebuff = ones(1, basebins)* 100000;
dinx = 1;
delaybuff = ones(1, delaybins) * 100000;

% events (each row): [ticktime chan(1) chan(2) threshvalue]
events = [];

base = mean(basebuff);

% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    d = GetEEGData('getdata', [i hunk]);

    e = CleanData(d);
    g = e(:,end);
    if sum(e(:,end-1)) < sum(e(:,end))
        g = e(:,end-1);  % principle components have been flipped
    end
    [f, x] = pwelch(g, [], [], round(eeghdr.rate),round(eeghdr.rate));
    s = (100*sum(f(high:end))/sum(f(1:low)));
    if s > base * thresh
        consecutivebins = consecutivebins + 1;
    else
        consecutivebins = 0;
    end
    if consecutivebins > binthresh
        %then event
        events(end+1, :) = [i];
        st = datestr(GetEEGData('tick2datetime', i));
        fprintf('event detection (%1d) at %s (%s)\n', consecutivebins, st, eeghdr.fname);
    end
    nextbase = delaybuff(dinx);
    delaybuff(dinx) = s;    
    if dinx > delaybins
        dinx = 1;
    end
    
    basebuff(binx) = nextbase;
    binx = binx +1;
    if binx > basebins
        binx = 1;
    end
    base = mean(basebuff);
end

results.eventticktimes = events;

% save the results
dp = GetResultsDataPath;
f = [dp GetName('name', eeghdr.FileName) '_' results.analysislabel '.mat'];
save(f, 'results');
fprintf('results saved to %s\n', f);

