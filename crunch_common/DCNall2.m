function decay = DCNall2(startses)
%function QSA
%  open a rat and analyze for seizure like activity using function decay on
%  the channel passed

labels(1).txt = 'L DG';
labels(2).txt = 'L CA1';
labels(3).txt = 'R DG';
labels(4).txt = 'R CA1';
labels(5).txt = 'L Ctx';
labels(6).txt = 'L Screw';


if ~exist('startses', 'var') || isempty(startses)
    startses = 0;
end
decay = [];

a = GetEEGData;                         % open a eeg file
if isempty(a)                           % if cancled
    return                              % then return
end
sechunksz = 10;
numchans = GetEEGData('getnumberofchannels');
if numchans > 6; numchans = 6; GetEEGData('limitchannels', 1:6); end
if numchans == 5; numchans = 4; GetEEGData('limitchannels', 1:4); end
GetEEGData('resetindex',startses);
decay = zeros((60/sechunksz)*60*24*31,1);     % one month of data for all the channels
x = zeros((60/sechunksz)*60*24*31,1);
decay_inx = 1;                          % where to put the next value

rate = GetEEGData('getrate');           % get the rate
GetEEGData('sethunksize', 10);          % set to 10 second hunks
events = GetEEGData('getAllMDevents');

[data] = GetEEGData('getnext');           % get the first hunk
dtime = GetEEGData('getvideotime');      % time of the last data point
currentmonth = dtime(2);
currentday = dtime(3);
decay_inx = (((dtime(3)-1)*24 + dtime(4))*60 + dtime(5))*(60/sechunksz) + round(dtime(6)/sechunksz)+1;
startlength = length(data);
figure
f = GetEEGData('getfilename');
t = [f(1:4) ' feat DCN ' datestr(dtime, 'mmm-yyyy')];
%subplot(numchans,1,1)
%title(t);
%xlabel('days');
while length(data) == startlength       % while data left
    if dtime(3) ~= currentday

        x = 1:(decay_inx-1);             % if the day has changed plot it
        x = x/((60/sechunksz)*60*24);
%        for plt = 1:numchans
%            subplot(numchans,1, plt)
            plot(x,decay(1:decay_inx-1, 1))   % plot all 5 second bins
%        end
        drawnow
        currentday = dtime(3);
        if dtime(2) ~= currentmonth
            % if the month has changed, make a new figure: one figure per month
%            subplot(numchans,1,1)
            title(t);
%            ylabel(labels(1).txt)
for i = 1:length(events)
hold on
    if events(i).datevec(2) == currentmonth && strcmp(events(i).text, '990')
        %then plot it
        xe = events(i).datevec(3) + (events(i).datevec(4) + events(i).datevec(5)/60)/24;
        plot([xe xe], [0 500], 'r');
    end
end
%            linkaxes;
            axis([0 x(end) 0 200]);
%            for j = 2:numchans
%                subplot(numchans,1,j)
 %               ylabel(labels(j).txt)
 %           end
            xlabel('days');
            drawnow
            saveas(gcf, [t '.fig'], 'fig');
            f = GetEEGData('getfilename');
            t = [f(1:4) ' feat DCN ' datestr(dtime, 'mmm-yyyy')];
            decay(:) = 0;
            decay_inx = floor(((dtime(3)-1)*24 + dtime(4))*60 + dtime(5))*(60/sechunksz) + round(dtime(6)/sechunksz)+1;
            currentmonth = dtime(2);
        end

    end
%    for chan = 1:numchans
        decay(decay_inx,1) = feat_DCN(data,rate);
%    end
    decay_inx = decay_inx+1;
    [data, evs, gap] = GetEEGData('getnext');    % gap is gap between sessions, if moving between sessions, and it there is a gap
    decay_inx = decay_inx + round(gap/sechunksz);
    dtime = GetEEGData('getvideotime');
end


x = 1:(decay_inx-1);             % if the day has changed plot it
x = x/((60/sechunksz)*60*24);
%for plt = 1:numchans
%    subplot(numchans,1, plt)
    plot(x,decay(1:decay_inx-1, 1))   % plot all 10 second bins
%end
drawnow

%subplot(numchans,1,1)
title(t);
%ylabel(labels(1).txt)
%linkaxes;
for i = 1:length(events)
hold on
    if events(i).datevec(2) == currentmonth && strcmp(events(i).text, '990')
        %then plot it
        xe = events(i).datevec(3) + (events(i).datevec(4) + events(i).datevec(5)/60)/24;
        plot([xe xe], [0 500], 'r');
    end
end

axis([0 x(end) 0 200]);
%for j = 2:numchans
%    subplot(numchans,1,j)
%    ylabel(labels(j).txt)
%end
xlabel('days');
drawnow
saveas(gcf, [t '.fig'], 'fig');
t = [GetEEGData('getfilename') ' feat DCN ' datestr(dtime, 'mmm-yyyy')];
decay_inx = 1;

