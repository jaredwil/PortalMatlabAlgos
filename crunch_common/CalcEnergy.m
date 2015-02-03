function out = CalcEnergy(ChList, PList, FileName, idstr);
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
    ChList = [1 2];
elseif strcmp(lower(ChList), 'all')
    ChList = [1:eeghdr.nchan-1; 2:eeghdr.nchan]';
end


% set the parameter list
if ~exist('PList')
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
results.lpfilter = lpfilt;
results.hpfilter = [];
results.channelstested = ChList;
results.events = [];

% events (each row): [ticktime chan(1) chan(2) threshvalue]
hours = zeros(ceil(eeghdr.PtIndx(end).last/(eeghdr.rate*60*60)),2);    % results buffer (mean, std)
min = zeros(60,1);          % temp results buffer

imin = 1;
ihours = 1;
% run the analysis
for i = 0:olp:eeghdr.PtIndx(end).last-hunk
    dat = GetEEGData('getdata', [i hunk]);

    %for each channel pair in the list
    for ch = 1:size(ChList,1);
        d = dat(:, ChList(ch,1)) - dat(:,ChList(ch,2));
        d = eegfilt(d, lpfilt, 'lp');
        d = d(1:samp:end);
        min(imin) = mean(d.*d);
        imin = imin+1;
        if imin == 61
            imin = 1;
            hours(ihours, 1) = mean(min); 
            hours(ihours, 2) = std(min); 
            ihours
            ihours = ihours+1;
        end
        
    end
end

if ihours <= size(hours,1)
    hours(ihours) = mean(min(1:imin));
    hours(ihours) = std(min(1:imin));
end
results.energy = hours;
% save the results
if ~exist('idstr')
    idstr = '';
end
f = [eeghdr.DataPath GetName('name', eeghdr.FileName) 'CalcEnergy.mat'] ;
save(f, 'results');
fprintf('results saved to %s\n', f);

plot(1:size(hours,1), hours(:,1), 'b');
hold on
plot(1:size(hours,1), hours(:,1)+hours(:,2), ':r');
plot(1:size(hours,1), hours(:,1)-hours(:,2), ':r');
