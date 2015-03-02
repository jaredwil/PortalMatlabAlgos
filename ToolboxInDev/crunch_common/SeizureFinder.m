function out = SeizureFinder(action, data);
global sf;
global eeghdr;

if ~exist('action')
    action = 'buttondown';
end

switch action

    case('file')
        dp = GetResultsDataPath;
        source = [dp '*Seizures.mat'];
        FileName = [];
        [FileName, DPath] = uigetfile(source, 'Choose a linelength results file to examine');
        if ~(FileName)
                out = [];		
                fprintf('No file selected, aborting\n');
                eeghdr = [];
                return
        end

        load([DPath FileName]);
        if isempty(results.eventticktimes)
            fprintf('No events detected in the line length analysis for %s\n', results.DataFile);
        else
            SeizureFinder('init', results.eventticktimes(:,1));
        end
        


    case 'init'
        sf = [];
        if isnumeric(data)
            % then passed a generic string of event times to view
            sf.EventList = data(:,1);
            sf.analysislabel = [];
            sf.EventData = data;
            sf.DataFile = [];
            szenable = 'on';
            bzenable = 'off';
            spenable = 'off';
                                sf.lpfilter = 70;
                    sf.hpfilter = [];
                   sf.ViewVersusRef = 1;
 
            okay = [];
            try
                okay = GetEEGData('getdata', [0 1]);
            catch
                fprintf('Cannot find data.  Please open the data file associated with times passed.\n');
                okay = GetEEGData;
            end
            if isempty(okay)
                fprintf('Exiting because cannot find data files.\n');
                return
            end
                    sf.ViewVersusRef = 1;
                    sf.refractorysec = 60;
                    sf.windsize = 15;
                    sf.clickwindsize = 5;
                    szenable = 'on';
                    bzenable = 'off';
                    spenable = 'off';
                    sf.lpfilter = 70;
                    sf.hpfilter = [];



        else

            sf = data;
            switch(sf.analysislabel)
                case 'Seizures'
                    sf.ViewVersusRef = 1;
                    sf.refractorysec = 60;
                    sf.windsize = 15;
                    sf.clickwindsize = 5;
                    szenable = 'on';
                    bzenable = 'off';
                    spenable = 'off';
                    sf.EventList = sf.eventticktimes(:,1);
                    sf.EventData = sf.eventticktimes;
                    sf.lpfilter = 70;
                    sf.hpfilter = [];

                case('6-12Hz_Buzz')
                    sf.ViewVersusRef = 0;
                    sf.refractorysec = 5;
                    sf.windsize = 1;
                    sf.clickwindsize = 1;
                    szenable = 'off';
                    bzenable = 'on';
                    spenable = 'off';
                    sf.EventList = sf.eventticktimes(:,1);
                    sf.EventData = sf.eventticktimes;

                case('SpikeRuns')
                    sf.ViewVersusRef = 1;
                    sf.refractorysec = 30;
                    sf.windsize = 15;
                    sf.clickwindsize = 0.5;
                    szenable = 'off';
                    bzenable = 'off';
                    spenable = 'on';
                    sf.EventList = PreProcessSpikeRuns(sf);
                    sf.EventData = [];
                    sf.lpfilter = [];
                    sf.hpfilter = 10;
            end

            % check for valid data
            okay = [];
            try
                if ~strcmp([eeghdr.DataPath GetName('name', eeghdr.FileName)], [sf.DataPath GetName('name', sf.DataFile)])
                    okay = GetEEGData('init',[sf.DataPath GetName('name', sf.DataFile) '.bni']);
                else
                    okay = 1;
                end
            catch
                okay = GetEEGData('init',[sf.DataPath GetName('name', sf.DataFile) '.bni']);
            end
            if isempty(okay)
                fprintf('Cannot find data.  Please open the data file associated with %s.\n', GetName('name', sf.DataFile));
                okay = GetEEGData;
            end
            if isempty(okay)
                fprintf('Exiting because cannot find data files for %s\n', GetName('name', sf.DataFile));
                return
            end
        end
        clear sf.EventData;
        
        sf.gdf = sf.EventList;
        sf.gdf(:,2) = sf.EventList;
        sf.gdf(:,1) = 0;
        
        sf.inrefraction = 0;
        sf.alignsec = -15;
        sf.totalsec = 45;
        sf.EventIndex = 0;
        sf.seizure = 0;
        sf.buzz = 0;
        sf.data = [];
        sf.yspacer = 4000;

        if isempty(sf.lpfilter)
            sf.drawpts = 1;  % no low pass filter so draw every point
        else
            sf.drawpts = floor(eeghdr.rate/(3*sf.lpfilter));
        end

        
        % check to see if video is available, if so, enable that button
        sf.viddisk = CheckForVideo('init', sf.DataFile);
        if ~isempty(sf.viddisk)
            sf.videnable ='on';
        else
            sf.videnable = 'off';
        end
        
        sf.Version = 'Seizure Finder v2.10';
        sf.Results = [];
        sf.fftplot = [];
        sf.redplot = [];

        y = 0.85;
        dy = -0.15;


        n = [sf.Version '   ' sf.DataFile];
        sf.Main = figure;
        set(sf.Main, 'UserData', [], ...
            'MenuBar','none', ...
            'tag','alMain',...
            'Name',n, ...
            'Numbertitle','off',...
            'Units', 'normalized', ...
            'Position', [.02 .55 .96 .35], ...
            'toolbar','figure');


        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder seizure;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','seizure', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','seizure', ...
            'Enable',szenable);
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder possSZ;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','? seizure ?', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','possSZ', ...
            'Enable',szenable);
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder buzz;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','buzz', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','buzz', ...
            'Enable',bzenable);
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder spikes', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','spikes', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','spikes', ...
            'Enable',spenable);
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder other', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','other', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','other', ...
            'Enable','on');
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder back;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .07 .10], ...
            'String','<- back', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','back', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder noSz;', ...
            'ListboxTop',0, ...
            'Position',[.88 y .07 .10], ...
            'String','skip ->', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','noSz', ...
            'Enable','on');
        y = y+dy;


        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder earlier;', ...
            'ListboxTop',0, ...
            'Position',[0.1, 0.05, 0.05 .07], ...
            'String','<', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','earlier', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder later;', ...
            'ListboxTop',0, ...
            'Position',[0.16, 0.05, 0.05 .07], ...
            'String','>', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','later', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder more;', ...
            'ListboxTop',0, ...
            'Position',[0.24, 0.05, 0.05 .07], ...
            'String','<<    >>', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','more', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder less;', ...
            'ListboxTop',0, ...
            'Position',[0.30, 0.05, 0.05 .07], ...
            'String','>>    <<', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','less', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder showvideo;', ...
            'ListboxTop',0, ...
            'Position',[0.58, 0.05, 0.09 .07], ...
            'String','show video', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','showvideo', ...
            'Enable',sf.videnable);

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder save;', ...
            'ListboxTop',0, ...
            'Position',[0.68, 0.05, 0.07 .07], ...
            'String','save', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','save', ...
            'Enable','on');

        if isempty(sf.hpfilter)
            s = 'HP: none';
        else
            s = ['HP: ' num2str(sf.hpfilter)];
        end
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder sethp;', ...
            'ListboxTop',0, ...
            'Position',[0.38, 0.05, 0.07 .07], ...
            'String',s, ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','sethp', ...
            'Enable','on');

        if isempty(sf.lpfilter)
            s = 'LP: none';
        else
            s = ['LP: ' num2str(sf.lpfilter)];
        end
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder setlp;', ...
            'ListboxTop',0, ...
            'Position',[0.46, 0.05, 0.07 .07], ...
            'String',s, ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','setlp', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder increaseY;', ...
            'ListboxTop',0, ...
            'Position',[0.01, 0.75, 0.02 .15], ...
            'String','^', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','increaseY', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SeizureFinder decreaseY;', ...
            'ListboxTop',0, ...
            'Position',[0.01, 0.58, 0.02 .15], ...
            'String','v', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','decreaseY', ...
            'Enable','on');


        sf.plot = subplot('position', [0.1, 0.30, 0.65, 0.60]);
        set(gca, 'ButtonDownFcn', 'SeizureFinder');

        SeizureFinder('getNext');


    case 'sethp'
        def = {num2str(sf.hpfilter)};
        hp = inputdlg('Enter a value for the hp filter, or empty for none', 'Set high pass filter',1, def);

        sf.hpfilter = str2num(hp{1});
        if isempty(sf.hpfilter)
            s = 'HP: none';
        else
            s = ['HP: ' num2str(sf.hpfilter)];
        end
        cf = findobj('tag', 'sethp');
        set(cf, 'string', s);
        SeizureFinder('draw');


    case 'setlp'
        def = {num2str(sf.lpfilter)};
        hp = inputdlg('Enter a value for the lp filter, or empty for none', 'Set low pass filter',1, def);

        sf.lpfilter = str2num(hp{1});
        if isempty(sf.lpfilter)
            sf.drawpts = 1;  % no low pass filter so draw every point
        else
            sf.drawpts = floor(eeghdr.rate/(3*sf.lpfilter));
        end

        if isempty(sf.lpfilter)
            s = 'LP: none';
        else
            s = ['LP: ' num2str(sf.lpfilter)];
        end
        cf = findobj('tag', 'setlp');
        set(cf, 'string', s);
        SeizureFinder('draw');



    case 'earlier'
        sf.alignsec = sf.alignsec - 15;
        sf.totalsec = sf.totalsec - 15;
        SeizureFinder('draw');

    case 'later'
        sf.alignsec = sf.alignsec + 15;
        sf.totalsec = sf.totalsec + 15;
        SeizureFinder('draw');

    case 'more'
        sf.alignsec = sf.alignsec - 15;
        sf.totalsec = sf.totalsec + 30;
        SeizureFinder('draw');

    case 'less'
        sf.alignsec = sf.alignsec + 15;
        sf.totalsec = sf.totalsec - 30;
        if sf.totalsec < 10
            sf.alignsec = sf.alignsec - 15;
            sf.totalsec = sf.totalsec + 30;
        else
            SeizureFinder('draw');
        end

    case 'increaseY'
        sf.yspacer = 2*sf.yspacer;
        SeizureFinder('draw');

    case 'decreaseY'
        sf.yspacer = sf.yspacer/2;
        SeizureFinder('draw');

    case 'buttondown'
        % if no data is displayed then return
        if isempty(sf.data)
            return
        end


        % if we clicked a spot
        if ~exist('data', 'var')
            wsize = sf.clickwindsize;
            a = get(gca, 'CurrentPoint');
            x = a(1,1);
            y = a(1,2);
        else  % display the time passed
            wsize = sf.windsize;
            y = 0;
            x = wsize/2;
        end


        % remove old selected region
        try delete(sf.redplot); catch end

        % move above and below clicks to nearest line
        dc = -round(y/sf.yspacer) +1;
        if dc > size(sf.data,2)-1, dc = size(sf.data,2)-1; end
       if dc < 1, dc = 1; end
 

        start = round((x-sf.alignsec-wsize/2)*eeghdr.rate);
        stop  = round((x-sf.alignsec+wsize/2)*eeghdr.rate);

        if start < 1
            start = 1;
            stop = round(5*eeghdr.rate);
            x = sf.alignsec + wsize/2;
        end
        if stop > length(sf.data)
            start = length(sf.data) - round(5*eeghdr.rate);
            stop = length(sf.data);
            x = sf.totalsec + sf.alignsec - wsize/2;
        end

        fdata = sf.data(start:stop, dc);
        d = fdata;
        if ~isempty(sf.lpfilter)
            d = eegfilt(d, sf.lpfilter, 'lp');
        end
        if ~isempty(sf.hpfilter)
            d = eegfilt(d, sf.hpfilter, 'hp');
        end
        d = d -((dc-1) * sf.yspacer);

        hold on
        xa = 0:length(d)-1;
        xa = xa/eeghdr.rate + x - wsize/2;
        sf.redplot = plot(xa, d, 'r', 'hittest', 'off');
        drawnow
        hold off

        %try close(sf.fftplot); catch end
        [f, x] = pwelch(fdata,[],[],round(eeghdr.rate),round(eeghdr.rate));
        try
            figure(sf.fftplot);
        catch
            sf.fftplot = figure;
        end
        set(sf.fftplot, 'UserData', [], ...
            'MenuBar','none', ...
            'tag','alfft',...
            'Name','fft', ...
            'Numbertitle','off',...
            'Units', 'normalized', ...
            'Position', [.02 .25 .96 .25], ...
            'toolbar','none');

        x = x(find(x < 100));
        f(1:3) = 0;
        bar(x,f(1:length(x)));
        ax = axis;
        ax(1) = 0;
        ax(2) = 100;
        axis(ax);


    case 'showvideo'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        CheckForVideo('play', st);
        
        
    case 'seizure'
        st = datestr(GetEEGData('tick2datevec', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 990;
        fprintf('seizure at %s (%s)\n', st, eeghdr.fname);
        sf.inrefraction =1;
        SeizureFinder('getNext');

    case 'possSZ'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 980;
        fprintf('possible seizure at %s (%s)\n', st, eeghdr.fname);
        SeizureFinder('getNext');

    case 'buzz'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 970;
        fprintf('buzz at %s (%s)\n', st, eeghdr.fname);
        sf.inrefraction =1;
        SeizureFinder('getNext');

    case 'spikes'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 960;
        fprintf('spike string at %s (%s)\n', st, eeghdr.fname);
        sf.inrefraction =1;
        SeizureFinder('getNext');

    case 'other'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 950;
        fprintf('other event detection at %s (%s)\n', st, eeghdr.fname);
        SeizureFinder('getNext');

    case 'noSz'
        SeizureFinder('getNext');

    case 'back'
        sf.EventIndex = sf.EventIndex-2;
        if sf.EventIndex < 0
            sf.EventIndex = 0;
        end
        SeizureFinder('getNext');

    case 'getNext'
        if sf.inrefraction
            tm = sf.EventList(sf.EventIndex);
        end
        while sf.inrefraction

            sf.EventIndex = sf.EventIndex+1;
            if sf.EventIndex > length(sf.EventList);
                sf.EventIndex = sf.EventIndex-2;
                fprintf('done!\n');
                sf.data = [];
                dp = GetResultsDataPath;
                sn =[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_examined.mat'];
                save(sn, 'sf');
                fprintf('results saved to %s\n', sn);
                return
            end
            if sf.EventList(sf.EventIndex) > tm + sf.refractorysec*eeghdr.rate
                sf.inrefraction =0;
                sf.EventIndex = sf.EventIndex -1;
            end
        end
        if sf.EventIndex > length(sf.EventList)
            sf.EventIndex = sf.EventIndex-2;
            fprintf('done!\n');
            sf.data = [];
            dp = GetResultsDataPath;
            sn=[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_examined.mat'];
            save(sn, 'sf');
            fprintf('results saved to %s\n', sn);
            return
        end
        sf.EventIndex = sf.EventIndex+1;
        SeizureFinder('draw');

    case('save')
        t = sf.data;
        sf.data = [];
        dp = GetResultsDataPath;
        sn=[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_examined.mat'];
        save(sn, 'sf');
        fprintf('results saved to %s\n', sn);
        sf.data = t;


    case('draw')
        sf.data = GetEEGData('getdata',[sf.EventList(sf.EventIndex) + sf.alignsec*eeghdr.rate, sf.totalsec*eeghdr.rate]);

        
        if ~sf.ViewVersusRef
            for i = 1:size(sf.data, 2)-1
                sf.data(:,i) = sf.data(:,i) - sf.data(:,i+1);
            end
            sf.data(:,end) = [];
        end

        for i = 1:size(sf.data, 2)
            sf.data(:,i) = detrend(sf.data(:,i), 'constant');
            d(:,i) = sf.data(:,i);
            if ~isempty(sf.lpfilter)
                d(:, i) = eegfilt(d(:,i), sf.lpfilter, 'lp');
            end
            if ~isempty(sf.hpfilter)
                d(:, i) = eegfilt(d(:,i), sf.hpfilter, 'hp');
            end
            d(:,i) = d(:,i)  - ((i-1) * sf.yspacer);
        end

        cf = findobj('tag', 'forward');
        set(cf, 'enable', 'on');
        cf = findobj('tag', 'back');
        set(cf, 'enable', 'on');



        dvec = GetEEGData('tick2datevec', sf.EventList(sf.EventIndex));
        x = 1:length(d);
        x = x/eeghdr.rate + sf.alignsec;
        plot(x(1:sf.drawpts:end), d(1:sf.drawpts:end,:), 'b', 'hittest', 'off');
        set(gca, 'ButtonDownFcn', 'SeizureFinder');
        title([datestr(dvec) '     event ' num2str(sf.EventIndex) '/' num2str(size(sf.EventList,1))]);
        xlabel('seconds');
        ylabel('uV');
        axis tight
        ax = axis;
        ax(3) = -size(sf.data,2)*sf.yspacer -sf.yspacer;
        ax(4) = 2*sf.yspacer;
        axis(ax);

        SeizureFinder('buttondown', sf.analysislabel);

end