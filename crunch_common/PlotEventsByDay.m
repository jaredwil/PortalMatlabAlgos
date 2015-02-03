function out = PlotEventsByDay(evtxt,texton)
% if doing Nicolet files then evtxt is the event text, 
% else we are reading seizure_results files for 990s and
% evtxt is the rat ID

doNicolet = 0;

if doNicolet
    a = GetEEGData('getAllMDevents', evtxt);
    GetEEGData('setsession', 0);
    start = GetEEGData('getstartdatevec');
    GetEEGData('setsession', 'last');
    last = GetEEGData('getenddatevec');

    st = start;
    st(4:6) = 0;
    last(4:6) = 0;
    szs =zeros(length(a),1);
    d = 60*60*24;  % secs in a day
    for i = 1:length(a)
        szs(i) = ceil(etime(a(i).datevec,st)/d);
    end

    hist(szs, 1:ceil(etime(last,st)/d));
    out = szs;

else
    a = dir(['u:\results\' evtxt '*_Seizures_examined.mat']);
    stim = GetEEGData('readstimfile', ['u:\results\' evtxt]);
    szlist = [];
    recbegin = datenum('01-Jan-2020');
    recend = 0;
    for i = 1:length(a)
       load(['u:\results\' a(i).name])
       start = datevec(sf.sessionstart);
       if datenum(start) < recbegin
           recbegin = datenum(start);
       end
       if datenum(sf.sessionstop) > recend
           recend = datenum(sf.sessionstop);
       end
       sztimes = sf.gdf(find(sf.gdf(:,1) == 990),2);
       sztimes = sztimes/sf.rate;
       for j = 1:length(sztimes)
           st = start;
           st(6) = st(6) + sztimes(j);
           sztimes(j) = datenum(st);       
       end
       szlist = [szlist; sztimes];
    end

    st = datevec(recbegin);
    st(4:6) = 0;
    last = datevec(recend);
    last(4:6) = 0;
    szs =zeros(length(szlist),1);
    d =60*60*24;  % secs in a day
    for i = 1:length(szlist)
        szs(i) = ceil(etime(datevec(szlist(i)),st)/d);
    end
    hist(szs, 1:ceil(etime(last,st)/d));
    ax = axis;
    ax(1) =  0;
    ax(2) = 1+ (ceil(etime(last,st)/d));
    if size(stim,2) 
        stimline = ax(4);
        ax(4) = ax(4) + 0.1*ax(4);
    end
    axis(ax);
    title(sprintf('Seizures per day for %s\n', evtxt));
    
    for i = 1:size(stim,2)
        hold on
        son = etime(stim(i).ontime, st)/d;
        soff = etime(stim(i).offtime, st)/d;
        c = [1 0.9 0.9];        
        a = plot([soff, son], [stimline, stimline], 'r', 'linewidth', 3);
        set(a, 'userdata', stim(i));
        set(a, 'ButtonDownFcn', 'a =get(gcbo, ''userdata''); fprintf(''params:  %s\n'',a.params); for i = 1:length(a.comments);fprintf(''%s\n'',a.comments{i});end;fprintf(''\n'')');
        if exist('texton', 'var') && texton
        text(son,stimline, stim(i).params, 'horizontalalign', 'left', 'verticalalign', 'bottom', 'fontsize', 8);
        end
        ff =fill([son son soff soff], [0 stimline stimline 0], c);
        set(ff,'edgecolor', c)
    end
    c = get(gca, 'children');
    set(gca, 'children', flipud(c));
    
    out = szs;
end
