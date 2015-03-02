function out = FreqHist(ChList, PList, FileName, idstr);
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
    overlap = 0;
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
results.DataFile = GetName('name', eeghdr.FileName);
results.sessionstart = datestr(eeghdr.PtIndx(1).startdatetimevec);
results.sessionstop = datestr(eeghdr.PtIndx(end).enddatetimevec);
results.analysistype = 'freqhist';
results.version = 1.0;
results.windowsecondsize = windsize;
results.analysiswindowoverlap = overlap;
results.analysissamplerate = downsampleto;
results.lpfilter = lpfilt;
results.hpfilter = [];
results.testthresold = thresh;
results.channelstested = ChList;

% events (each row): [ticktime chan(1) chan(2) threshvalue]
events = [];

results.histo = zeros(100,1);

% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    dat = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    for ch = 1:size(ChList,1);
        % do a power spectrum
        [f, x] = pwelch(dat(:, ChList(ch,1)),[],[],round(eeghdr.rate),round(eeghdr.rate));
        t = sum(f(7:13));
        a = sum(f(4:45)) - t;

        % if power in 6-12Hz range is  > than twice all other power (3-45Hz
        % excluding 6-12)
        if t > a
            %then histo
            bin = round(10*log10(t));
            results.histo(bin) = results.histo(bin)+1;
        end

    end
end

% save the results
if ~exist('idstr')
    idstr = '';
end
f = [eeghdr.DataPath eeghdr.FileName idstr 'FreqHisto.mat']
save(f, 'results');

% now go through and look at the results
bar(1:100, results.histo);