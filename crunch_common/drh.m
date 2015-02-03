function result = drh(action, data)
% makes rasters and histograms from gdf data files

global jps;						% common vars for jeff's program suite
% see JPSVars.m
global rh;
%	rh.AlignIDTimes;		% rows = trials, cols = ids; working value
% rh.SpikeIDTimes; 		% spike times of the current ID; working value
%	rh.AlignID;					% current align ID; working value
% rh.SpikeID;					% current spike ID; working value
% rh.RasterVector;		% the line that is displayed as the current raster
%	rh.DisplayTrials;		% the (max) number of trials to show on the display
% rh.TrialDisplay;		% either 'all' or 'same' - same plots the same no in each raster
%	rh.DotSize;					% marker size of the dots on the raster line
%	rh.DotColor;				% color of the dots on the raster line
%	rh.Barcolor;
%	rh.Smoothing;
% rh.ACorNorm;				% auto correlation normalization
% rh.CalcRateChange		% [boolean, baselineBins]


if ~exist('action', 'var')
    if JPSVars('getNewGDFFile')
        drh('init');
        drh('makeMainWind');
        drh('makeStartStopBWWind');
        %    drh('display','b')
    end
    return
end


switch(action)

    case('jps')
        drh('init');
        drh('makeMainWind');

    case('current');
        drh('init');
        drh('makeMainWind');
        %    drh('display','b')


    case('init');
        rh.ACorNorm = 'unbiased';
        rh.TrialDisplay = 'same';
        rh.DotColor = 'k';
        rh.DotSize = 1;
        rh.BarColor = 'w';
        rh.BarEdgeColor = 'k';
        rh.Smoothing = 0;
        rh.RasterVectorValid = 0;
        rh.CalcRateChange = [0 10];
        rh.FindFirstDiff = 0;
        rh.bsd = [];  % bin standard deviations -- for calculating First differences
        rh.obsd = [];  % bin standard deviations -- for calculating First differences
        rh.DisplayTrials = 1000000;
        rh.BWList = [1  2  3  5  10  30  60 600 3600];
        rh.MarkerColor = ['r','b','c','g','m','y'];
        rh.MarkerSize = 6;
        rh.MarkerIDs = [];
        rh.MarkerVectors = [];
        rh.SortOrder = [];
        rh.SortID = [];
        rh.CommonScale = 1;
        rh.Xunitdivisor = 1; % can be 1 for sec, 60 for min, or 3600 for hours

    case('getAlignIDTimes')
        % data is the value of the current spikeID (just one value)
        if exist('data', 'var')
            rh.AlignIDTimes = jps.gdf(find(jps.gdf(:,1) == data),2);	% just the times;
            rh.AlignID = data;
        end

    case('getSpikeIDTimes');
        % data is the value of the current spikeID (just one value)
        if exist('data', 'var')
            rh.SpikeID = data;
            rh.SpikeIDTimes = jps.gdf(find(jps.gdf(:,1) == data),2);	% just the times;
        end


    case('calcSortOrder');
        % get time and trial number information
        startTick = jps.StartStop(1)*jps.TicksPersec;
        stopTick  = jps.StartStop(2)*jps.TicksPersec;
        if rh.DisplayTrials
            % find number of trials to display
            if rh.DisplayTrials > length(rh.AlignIDTimes)
                NoDispTrials = length(rh.AlignIDTimes);
            else
                NoDispTrials = rh.DisplayTrials;
            end
        else
            NoDispTrials = length(rh.AlignIDTimes);
        end


        if isempty(rh.SortID)
            rh.SortOrder = 1:NoDispTrials;
            return
        end

        Raster = [];
        MarkerTimes = jps.gdf(find(jps.gdf(:,1) == rh.SortID),2);	% just the times;
        for t = 1:NoDispTrials			% have to do a for loop
            start = rh.AlignIDTimes(t) + startTick -1;  % for this trial
            stop =  rh.AlignIDTimes(t) + stopTick;
            tRaster = MarkerTimes(find( (MarkerTimes > start) & (MarkerTimes < stop) ) ) - rh.AlignIDTimes(t);
            if ~isempty(tRaster)
                tRaster(:,2) = t;
                Raster =  [Raster; tRaster];   	% build Raster lines
            end
        end

        if size(Raster,1)
            Raster(:,1) = Raster(:,1)/jps.TicksPersec;
            % first trial is on bottom when plotted
        end

        srt = [];
        plt = Raster;
        if ~isempty(plt)
            for i = 1:NoDispTrials
                tmp = plt(find(plt(:,2) == i),1);    % get events for trial number in plotting range
                if isempty(tmp)
                    tmp = jps.StartStop(2);  % if no code put last
                end
                srt = [srt; [min(tmp), i]];
            end
            srt = sortrows(srt,1);  % sort by time diff of closest marker
            srt(:,1) = (1:size(srt,1))';  %replace times with order number
            srt = sortrows(srt,2);  % sort by trial number;
            rh.SortOrder = srt(:,1);  % this is the order we want to display the trials in
        end


    case('getRasterVector');
        Raster = [];
        startTick = jps.StartStop(1)*jps.TicksPersec;
        stopTick  = jps.StartStop(2)*jps.TicksPersec;
        if rh.DisplayTrials
            if rh.DisplayTrials > length(rh.AlignIDTimes)
                NoDispTrials = length(rh.AlignIDTimes);
            else
                NoDispTrials = rh.DisplayTrials;
            end
        else
            NoDispTrials = length(rh.AlignIDTimes);
        end

        for t = 1:NoDispTrials			% have to do a for loop
            start = rh.AlignIDTimes(t) + startTick -1;  % for this trial
            stop =  rh.AlignIDTimes(t) + stopTick;
            tRaster = rh.SpikeIDTimes(find( (rh.SpikeIDTimes > start) & (rh.SpikeIDTimes < stop) ) ) - rh.AlignIDTimes(t);
            if ~isempty(tRaster)
                tRaster(:,2) = rh.SortOrder(t);
                Raster =  [Raster; tRaster];   	% build Raster lines
            end
        end

        if size(Raster,1)
            Raster(:,1) = Raster(:,1)/jps.TicksPersec;
            % first trial is on bottom when plotted
            rh.RasterVector = Raster;
            rh.RasterVectorValid = 1;
        else
            rh.RasterVector = [];
            rh.RasterVectorValid = 0;
        end


    case('getMarkerVectors');
        if isempty(rh.MarkerIDs)
            rh.MarkerVectors = [];
            return
        end

        % get time and trial number information
        startTick = jps.StartStop(1)*jps.TicksPersec;
        stopTick  = jps.StartStop(2)*jps.TicksPersec;
        if rh.DisplayTrials

            % find number of trials to display
            if rh.DisplayTrials > length(rh.AlignIDTimes)
                NoDispTrials = length(rh.AlignIDTimes);
            else
                NoDispTrials = rh.DisplayTrials;
            end
        else
            NoDispTrials = length(rh.AlignIDTimes);
        end


        % for each MarkerID to plot
        for i = 1:length(rh.MarkerIDs)
            Raster = [];
            MarkerTimes = jps.gdf(find(jps.gdf(:,1) == rh.MarkerIDs(i)),2);	% just the times;
            for t = 1:NoDispTrials			% have to do a for loop
                start = rh.AlignIDTimes(t) + startTick -1;  % for this trial
                stop =  rh.AlignIDTimes(t) + stopTick;
                tRaster = MarkerTimes(find( (MarkerTimes > start) & (MarkerTimes < stop) ) ) - rh.AlignIDTimes(t);
                if ~isempty(tRaster)
                    tRaster(:,2) = rh.SortOrder(t);
                    Raster =  [Raster; tRaster];   	% build Raster lines
                end
            end

            if size(Raster,1)
                Raster(:,1) = Raster(:,1)/jps.TicksPersec;
                % first trial is on bottom when plotted
                rh.MarkerVectors{i} = Raster;
            else
                rh.MarkerVectors{i} = [];
            end
        end


    case('plotRaster')
        f = jps.FileName;
        s = int2str(rh.SpikeID);
        a = int2str(rh.AlignID);
        t = [int2str(jps.StartStop(1)) ':' int2str(jps.StartStop(2))];

        if rh.RasterVectorValid
            h = plot(rh.RasterVector(:,1),rh.RasterVector(:,2), ...
                '.k','color',rh.DotColor,'MarkerSize',rh.DotSize, ...
                'UserData', 'raster', ...
                'tag', [f '  SpikeID ' s '  AlignID ' a '  time ' t]);

            if strcmp(get(gcf', 'tag'), 'drhMain')
                set(h,'UIContextMenu', rh.RasterMenu);
            end
        end

        if ~isempty(rh.MarkerVectors)
            hold on
            for i = 1:size(rh.MarkerIDs)
                plt = rh.MarkerVectors{i};
                if ~isempty(plt)
                    h = plot(plt(:,1),plt(:,2),'.k','color',rh.MarkerColor(i),'MarkerSize',rh.MarkerSize);
                end
            end
        end
        hold off
        axis manual
        axis([jps.StartStop(1) jps.StartStop(2) 0 length(rh.SortOrder)+1]);
        axis off


    case('plotHistogram')
        bintimes = jps.StartStop(1):jps.secBinWidth:jps.StartStop(2);
        binheights = histc(rh.RasterVector(:,1),bintimes);
        if rh.FindFirstDiff
            % here we want to keep track of each bin for each trial, then calc sd
            % already have mean in the term bin heights
            rh.bsd = zeros(length(binheights),length(rh.SortOrder));
            for i = 1:length(rh.SortOrder)          % each trial
                r = find(rh.RasterVector(:,2) == i);  % all spikes for this trial
                rh.bsd(:,i) = histc(rh.RasterVector(r,1),bintimes); %binned
            end
            rh.bsd(end,:) = [];
        end
        bintimes(end) = [];
        bintimes = bintimes+jps.secBinWidth;
        binheights(end) = [];
        binheights = 3600*binheights/(length(rh.SortOrder)*jps.secBinWidth);  % spikes per hour
        bh = drh('smooth',binheights);

        % figure out which units to use
        xt = 'sec';
        if max(abs(bintimes)) > 100
            bintimes =  bintimes/60;
            xt = 'min';
            if max(abs(bintimes)) > 100
                bintimes =  bintimes/60;
                xt = 'hours';
            end
        end
        bintimes = bintimes/rh.Xunitdivisor;
        h = bar(bintimes,bh,1,rh.BarColor);
        set(h,'UserData','histo');
        if strcmp(get(gcf', 'tag'), 'drhMain')

            set(h,'UIContextMenu', rh.HistoMenu);
        end

        set(h,'EdgeColor',rh.BarEdgeColor);
        axis tight
        cf = findobj('tag','rhShowAxes');
        if strcmp(get(cf,'checked'), 'off');
            axis off
        end

        xlabel(xt)
        if rh.CalcRateChange(1)
            [mv mt] = max(binheights);
            fprintf('%d-%d  max: %2.1fHz %dsec',...
                rh.SpikeID, rh.AlignID, mv, bintimes(mt));
            times = drh('CalcRateChangeTimes',binheights);
            if times(1)
                text(bintimes(times(1)),binheights(times(1)),'\downarrow',...
                    'FontSize',8,...
                    'color','k',...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom');
                fprintf('  onset %dsec  ',bintimes(times(1)));
                if times(2) && 0  % don't display
                    text(bintimes(times(2)),binheights(times(2)),'\downarrow',...
                        'FontSize',8,...
                        'color','b',...
                        'HorizontalAlignment','center',...
                        'VerticalAlignment','bottom');
                    fprintf('offset %dsec',bintimes(times(2)));
                end
            end
            fprintf('\n')
        end

        if rh.FindFirstDiff && ~isempty(rh.obsd)  % then have a pair so draw arrow at first diff
            sigbin = [];
            res =  zeros(size(rh.bsd,1), 1);
            for i = 1:length(res)
                [H,P,CI,STATS] = ttest2(rh.obsd(i,:), rh.bsd(i,:), 0.05, 0);
                res(i) = H;
            end
            sigbinindex = find(diff(res));
            for i = 1:length(sigbinindex)
                if sigbinindex(i)+2 <= length(res)
                    if res(sigbinindex(i)+1) == 1 && res(sigbinindex(i)+2) == 1
                        sigbin = sigbinindex(i);
                        break
                    end
                end
            end

            if ~isempty(sigbin)
                text(bintimes(sigbin),binheights(sigbin),'+',...
                    'FontSize',12,...
                    'color','k',...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom');
                fprintf('Channel %d first diff at %dsec\n',rh.SpikeID, bintimes(sigbin));
            end


        end


    case('CalcRateChangeTimes');
        baseSD = std(data(1:rh.CalcRateChange(2)));
        baseM	 = mean(data(1:rh.CalcRateChange(2)));
        saveSmooth = rh.Smoothing;
        rh.Smoothing = 2;
        data =drh('smooth',data);
        rh.Smoothing = saveSmooth;
        GotOnset = 0;
        result = [0 0];
        for i = rh.CalcRateChange(2)+1:length(data)-1
            if ~GotOnset
                if abs(data(i)-baseM) > 3*baseSD && abs(data(i+1)-baseM) > 3*baseSD
                    result(1) = rh.CalcRateChange(2)+1;
                    GotOnset = 1;
                    for j =i:-1:rh.CalcRateChange(2)
                        if abs(data(j)-baseM) < 2*baseSD && abs(data(j-1)-baseM) < 2*baseSD
                            result(1) = j+1;
                            break;
                        end
                    end
                end
                %found an onset of rate change

            else
                if abs(data(i)-baseM) < baseSD && abs(data(i+1)-baseM) < baseSD
                    result(2) = i;
                    break;
                end
            end
        end


    case('smooth');
        l1 = length(data);

        switch (rh.Smoothing)
            case 0
                result = data;
                return

            case 1
                GTAB1 =[ 0., 0., 0., 0., 0., 0., 0., 5.39910E-02,...
                    2.41971E-01, 3.98942E-01, 2.41971E-01, 5.39910E-02,...
                    0., 0., 0., 0., 0., 0., 0.];
                out = conv(data, GTAB1);

            case 2
                GTAB2 =[ 0., 0., 0., 0., 0., 2.69955E-02, 6.47588E-02,...
                    1.20985E-01, 1.76033E-01, 1.99471E-01, 1.76033E-01,...
                    1.20985E-01, 6.47588E-02, 2.69955E-02, 0., 0., 0., 0., 0.];
                out = conv(data, GTAB2);


            case 4
                GTAB4 =[ 7.9349130E-03, 1.3497742E-02, 2.1569330E-02,...
                    3.2379400E-02, 4.5662273E-02, 6.0492679E-02, 7.5284354E-02,...
                    8.8016331E-02, 9.6667029E-02, 9.9735573E-02, 9.6667029E-02,...
                    8.8016331E-02, 7.5284354E-02, 6.0492679E-02, 4.5662273E-02,...
                    3.2379400E-02, 2.1569330E-02, 1.3497742E-02, 7.9349130E-03];
                out = conv(data, GTAB4);

        end

        l2 = length(out);
        result = out((l2-l1)/2+1:end-(l2-l1)/2);


    case('FindFirstChange');
        cf = findobj('tag', 'findfirstchange');
        if strcmp(get(cf, 'checked'), 'off')
            set(cf, 'checked', 'on');
            rh.CalcRateChange(1) = 1;
        else
            set(cf, 'checked', 'off');
            rh.CalcRateChange(1) = 0;
        end



    case('FindFirstDifference');
        cf = findobj('tag', 'findfirstdifference');
        if strcmp(get(cf, 'checked'), 'off')
            set(cf, 'checked', 'on');
            rh.FindFirstDiff = 1;
        else
            set(cf, 'checked', 'off');
            rh.FindFirstDiff = 0;
        end



    case('contextMenu');
        typ = get(gco,'UserData');
        cp = get(gca,'CurrentPoint');
        switch (typ)

            case ('raster');
                s{1} = 'AutoCorrelate';
                s{2} = 'Copy';
                [selected,ok] = listdlg('ListString',s,'Name','do what',...
                    'Position',[cp(3),cp(1), 100, 100],...
                    'SelectionMode','single','ListSize',[100 100]);
                if ok
                    switch (selected)
                        case(1)
                            drh('xcortest');
                        case(2)
                            fprintf('not implemented');
                    end
                end

        end

    case('setBW');
        cf = findobj('tag', 'setBW');
        jps.secBinWidth =  rh.BWList(get(cf,'value'));
        drh('drhSetStartsec');
        drh('drhSetStopsec');

    case('drhSetStartsec');
        jps.StartStop(1) = jps.secBinWidth*ceil(jps.StartStop(1)/jps.secBinWidth);  % all these have to be right

        cf = findobj('tag','drhStartSlider');
        set(cf,'value',jps.StartStop(1));
        cf = findobj('Tag','drhStartsec');
        set(cf,'String',int2str(jps.StartStop(1)));

    case('drhSetStopsec');
        jps.StartStop(2) = jps.secBinWidth*floor(jps.StartStop(2)/jps.secBinWidth);  % all these have to be right
        cf = findobj('tag','drhStopSlider');
        set(cf,'value',jps.StartStop(2));
        cf = findobj('Tag','drhStopsec');
        set(cf,'String',int2str(jps.StartStop(2)));

    case('drhStartsec');
        cf = findobj('tag','drhStartSlider');
        jps.StartStop(1) = get(cf,'value');
        drh('drhSetStartsec');

    case('drhStopsec');
        cf = findobj('tag','drhStopSlider');
        jps.StartStop(2) = get(cf,'value');
        drh('drhSetStopsec');


    case('makeStartStopBWWind');
        h0 = figure('Units','points', ...
            'Name','DRH', ...
            'NumberTitle','off', ...
            'MenuBar','none',...
            'Position',[450 308 100 103], ...
            'Color',[0.8 0.8 0.8], ...
            'Tag','drhSSBW');
        rh.BWStr = num2str(rh.BWList(1));
        for i = 2:length(rh.BWList)
            rh.BWStr = [rh.BWStr '|' num2str(rh.BWList(i))];
        end
        % find the menu item closest to the actual jps.secBinwWidth
        [val,inx] = sort(abs(rh.BWList - jps.secBinWidth));
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'Callback','drh setBW;', ...
            'ListboxTop',0, ...
            'Position',[10.5 73.75 80.5 15.75], ...
            'String',rh.BWStr, ...
            'Style','popupmenu', ...
            'Tag','setBW', ...
            'Value',inx(1));
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','left', ...
            'ListboxTop',0, ...
            'Position',[10.5 89.5 80.5 9.75], ...
            'String','Bin Width (sec)', ...
            'Style','text', ...
            'Tag','BWText');

        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','left', ...
            'ListboxTop',0, ...
            'Position',[10.5 52.75 55.25 9.75], ...
            'String','Trial Start sec:', ...
            'Style','text', ...
            'Tag','drhStartText');
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','right', ...
            'ListboxTop',0, ...
            'Position',[65.5 52.75 25.5 9.75], ...
            'String',int2str(jps.StartStop(1)), ...
            'Style','text', ...
            'Tag','drhStartsec');
        quantum = 10/(jps.StartStopRange(2) - jps.StartStopRange(1));
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
            'Callback','drh drhStartsec;', ...
            'ListboxTop',0, ...
            'Max',jps.StartStopRange(2), ...
            'Min',jps.StartStopRange(1), ...
            'Position',[10.5 36.75 80.5 15.75], ...
            'SliderStep',[quantum quantum*10], ...
            'Style','slider', ...
            'Tag','drhStartSlider', ...
            'TooltipString','Start time relative to align',...
            'Value',jps.StartStop(1));
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','left', ...
            'ListboxTop',0, ...
            'Position',[10.5 23.5 55.25 9.75], ...
            'String','Trial Stop sec:', ...
            'Style','text', ...
            'Tag','drhStopText');
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','right', ...
            'ListboxTop',0, ...
            'Position',[65.5 23.5 25.5 9.75], ...
            'String',int2str(jps.StartStop(2)), ...
            'Style','text', ...
            'Tag','drhStopsec');
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.752941176470588 0.752941176470588 0.752941176470588], ...
            'Callback','drh drhStopsec;', ...
            'ListboxTop',0, ...
            'Max',jps.StartStopRange(2), ...
            'Min',jps.StartStopRange(1), ...
            'Position',[10.5 7.5 80.5 15.75], ...
            'SliderStep',[quantum quantum*10], ...
            'Style','slider', ...
            'Tag','drhStopSlider', ...
            'TooltipString','Stop time relative to align', ...
            'Value',jps.StartStop(2));

    case('getNewGDFFile');
        JPSVars('getNewGDFFile');
        cf = findobj('tag','drhMain');
        set(cf,'Name',[rh.Version ' - ' jps.FileName]);


    case('makeMainWind');


        rh.Version = 'Raster / Histogram v0.70';

        h0 = figure;
        set(h0, 'UserData', [], ...
            'MenuBar','none', ...
            'CloseRequestFcn', 'drh exit;',...
            'tag','drhMain',...
            'Name',[rh.Version ' - ' jps.FileName], ...
            'Numbertitle','off',...
            'Position',[30 74 560 426],...
            'toolbar','figure');

        h1 = uimenu('Parent',h0, ...
            'Label','&File', ...
            'Tag','rhFile');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh getNewGDFFile;', ...
            'Label','&Open GDF...', ...
            'Tag','OpenGDF');
        h2 = uimenu('Parent',h1, ...
            'Callback','JPSVars', ...
            'Label','Change defaults...', ...
            'Tag','changedefaults');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh exit;', ...
            'separator','on',...
            'Label','E&xit', ...
            'Tag','exit');
        h2 = uimenu('Parent',h1, ...
            'Callback','pagesetupdlg', ...
            'separator','on',...
            'Label','Page Setup...', ...
            'Tag','drhpgsetup');
        h2 = uimenu('Parent',h1, ...
            'Callback','printpreview', ...
            'Label','Print Pre&view...', ...
            'Tag','drhprintpreview');
        h2 = uimenu('Parent',h1, ...
            'Callback','printdlg', ...
            'Label','&Print ...', ...
            'Tag','drhprint');
        h1 = uimenu('Parent',h0, ...
            'Label','&Analysis', ...
            'Tag','rhAnalysis');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh togAutoCorr;', ...
            'Label',['Autocorrelate : ' rh.ACorNorm], ...
            'checked','off',...
            'Tag','acorr');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh FindFirstChange;', ...
            'Label','Find first change ', ...
            'checked','off',...
            'Tag','findfirstchange');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh FindFirstDifference;', ...
            'Label','Find first difference ', ...
            'checked','off',...
            'Tag','findfirstdifference');

        h1 = uimenu('Parent',h0, ...
            'Label','&Options', ...
            'Tag','rhOptions');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh selectSpikeIDs;', ...
            'Label','select Spike IDs', ...
            'Tag','selectSpikeIDs');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh selectAlignIDs;', ...
            'Label','select Align IDs', ...
            'Tag','selectAlignIDs');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh selectMarkerIDs;', ...
            'Label','select Marker IDs', ...
            'Tag','selectMarkerIDs');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh sortTrials', ...
            'Label','sort trials', ...
            'Tag','SortTrials');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh display;', ...
            'separator','on',...
            'Label','update', ...
            'Tag','update');
        h2 = uimenu('Parent',h1, ...
            'Callback','figure; drh draw new;', ...
            'separator','on',...
            'Label','update in new window', ...
            'Tag','updatenew');
        h1 = uimenu('Parent',h0, ...
            'Label','&Display', ...
            'Tag','rhDisplay');
        h2 = uimenu('Parent',h1, ...
            'Callback','drh togShowAxes;', ...
            'Label','Show axes', ...
            'checked','off',...
            'Tag','rhShowAxes');

        h2 = uimenu('Parent',h1, ...
            'Callback','drh makeStartStopBWWind;', ...
            'Label','Show timing window...', ...
            'checked','off',...
            'Tag','rhmakeStartStopBWWind');


        rh.RasterMenu = uicontextmenu;
        cb1 = 'drh xcortest;';
        item1 = uimenu(rh.RasterMenu, 'Label', 'Autocorrelate', 'Callback', cb1);

        rh.HistoMenu = uicontextmenu;
        cb1 = 'drh AddScaleBar;';
        item1 = uimenu(rh.HistoMenu, 'Label', 'add scalebar', 'Callback', cb1);

    case('togShowAxes');
        cf = findobj('tag','rhShowAxes');
        ch = strcmp(get(cf,'checked'), 'on');
        if ch
            set(cf,'checked','off');
            axis off
        else
            set(cf,'checked','on');
            axis on
        end


    case('togAutoCorr');
        cf = findobj('tag','acorr');
        ch = strcmp(get(cf,'checked'), 'on');
        %  if ch
        set(cf,'checked','off');
        %  else
        drh('setACorNorm')
        %    set(cf,'checked','on');
        set(cf,'Label',['Autocorrelate : ' rh.ACorNorm]);
        %  end


    case('selectSpikeIDs');
        % jps.SpikeIDList;    % current valid spikeID(s) in jps.gdf
        v = [];
        for i = 1: length(jps.SpikeIDList);
            s{i} = int2str(jps.SpikeIDList(i));
        end
        if ~isempty(jps.SpikeID)
            for i = 1:length(jps.SpikeIDList)
                if find(jps.SpikeID(:) == jps.SpikeIDList(i))
                    v = [v, i];
                end
            end
        end

        [selected,ok] = listdlg('ListString',s,'Name','select Spike IDs',...
            'InitialValue',v,...
            'ListSize',[100 100]);
        if ok
            jps.SpikeID = jps.SpikeIDList(selected);
        end


    case('selectAlignIDs');
        % jps.SpikeIDList;    % current valid spikeID(s) in jps.gdf
        if isempty(jps.AlignIDList)
            msgbox('No align codes are available in this gdf file!', 'No align codes');
            return
        end
        v = [];
        s = [];
        for i = 1: length(jps.AlignIDList);
            s{i} = int2str(jps.AlignIDList(i));
        end
        if ~isempty(jps.AlignID)
            for i = 1:length(jps.AlignIDList)
                if find(jps.AlignID(:) == jps.AlignIDList(i))
                    v = [v, i];
                end
            end
        end

        [selected,ok] = listdlg('ListString',s,'Name','select Align IDs',...
            'InitialValue',v,...
            'ListSize',[100 100]);
        if ok
            jps.AlignID = jps.AlignIDList(selected);
        end



    case('selectMarkerIDs');
        v = [];
        s{1} = 'none';
        for i = 1: length(jps.AlignIDList);
            s{i+1} = int2str(jps.AlignIDList(i));
        end
        if ~isempty(rh.MarkerIDs)
            for i = 1:length(jps.AlignIDList)
                if find(rh.MarkerIDs(:) == jps.AlignIDList(i))
                    v = [v, i+1];
                end
            end
        end

        [selected,ok] = listdlg('ListString',s,'Name','select Marker IDs',...
            'InitialValue',v,...
            'ListSize',[100 100]);
        if ok
            if length(selected) ==1
                if selected(1) == 1
                    rh.MarkerIDs = [];
                else
                    rh.MarkerIDs = jps.AlignIDList(selected-1);
                end
            else
                if selected(1) == 1
                    selected(1) = [];
                end
                rh.MarkerIDs = jps.AlignIDList(selected-1);
            end

        end


    case('sortTrials');
        v = [];
        s{1} = 'gdf order';
        for i = 1: length(jps.AlignIDList);
            s{i+1} = int2str(jps.AlignIDList(i));
        end
        if ~isempty(rh.SortID)
            for i = 1:length(jps.AlignIDList)
                if find(rh.SortID == jps.AlignIDList(i))
                    v = [v, i+1];
                end
            end
        end

        if isempty(v)
            v = 1;
        end
        [selected,ok] = listdlg('ListString',s,'Name','Sort trials by',...
            'InitialValue',v,...
            'SelectionMode','single',...
            'ListSize',[100 100]);
        if ok
            if selected(1) == 1
                rh.SortID = [];
            else
                rh.SortID = jps.AlignIDList(selected-1);
            end
        end


    case('setACorNorm');
        s{1} = 'biased';
        s{2} = 'unbiased';
        s{3} = 'coeff';
        s{4} = 'none';
        for v = 1:4
            if strcmp(s{v},rh.ACorNorm)
                break;
            end
        end
        [selected,ok] = listdlg('ListString',s,'Name','set normalization',...
            'InitialValue',v,...
            'SelectionMode','single','ListSize',[100 100]);
        if ok
            rh.ACorNorm = s{selected};
        end


    case('exit')
        cf = findobj('tag','drhMain');
        if ~isempty(cf)
            set(cf,'CloseRequestFcn', 'closereq');
            close(cf);
        end
        cf = findobj('Tag','drhSSBW');
        if ~isempty(cf)
            close(cf);
        end


    case('display')
        if ~(exist('data', 'var')==1)
            data = 'b';
        else
            data = 0;
        end
        cf = findobj('tag','drhMain');
        if isempty(cf)
            drh('makeMainWind');
            cf = findobj('tag','drhMain');
        end
        figure(cf);
        drh('draw', data);

    case('draw')
        if isempty(jps.AlignIDList)
            msgbox('No align code chosen - nothing to display', 'No align code');
            return
        end
        cf = gcf;
        a = get(cf, 'children');
        delete(findobj(a, 'type', 'axes'));
        cr = findobj('tag','acorr');
        DoXcorr = strcmp(get(cr,'checked'), 'on');
        DoXcorr = 0;
        switch rh.TrialDisplay
            case('all')
                rh.DisplayTrials = 0;

            case('same')
                mn = 1000000;
                for i = 1:length(jps.AlignID)
                    drh('getAlignIDTimes',jps.AlignID(i));
                    if length(rh.AlignIDTimes) < mn
                        mn = length(rh.AlignIDTimes);
                    end
                end
                rh.DisplayTrials = mn;
        end

        switch data(1)

            case('r')	% display raster(s) only
                for i = 1:length(jps.SpikeID)
                    drh('getSpikeIDTimes',jps.SpikeID(i));
                    for j = 1:length(jps.AlignID)
                        drh('getAlignIDTimes',jps.AlignID(j));
                        drh('getRasterVector');
                        subplot(length(jps.SpikeID),length(jps.AlignID),length(jps.AlignID)*(i-1)+j);
                        drh('plotRaster');
                        if j ==1
                            ax = axis;
                            text(ax(1)-0.1*(ax(2)-ax(1)),(ax(3)+ax(4))/2,['ID ' int2str(jps.SpikeID(i))], ...
                                'rotation',90,...
                                'HorizontalAlignment','center',...
                                'VerticalAlignment','middle',...
                                'FontSize',6);
                        end
                        drawnow
                    end
                end

            case('h')	% display histograsec(s) only
                m = 0;
                for i = 1:length(jps.SpikeID)
                    drh('getSpikeIDTimes',jps.SpikeID(i));
                    for j = 1:length(jps.AlignID)
                        drh('getAlignIDTimes',jps.AlignID(j));
                        drh('getRasterVector');
                        subplot(length(jps.SpikeID),length(jps.AlignID),length(jps.AlignID)*(i-1)+j);

                        drh('plotHistogram');
                        ax = axis;
                        if ax(4) > m
                            m = ax(4);
                        end
                        %if j ==1
                        %  text(ax(1)-0.1*(ax(2)-ax(1)),(ax(3)+ax(4))/2,['ID ' int2str(jps.SpikeID(i))], ...
                        %    'rotation',90,...
                        %    'HorizontalAlignment','center',...
                        %    'VerticalAlignment','middle',...
                        %    'FontSize',6);
                        %end
                        drawnow
                    end
                end
                ax(3) = 0;
                ax(4) = m;
                for i = 1:length(jps.SpikeID)*length(jps.AlignID)
                    subplot(length(jps.SpikeID),length(jps.AlignID),i);
                    axis(ax);
                    if mod(i,length(jps.AlignID)) == 1
                        text(ax(1)-0.1*(ax(2)-ax(1)),(ax(3)+ax(4))/2,['ID ' int2str(jps.SpikeID(ceil(i/length(jps.AlignID))))], ...
                            'rotation',90,...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','middle',...
                            'FontSize',6);
                    end
                end

            otherwise

                rh.bsd = [];
                m = 0;
                for i = 1:length(jps.SpikeID)
                    drh('getSpikeIDTimes',jps.SpikeID(i));
                    rh.obsd = [];
                    for j = length(jps.AlignID):-1:1
                        k = length(jps.AlignID)-j+1;
                        drh('getAlignIDTimes',jps.AlignID(j));
                        drh('calcSortOrder');
                        drh('getMarkerVectors');
                        drh('getRasterVector');
                        if DoXcorr
                            f = jps.FileName;
                            s = int2str(jps.SpikeID(i));
                            a = int2str(jps.AlignID(j));
                            t = [int2str(jps.StartStop(1)) ':' int2str(jps.StartStop(2))];
                            %        xcorrRaster([f '  SpikeID ' s '  AlignID ' a '  time ' t],'coeff');
                            xcorrRaster([f '  SpikeID ' s '  AlignID ' a '  time ' t],rh.ACorNorm);
                        end
                        figure(cf);
                        subplot(2*length(jps.SpikeID),length(jps.AlignID),length(jps.AlignID)*(2*i -1)+k);
                        if ~rh.RasterVectorValid
                            axis([0 1 0 1]);
                            axis off
                            s = ['No spikes in range for spike ID ' int2str(jps.SpikeID(i)) ' align ID ' int2str(jps.AlignID(j))];
                            fprintf('%s\n',s);
                        else
                            drh('plotRaster');
                            if i == length(jps.SpikeID)
                                ax = axis;
                                if jps.StartStop(1) <= 0 && jps.StartStop(2) >= 0
                                    text(0,0,'\uparrow',...
                                        'HorizontalAlignment','center',...
                                        'VerticalAlignment','top');
                                end
                                if abs(jps.StartStop(2)) > abs(jps.StartStop(1))
                                    text(ax(2),-1,...
                                        ['Align ID: ' int2str(jps.AlignID(j)) ' (' int2str(length(rh.SortOrder)) '/' int2str(length(rh.AlignIDTimes)) ')'],...
                                        'HorizontalAlignment','right',...
                                        'VerticalAlignment','top',...
                                        'FontSize',6);
                                else
                                    text(ax(1),-1,...
                                        ['Align ID: ' int2str(jps.AlignID(j)) ' (' int2str(length(rh.SortOrder)) '/' int2str(length(rh.AlignIDTimes)) ')'],...
                                        'HorizontalAlignment','left',...
                                        'VerticalAlignment','top',...
                                        'FontSize',6);
                                end
                            end
                            subplot(2*length(jps.SpikeID),length(jps.AlignID),length(jps.AlignID)*(2*i-2)+k);
                            drh('plotHistogram');
                            if isempty(rh.obsd) % then this is the first align id so save for comparison (for findfirstdiff)
                                rh.obsd = rh.bsd;
                            end
                            ax = axis;
                            if ax(4) > m
                                m = ax(4);
                            end
                            drawnow
                        end
                    end
                end
                ax(3) = 0;
                ax(4) = m+0.05*m;
                ax(1) = ax(1)-0.002*(ax(2)-ax(1));
                for i = 1:2*length(jps.SpikeID)*length(jps.AlignID)
                    if rem(ceil(i/length(jps.AlignID)),2)
                        subplot(2*length(jps.SpikeID),length(jps.AlignID),i);
                        if sum(ax)
                            if ~rh.CommonScale
                                ax = axis;
                                ax(1) = ax(1)-0.002*(ax(2)-ax(1));
                                ax(4) = ax(4)+0.05*ax(4);
                            end
                            axis(ax);
                            if mod(i,length(jps.AlignID)) == 1  || length(jps.AlignID) == 1
                                %        text(ax(1)-0.1*(ax(2)-ax(1)),(ax(3)+ax(4))/2,[int2str(jps.SpikeID(ceil(i/(2*length(jps.AlignID)))))-20000], ...
                                text(ax(1)-0.1*(ax(2)-ax(1)),(ax(3)+ax(4))/2,['ID ' int2str(jps.SpikeID(ceil(i/(2*length(jps.AlignID)))))], ...
                                    'rotation',90,...
                                    'HorizontalAlignment','right',...
                                    'VerticalAlignment','middle',...
                                    'FontSize',12);
                            end
                            if i == 1
                                text(ax(1),ax(4) + length(jps.SpikeID)*(ax(4)-ax(3))/10,['File: ' jps.FileName '    bin width: ' num2str(jps.secBinWidth) 'sec'  ], ...
                                    'HorizontalAlignment','left',...
                                    'VerticalAlignment','middle',...
                                    'FontSize',8);
                            end
                        else
                
                            axis off
                        end
                    end
                end

        end % local switch

    case('AddScaleBar');
        typ = strcmp(get(gco,'UserData'),'histo');
        if ~typ
            return
        end
        hold on
        ax = axis;
        range = ax(4)-ax(3);
        dec = 0;
        while range > 10
            range = range/10;
            dec = dec+1;
        end
        Hzsz = 10^dec;
        if range < 2.5
            Hzsz = Hzsz/2;
        end

        range = ax(2)-ax(1);
        dec = 0;
        while range > 10
            range = range/10;
            dec = dec+1;
        end
        tmsz = 10^dec;
        if range < 2.5
            tmsz = tmsz/2;
        end

        x = [ax(2) ax(2)];
        y = [ax(4)-Hzsz ax(4)];
        line(x, y,'color','k','linewidth',2);
        text(x(1),mean(y), [' ' int2str(Hzsz) 'Hz'],...
            'HorizontalAlignment','left',...
            'VerticalAlignment','middle',...
            'FontSize',6);

        x = [ax(2)-tmsz ax(2)];
        y = [ax(4) ax(4)];
        line(x, y,'color','k','linewidth',2);
        text(mean(x),y(2), [' ' int2str(tmsz) 'ms'],...
            'HorizontalAlignment','center',...
            'VerticalAlignment','bottom',...
            'FontSize',6);

        hold off


    case ('xcortest');
        typ = strcmp(get(gco,'UserData'),'raster');
        if ~typ
            return
        end
        sz = jps.StartStop(2)-jps.StartStop(1);
        z =[];
        t = get(gco,'tag');
        x = get(gco,'xdata');
        y = get(gco,'ydata');
        for i = 1:y(end)
            temp = x(find(y == i));
            temp = temp-jps.StartStop(1)+1;
            temp = 2*temp;
            temp = ceil(temp);
            tz = zeros(1,2*jps.StartStop(2)-jps.StartStop(1)+1);
            tz(temp) = 1;
            if i == 1
                z = xcorr(tz,tz,sz,rh.ACorNorm);
            else
                z = z + xcorr(tz,tz,sz,rh.ACorNorm);
            end
        end

        h = figure;
        z = z/length(rh.SortOrder);
        x = -sz:sz;
        z(ceil(length(z)/2)) = 0;  % remove central 0 peak
        a =bar(x,z,1);
        set(gca,'xtickmode','manual');
        %set(gca,'xtick',[-20, -10, 0, 10, 20]);
        set(gca,'xtick',[-15, -10, -5, 0, 5, 10, 15]);
        set(gca,'xticklabel',['-15';'-10';'-5 ';' 0 ';' 5 ';' 10';' 15']);
        axis([-20 20 0 0.10]);
        ylabel([' Normalization: ' rh.ACorNorm]);
        %xlabel(['ms (0.5ms bins)']);
        title(t);







end  % main switch
