function out = PlotDataByDay(printit)
% plot all the data, one figure (page) per day.
% each page starts at midnight and ends one tick before midnight
global myprint

if ~exist('printit', 'var')
    myprint = 'no';
else
    myprint=printit;
end
out = [];
if isempty(GetEEGData); return; end



markers = [];
rate = GetEEGData('getrate');

plotdata = zeros(17280, GetEEGData('getnumberofchannels'));
plotdata(:) = NaN;

[plotdata, startdate, curdate, last, fn, markers] = initnew(plotdata, markers);
figure
markers = myplot(plotdata, startdate, fn, markers);
drawnow


curdate(3) = curdate(3)+1;  % midnight the next day
curdate = datevec(datenum(curdate));  % just in case adding a day increments the month

done = 0;
while ~done

    % need to get this in small parts, find the max and min, and add them to the plot
    j = 1;
    plotdata(:) = NaN;
    for i = 0:23
        d = GetEEGData(curdate, [i*3600 3600]);     % get the number of seconds in one hour
        for k =  1:10*rate:length(d)-1*rate        % get 10 second hunks
            try
                plotdata(j,:) = max(d(k:k+10*rate-1,:));   % get the max or min of the data
                j = j+1;
                plotdata(j,:) = min(d(k:k+10*rate-1,:));
                j = j+1;
            catch
                break
            end
        end
        if size(d,1) < 3600*rate
            break
        end
    end
    if size(d,1) < 3600*rate
        % open next session
        secgap = GetEEGData('getNextSession');

        if isempty(secgap)
            done =1;
        else
            % depending on the size of the secgap and the end of the last file
            % we might need to draw current data and then open a new figure here
            if secgap >= startdate(4)*60*60 + startdate(6)*60 +startdate(6)
                % then the gapb is bigger than the time into the next day: ie,
                % we have to draw the data on a new sheet
                close(gcf);
                figure  % first draw the data left from the old file
                markers = myplot(plotdata, curdate, fn, markers);
                plotdata(:) = NaN;  % empty the buffer for the current data
            end
            [plotdata, startdate, curdate, last, fn, markers] = initnew(plotdata, markers);
        end
    end
    close(gcf);
    figure
    markers = myplot(plotdata, curdate, fn, markers);
    drawnow
    curdate(3) = curdate(3) + 1;
    curdate = datevec(datenum(curdate));  % fix month or larger boundries
end



function [plotdata, startdate, curdate, last, fn, markers] = initnew(plotdata, markers)
startdate =  GetEEGData('getstartdatevec');
last = GetEEGData('getlasttick');
fn = GetEEGData('getfilename');
fprintf('startdate: %s, stopdate: %s\n', datestr(startdate), datestr(GetEEGData('getenddatevec')));
curdate = startdate;
curdate(4:6) = 0;
offsecs = etime(startdate, curdate);
rate = GetEEGData('getrate');
m = GetEEGData('getMDevents');
for i = 1:size(m,2)
    markers(end+1).j = (((m(i).ticktime)/rate) + offsecs)/5;  %so we can plot as j
    markers(end).text = m(i).text;
end
start = 0;
% get the start offset
j = floor(offsecs/5);
while j < 17291
    d = GetEEGData('seconds', [start, 10]);
    try
        plotdata(j,:) = max(d);   % get the max or min of the data
        j = j+1;
        plotdata(j,:) = min(d);
        j = j+1;
        start = start+10;
    catch
        break
    end
end



function markers = myplot(plotdata, curdate, fn, markers)
global myprint
out = [];
sz = 17000;
nightc = 0.8;
for i = 1:size(plotdata,2)
    plotdata(:,i) = plotdata(:,i) - i*sz;
end
i = i+1;
y = [0, -sz*i, -sz*i, 0];
x = [0, 0, 7*60*12, 7*60*12];
h = fill(x,y, [nightc, nightc, nightc]);
set(h, 'edgecolor', [nightc,nightc,nightc]);
hold on
x = [19*60*12, 19*60*12, 24*60*12, 24*60*12];
h = fill(x,y, [nightc, nightc, nightc]);
set(h, 'edgecolor', [nightc,nightc,nightc]);
%hour = 1:size(plotdata,1);
%hour = hour/(6*60);
plot(plotdata, 'k')
ax(1) = 0;
ax(2) = 17280;
%ax(2) = 24;
ax(3) = -sz*i -sz/10;
ax(4) = sz;
axis(ax);
box off
axis off
set(gcf, 'color', 'w');
a = findstr(fn, '_');
title([fn(1:a(1)-1) '   ' , datestr(curdate, 2)], 'fontsize', 18);
drawnow;
for i = 1:size(markers,2)
    %    fprintf('%s %7d\n', markers(i).text, floor(markers(i).j));
    if markers(i).j > -1 && markers(i).j < 17281
        switch markers(i).text(1:2)
            case 'ss'
                text(markers(i).j, sz/2, markers(i).text,  'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                plot([markers(i).j,markers(i).j], [sz/2, sz/4], 'k');
                plot(markers(i).j, sz/4, 'vk');%, 'MarkerSize', 10);
            case 'st'
                text(markers(i).j, sz/2, markers(i).text,  'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                plot([markers(i).j,markers(i).j], [sz/2, sz/4], 'k');
                plot(markers(i).j, sz/4, 'vk');%, 'MarkerSize', 10);

            otherwise
        end
    end
    markers(i).j = markers(i).j - 17280;  % get ready for next plot by advancing markers
end

drawnow;
if strcmp(myprint, 'print')
    orient landscape
    print
end
