function out = LineLength;
global eeghdr;

GetEEGData;  % open the eeg file
PlotEEGData('initvars');
%hunk = eeghdr.rate*30; % 30 second pieces    d = GetEEGData('getdata', [i hunk]);
windsize = 33;
thresh = 1.7;
overlap = 0.1;
SearchCh =  1;
baseperiods = 2;
downsampleto = 200;
lpfilt = 70;

hunk = eeghdr.rate*windsize; % 
olp = round(hunk*(1-overlap));
samp = round(eeghdr.rate/downsampleto);
Buff = ones(1,baseperiods)*100000;
sBuff = ones(1,baseperiods);
iBuff = 1;
events = [];
fprintf('Session start: %s\n', datestr(eeghdr.PtIndx(1).startdatetimevec));
fprintf('Session stop: %s\n', datestr(eeghdr.PtIndx(end).enddatetimevec));
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    d = GetEEGData('getdata', [i hunk]);
    d = d(:, SearchCh) - d(:,SearchCh+1);
    d = eegfilt(d, lpfilt, 'lp');
    d = d(1:samp:end);
    m = mean(abs(diff(d)));
    if m > thresh*mean(Buff)
        %then seizure
        events(end+1) = i;
        st = datestr(GetEEGData('tick2datetime', i));
        %if std(d)/mean(sBuff)>=2
        fprintf('event detection (%1.1f, %1.1f) at %s (%s)\n', m/mean(Buff), std(d)/mean(sBuff), st, eeghdr.fname);
        %end
    end
    Buff(iBuff) = m;
    sBuff(iBuff) = std(d);
    iBuff = iBuff+1;
    if iBuff > baseperiods
        iBuff = 1;
    end
end

results.DataFile = eeghdr.FileName(1:end-4);
results.sessionstart = datestr(eeghdr.PtIndx(1).startdatetimevec);
results.sessionstop = datestr(eeghdr.PtIndx(end).enddatetimevec);
results.analysistype = 'line length';
results.thresold = thresh;
results.searchchannel = [SearchCh SearchCh+1]; 
results.analysiswindowoverlap = overlap;
results.windowsecondsize = windsize;
results.baselineperiods = baseperiods;
results.analysissamplerate = downsampleto;
results.lpfilter = lpfilt;
results.hpfilter = [];
results.eventticktimes = events;
% now go through and look at which might be seizures
save
SeizureFinder('init', events);