function out = r042ll(FileName, idstr);
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


% set the list of channels to run
    ChList = [2];


% set the parameter list
  windsize = 15;
  thresh = 150;
  overlap = 0.5;
  baseperiods = 5 +2;
  thrvar = 3;


lpfilt = 40;
hpfilt = 10;
hunk = eeghdr.rate*windsize; 
olp = round(hunk*(1-overlap));

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
results.analysissamplerate = eeghdr.rate;
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


GetEEGData('limitchannels', ChList);
% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    d = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    d = eegfilt(d, lpfilt, 'lp');
    d = eegfilt(d, hpfilt, 'hp');
    mm = find(abs(d) > thresh );
    m = length(mm);
    
    if m > length(d)/2  & (mean(d) < thresh) & std(abs(d(mm))) < thrvar*thresh % if more than half the points are over thresh
        %then seizure
        events(end+1, :) = [i ChList m];
        st = datestr(GetEEGData('tick2datevec', i));
        fprintf('event detection (%1.1f %1.1f) at %s (%s)\n', m, std(abs(d(mm))), st, eeghdr.fname);
    end
end

results.eventticktimes = events;

% save the results

f = [eeghdr.DataPath GetName('name', eeghdr.FileName) '_' results.analysislabel '.mat'] 
save(f, 'results');
fprintf('results saved to %s\n', f);

% now go through and look at which might be seizures
%SeizureFinder('init', results);