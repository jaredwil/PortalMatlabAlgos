function out = FreqDetect(ChList, PList, FileName, idstr);
global eeghdr;
global results;

% open the series of files
if ~exist('FileName')
    FileName = 'file';
    out = GetEEGData;  % open the eeg file through the gui
else
    out = GetEEGData('init', FileName);
end

if isempty(out)
    fprintf('Unable to open %s. Exiting.\n', FileName);
    return
end


% set the list of channels to run
if ~exist('ChList')
    ChList = [1];
elseif strcmp(lower(ChList), 'all')
    ChList = [1:eeghdr.nchan];
end


% set the parameter list
if ~exist('PList')
    windsize = 1;
    thresh = 5;
    overlap = 0.5;
elseif ~isempty(PList)
    windsize = PList(1);
    thresh = PList(2);
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
results.analysistype = 'freqdetect';
results.analysislabel = '6-12Hz_Buzz';
results.version = 1.0;
results.windowsecondsize = windsize;
results.analysiswindowoverlap = overlap;
results.analysissamplerate = downsampleto;
results.rate = eeghdr.rate;
results.lpfilter = lpfilt;
results.hpfilter = [];
results.testthresold = thresh;
results.channelstested = ChList;
results.events = [];

% events (each row): [ticktime chan(1) chan(2) threshvalue]
events = [];

figure;

% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    dat = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    for ch = 1:size(ChList,1);
        d = dat(:, ChList(ch,1));
        e = detrend(d,'constant');
        % do a power spectrum
        [f, x] = pwelch(e,[],[],round(eeghdr.rate),round(eeghdr.rate));
        f(1:3) = 0;
        inc = 1;

        % bin results
        y(1) = sum(f(1:6));
        for j = 7:7:45
            inc = inc+1;
            y(inc) = sum(f(j:j+6));
        end
        % sort results
        [s,d] = sort(y);
        if d(end) ==2
            if s(end-1)*thresh < s(end) && s(end) >  20000

                %then buzz
                events(end+1, :) = [i ChList(ch,1) s(end)/s(end-1) s(end)];
                st = datestr(GetEEGData('tick2datetime', i));
                fprintf('event detection (%1.1f, %1.1f) at %s (%s)\n', s(end)/s(end-1), s(end), st, eeghdr.fname);
                plot(e);
                drawnow
            end
        end

    end
end

results.eventticktimes = events;

% save the results
if ~exist('idstr')
    idstr = '';
end
f = [eeghdr.DataPath GetName('name', eeghdr.FileName) results.analysislabel '.mat'] ;
save(f, 'results');
fprintf('results saved to %s\n', f);

% now go through and look at which might be seizures
SeizureFinder('init', results);