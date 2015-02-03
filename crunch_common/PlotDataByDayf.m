function out = PlotDataByDayf(action, data)
% plot all the data, one figure (page) per day.
% each page starts at midnight and ends one tick before midnight
global pd

out = 1;
switch action

    case 'init'
        if isempty(GetEEGData); return; end
        pd = [];
        if exist('data', 'var')
            pd.myprint = data;  % needs to be 'print' to print
        else
            pd.myprint = 'no';
        end
        pd.done = 0;
        pd.state = 0;
        pd.markers = [];
        pd.userdata = [];
        pd.linefigh = [];
        pd.rate = GetEEGData('getrate');
        pd.xsize = 17280;
        pd.yspacer = 17000;
        pd.plotdata = zeros(pd.xsize, GetEEGData('getnumberofchannels'));
        pd.plotdata(:) = NaN;
        initnew;
        ax =get(0,'screensize');
        pd.h = figure('position', [floor(0.02*ax(3)), floor(0.5*ax(4)), floor(0.96*ax(3)), floor(0.45*ax(4))]);

        uicontrol('Parent',pd.h, ...
            'Units','normalized', ...
            'Callback', 'PlotDataByDayf test;' , ...
            'ListboxTop',0, ...
            'Position',[0.020 0.74 0.10 0.05], ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'on', ...
            'String', 'test', ...
            'Tag','pd test', ...
            'Enable','on');
        uicontrol('Parent',pd.h, ...
            'Units','normalized', ...
            'Callback', 'PlotDataByDayf getnextday;' , ...
            'ListboxTop',0, ...
            'Position',[0.020 .67 0.10 0.05], ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'on', ...
            'String', 'next', ...
            'Tag','pd nextday', ...
            'Enable','on');



        nightc = 0.8;
        i = size(pd.plotdata,2)+1;
        y = [0, -pd.yspacer*i, -pd.yspacer*i, 0];
        x = [0, 0, 7*60*12, 7*60*12];
        h = fill(x,y, [nightc, nightc, nightc]);
        set(h, 'edgecolor', [nightc,nightc,nightc]);
        hold on
        x = [19*60*12, 19*60*12, 24*60*12, 24*60*12];
        h = fill(x,y, [nightc, nightc, nightc]);
        set(h, 'edgecolor', [nightc,nightc,nightc]);
        ax(1) = 0;
        ax(2) = pd.xsize;
        ax(3) = -pd.yspacer*i -pd.yspacer/10;
        ax(4) = pd.yspacer;
        axis(ax);
        box off
        axis off
        set(gcf, 'color', 'w');

        pd.hplot = plot(pd.plotdata, 'k', 'ButtonDownFcn', 'PlotDataByDayf lineclicked;');
        hold on
        myplot;
        drawnow
        pd.curdate(3) = pd.curdate(3)+1;  % midnight the next day
        pd.curdate = datevec(datenum(pd.curdate));  % just in case adding a day increments the month

        % ready to go and first day done.


    case 'lineclicked'
        g = get(gcbo);
        chan = g.UserData.chan;
        cp = get(gca, 'CurrentPoint');
        
        for i = 1:length(g.UserData.ud)  % find the dataset that was clicked on
            if cp(1)-g.UserData.ud(i).j+1 < 1
                i = i-1; %#ok<FXSET>
                break
            end
        end
        if ~strcmp(g.UserData.ud(i).fn, GetEEGData('getfilename'))  % if from a different file, then open the file
            savefn = GetEEGData('getfilename');
            GetEEGData('init', [GetEEGData('getpathname') g.UserData.ud(i).fn]);
        else
            savefn = [];
        end

        sec = g.UserData.ud(i).dayoff+5*(cp(1)-g.UserData.ud(i).j+1);
        d = GetEEGData('seconds', [sec-300, 600]);
%        d = eegfilt(d, 50, 'hp');
%        d = eegfilt(d, 50, 'lp');
        

        try
            figure(pd.linefigh);
            set(pd.linefiglineh, 'ydata', d(:,chan)/1000);
        catch
            ax =get(0,'screensize');
            pd.linefigh = figure('position', [floor(0.05*ax(3)), floor(0.1*ax(4)), floor(0.9*ax(3)), floor(0.4*ax(4))]);
            zoom on
            x = 1:length(d);
            x = x/pd.rate;
            x = x-300;
            pd.linefiglineh = plot(x,d(:,chan)/1000);
            xlabel('seconds');
            ylabel('mV');
        end
        a = findstr(pd.fn, '_');
        title([pd.fn(1:a(1)-1) '   chan ' num2str(chan)  '   ' datestr(GetEEGData('tick2datevec', pd.rate*sec))]);
        if ~isempty(savefn)
            GetEEGData('init', [GetEEGData('getpathname') savefn]);
        end



    case 'getnextday'
        set(gcbo, 'enable', 'off');
        drawnow
        if pd.done
            fprintf('All Done!\n');
            return
        end
        if pd.state
            finishoffday;
            pd.state = 0;
        end

        % need to get this in small parts, find the max and min, and add them to the plot
        j = 1;
        pd.daysecoffset = etime(pd.curdate, pd.startdate);
        pd.userdata(end+1).fn = pd.fn;
        pd.userdata(end).j = j;
        pd.userdata(end).dayoff = pd.daysecoffset;
        pd.plotdata(:) = NaN;
        for i = 0:23
            d = GetEEGData(pd.curdate, [i*3600 3600]);     % get the number of seconds in one hour
            for k =  1:10*pd.rate:length(d)-1*pd.rate        % get 10 second hunks
                try
                    pd.plotdata(j,:) = max(d(k:k+10*pd.rate-1,:));   % get the max or min of the data
                    j = j+1;
                    pd.plotdata(j,:) = min(d(k:k+10*pd.rate-1,:));
                    j = j+1;
                catch
                    break
                end
            end
            if size(d,1) < 3600*pd.rate
                break
            end
        end


        if size(d,1) < 3600*pd.rate
            % open next session
            secgap = GetEEGData('getNextSession');

            if isempty(secgap)
                pd.done =1;
                fprintf('All Done!\n');
            else
                % depending on the size of the secgap and the end of the last file
                % we might need to draw current data and then open a new figure here
                if secgap >= pd.startdate(4)*60*60 + pd.startdate(6)*60 +pd.startdate(6)
                    % then the gapb is bigger than the time into the next day: ie,
                    % we have to draw the data on a new sheet
                    myplot;
                    pd.plotdata(:) = NaN;  % empty the buffer for the current data
                    initnew;
                    pd.state = '1';
                    set(gcbo, 'enable', 'on');
                    drawnow
                    return
                end
                initnew;
            end
        end
        finishoffday;
        set(gcbo, 'enable', 'on');
        drawnow


end % switch




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subfunction out = finishoffday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = finishoffday
global pd
out = 1;
myplot;
drawnow
pd.curdate(3) = pd.curdate(3) + 1;
pd.curdate = datevec(datenum(pd.curdate));  % fix month or larger boundries

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% end subfunction out = finishoffday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subfunction out = initnew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function out =initnew
global pd
out = 1;
pd.daysecoffset = 0;
pd.startdate =  GetEEGData('getstartdatevec');
pd.last = GetEEGData('getlasttick');
pd.fn = GetEEGData('getfilename');
fprintf('startdate: %s, stopdate: %s\n', datestr(pd.startdate), datestr(GetEEGData('getenddatevec')));
pd.curdate = pd.startdate;
pd.curdate(4:6) = 0;
offsecs = etime(pd.startdate, pd.curdate);
pd.rate = GetEEGData('getrate');
m = GetEEGData('getMDevents');
for i = 1:size(m,2)
    pd.markers(end+1).j = (((m(i).ticktime)/pd.rate) + offsecs)/5;  %so we can plot as j
    pd.markers(end).text = m(i).text;
end
start = 0;
% get the start offset
j = floor(offsecs/5);
pd.userdata(end+1).fn = pd.fn;
pd.userdata(end).j = j;
pd.userdata(end).dayoff = pd.daysecoffset;
while j < pd.xsize+1
    d = GetEEGData('seconds', [start, 10]);
    try
        pd.plotdata(j,:) = max(d);   % get the max or min of the data
        j = j+1;
        pd.plotdata(j,:) = min(d);
        j = j+1;
        start = start+10;
    catch
        break
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% end subfunction out = intinew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% subfunction out = myplot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function out = myplot
global pd

out = [];
try %#ok<TRYNC>
    delete(pd.tmark)
end
pd.tmark = [];
for i = 1:size(pd.plotdata,2)
    pd.plotdata(:,i) = pd.plotdata(:,i) - i*pd.yspacer;
    info.ud = pd.userdata;
    info.chan = i;
    set(pd.hplot(i), 'ydata', pd.plotdata(:,i), 'UserData', info);
end
a = findstr(pd.fn, '_');
title([pd.fn(1:a(1)-1) '   ' , datestr(pd.curdate, 2)], 'fontsize', 18);
drawnow;
for i = 1:size(pd.markers,2)
    %    fprintf('%s %7d\n', pd.markers(i).text, floor(pd.markers(i).j));
    if pd.markers(i).j > -1 && pd.markers(i).j < 17281
        switch pd.markers(i).text(1:2)
            case 'ss'
                pd.tmark(end+1) = text(pd.markers(i).j, pd.yspacer/2, pd.markers(i).text,  'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                pd.tmark(end+1) = plot([pd.markers(i).j,pd.markers(i).j], [pd.yspacer/2, pd.yspacer/4], 'k');
                pd.tmark(end+1) = plot(pd.markers(i).j, pd.yspacer/4, 'vk');%, 'pd.markersize', 10);
            case 'st'
                pd.tmark(end+1) = text(pd.markers(i).j, pd.yspacer/2, pd.markers(i).text,  'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
                pd.tmark(end+1) = plot([pd.markers(i).j,pd.markers(i).j], [pd.yspacer/2, pd.yspacer/4], 'k');
                pd.tmark(end+1) = plot(pd.markers(i).j, pd.yspacer/4, 'vk');%, 'MarkerSize', 10);

            otherwise
        end
    end
    pd.markers(i).j = pd.markers(i).j - pd.xsize;  % get ready for next plot by advancing markers
end

pd.userdata = [];
drawnow;
if strcmp(pd.myprint, 'print')
    orient landscape
    print
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% end subfunction out = myplot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

