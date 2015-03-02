function out = SzLengthMeasure(action, data);
global sf;
global eeghdr;

if ~exist('action')
%    try
        if ~isempty(findobj('tag', 'alMain'))
            action = 'buttondown';
        else
            action = 'file';
        end
%    catch
%        action = 'file';
%    end
end

switch action

    case('file')
        defaultanswer = {''};
        sf.User = [];
        sf.User = inputdlg('Enter an identifier (ie, your name)','User Identifier', 1, defaultanswer);
        if isempty(sf.User) | strcmp(strtrim(sf.User),'')
            sf.User = inputdlg('An identifier must be entered','User Identifier', 1, defaultanswer);
        end
        if isempty(sf.User) | strcmp(strtrim(sf.User),'')
            fprintf('Aborting because no user identifier has been entered.\n');
            return
        end
        
        try
            dp = GetResultsDataPath;
        catch
            dp = [];
        end
        source = [dp '*_Seizures_examined.mat'];
        FileName = [];
        [FileName, DPath] = uigetfile(source, 'Choose an examined seizures results file to examine');
        if ~(FileName)
            out = [];
            fprintf('No file selected, aborting\n');
            eeghdr = [];
            return
        end

        load([DPath FileName]);
        if isempty(sf.gdf)
            fprintf('No events detected in the examined seizures analysis for %s\n', sf.DataFile);
        else
            SzLengthMeasure('init', sf);
        end



    case 'init'
        sf.ViewVersusRef = 1;
        szenable = 'on';
        bzenable = 'off';
        spenable = 'off';
        sf.lpfilter = 70;
        sf.hpfilter = [];
        sf.Duration = [];
        sf.CurrentStart = [];
        sf.CurrentEnd = [];


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

        clear sf.EventData;

        sf.gdf = sf.gdf(find(sf.gdf(:,1) == 990),:);  % only those marked as seizures
        sf.gdf(:,3:5) = -1;             % 3 will be start tick, 4 end tick of the seizure, 5 duration in seconds
        sf.EventList = sf.gdf(:,2);
        

        sf.inrefraction = 0;
        sf.alignsec = -30;
        sf.totalsec = 180;
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

        sf.Version = 'Seizure Finder v2.10';
        sf.Results = [];
        sf.fftplot = [];
        sf.redplot = [];

        y = 0.80;
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
            'Callback','SzLengthMeasure seizure;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','accept', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','accept', ...
            'Enable','off');
        y = y+dy;


        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure redo;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','re-do selection', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','redo', ...
            'Enable','off');
        y = y+dy;



        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure noSZ;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','not a seizure', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','possSZ', ...
            'Enable',szenable);
        y = y+dy;

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure back;', ...
            'ListboxTop',0, ...
            'Position',[.80 y .15 .10], ...
            'String','<- back', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','back', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure earlier;', ...
            'ListboxTop',0, ...
            'Position',[0.1, 0.05, 0.05 .07], ...
            'String','<', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','earlier', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure later;', ...
            'ListboxTop',0, ...
            'Position',[0.16, 0.05, 0.05 .07], ...
            'String','>', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','later', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure more;', ...
            'ListboxTop',0, ...
            'Position',[0.24, 0.05, 0.05 .07], ...
            'String','zoom out', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','more', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure less;', ...
            'ListboxTop',0, ...
            'Position',[0.30, 0.05, 0.05 .07], ...
            'String','zoom in', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','less', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure showvideo;', ...
            'ListboxTop',0, ...
            'Position',[0.58, 0.05, 0.09 .07], ...
            'String','show video', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','showvideo', ...
            'Enable','off');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure save;', ...
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
            'Callback','SzLengthMeasure sethp;', ...
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
            'Callback','SzLengthMeasure setlp;', ...
            'ListboxTop',0, ...
            'Position',[0.46, 0.05, 0.07 .07], ...
            'String',s, ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','setlp', ...
            'Enable','on');

        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure increaseY;', ...
            'ListboxTop',0, ...
            'Position',[0.01, 0.75, 0.02 .15], ...
            'String','^', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','increaseY', ...
            'Enable','on');
        h1 = uicontrol('Parent',sf.Main, ...
            'Units','normalized', ...
            'Callback','SzLengthMeasure decreaseY;', ...
            'ListboxTop',0, ...
            'Position',[0.01, 0.58, 0.02 .15], ...
            'String','v', ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'off', ...
            'Tag','decreaseY', ...
            'Enable','on');


        sf.plot = subplot('position', [0.1, 0.30, 0.65, 0.60]);
        set(gca, 'ButtonDownFcn', 'SzLengthMeasure');

        SzLengthMeasure('getNext');


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
        SzLengthMeasure('draw');


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
        SzLengthMeasure('draw');


    case 'earlier'
        if sf.totalsec > 30
        sf.alignsec = sf.alignsec - 15;
        else
            sf.alignsec = sf.alignsec - sf.totalsec/2;
        end
        SzLengthMeasure('draw');
        
        
    case 'later'
        if sf.totalsec > 30
            sf.alignsec = sf.alignsec + 15;
        else
            sf.alignsec = sf.alignsec + sf.totalsec/2;
        end
        SzLengthMeasure('draw');
       
        
    case 'more'
        if sf.totalsec > 30
            sf.alignsec = sf.alignsec - 15;
            sf.totalsec = sf.totalsec + 30;
        else
            sf.alignsec = sf.alignsec-sf.totalsec/2;
            sf.totalsec = sf.totalsec*2;
        end
        SzLengthMeasure('draw');
      
        
    case 'less'
        if sf.totalsec > 60
            sf.alignsec = sf.alignsec + 15;
            sf.totalsec = sf.totalsec - 30;
        else
            sf.totalsec = sf.totalsec/2;
            sf.alignsec = sf.alignsec+ sf.totalsec/2;
        end
        SzLengthMeasure('draw');
 
        
    case 'increaseY'
        sf.yspacer = 2*sf.yspacer;
        SzLengthMeasure('draw');

    case 'decreaseY'
        sf.yspacer = sf.yspacer/2;
        SzLengthMeasure('draw');

    case 'buttondown'
        point1 = get(gca,'CurrentPoint');    % button down detected
        finalRect = rbbox;                   % return figure units
        point2 = get(gca,'CurrentPoint');    % button up detected
        ax = axis;
        hold on
        sf.FirstLine = plot([point1(1,1) point1(1,1)], [ax(3) ax(4)], 'r');
        sf.SecondLine = plot([point2(1,1) point2(1,1)], [ax(3) ax(4)], 'r');

        sf.CurrentStart = point1(1,1)*sf.rate;
        sf.CurrentEnd = point2(1,1)*sf.rate;
        sf.Duration = abs(point2(1,1) - point1(1,1));
        drawnow
        hold off
        cf = findobj('tag', 'accept');
        if ~isempty(cf)
            set(cf, 'enable', 'on');
        end    
        cf = findobj('tag', 'redo');
        if ~isempty(cf)
            set(cf, 'enable', 'on');
        end    
        
        

    case 'seizure'
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        sf.gdf(sf.EventIndex, 1) = 990;
        sf.gdf(sf.EventIndex, 3) = sf.CurrentStart;
        sf.gdf(sf.EventIndex, 4) = sf.CurrentEnd;
        sf.gdf(sf.EventIndex, 5) = sf.Duration;
        sf.CurrentStart = [];
        sf.CurrentEnd = [];
        sf.Duration = [];
        
        cf = findobj('tag', 'accept');
        if ~isempty(cf)
            set(cf, 'enable', 'off');
        end    
        cf = findobj('tag', 'redo');
        if ~isempty(cf)
            set(cf, 'enable', 'off');
        end    
  
        fprintf('seizure at %s marked\n', st);
        SzLengthMeasure('getNext');


    case 'noSZ'
        SzLengthMeasure('getNext');
        sf.gdf(sf.EventIndex, 1) = 0;
        st = datestr(GetEEGData('tick2datetime', sf.EventList(sf.EventIndex)));
        fprintf('event at %s (%s) unmarked as a seizure\n', st, eeghdr.fname);
        SzLengthMeasure('getNext');


    case 'redo'
        cf = findobj('color', 'red');
        delete(cf);
        cf = findobj('tag', 'redo');
        if ~isempty(cf)
            set(cf, 'enable', 'off');
        end    
        cf = findobj('tag', 'accept');
        if ~isempty(cf)
            set(cf, 'enable', 'off');
        end    

        sf.CurrentStart = [];
        sf.CurrentEnd = [];
        sf.Duration = [];
          
    case 'back'
        sf.EventIndex = sf.EventIndex-2;
        if sf.EventIndex < 0
            sf.EventIndex = 0;
        end
        SzLengthMeasure('getNext');


        
        
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
                sn =[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_timed.mat'];
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
            sn=[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_timed.mat'];
            save(sn, 'sf');
            fprintf('results saved to %s\n', sn);
            return
        end
        sf.EventIndex = sf.EventIndex+1;
        if sf.EventIndex > length(sf.EventList)
            sf.EventIndex = length(sf.EventList);
        end

        % reset window values
        sf.alignsec = -30;
        sf.totalsec = 180;

        SzLengthMeasure('draw');

    case('save')
        t = sf.data;
        sf.data = [];
        try
            dp = GetResultsDataPath;
        catch
            dp = [];
        end
        sn=[dp GetName('name', eeghdr.fname) '_' sf.analysislabel '_timed_' sf.User '.mat'];
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

        dvec = GetEEGData('tick2datetime', sf.EventList(sf.EventIndex));
        x = 1:length(d);
        x = x/eeghdr.rate + sf.alignsec;
        plot(x(1:sf.drawpts:end), d(1:sf.drawpts:end,:), 'b', 'hittest', 'off');
        set(gca, 'ButtonDownFcn', 'SzLengthMeasure');
        title([datestr(dvec) '     event ' num2str(sf.EventIndex) '/' num2str(size(sf.EventList,1))]);
        xlabel('seconds');
        ylabel('uV');
        axis tight
        ax = axis;
        ax(3) = -size(sf.data,2)*sf.yspacer -sf.yspacer;
        ax(4) = 2*sf.yspacer;
        axis(ax);
        

end




function out = GetName(action, PN);

l = length(PN);

% backup from end until we find '\', the next char is the first of the file name
for i = 1:l-1
  s = l-i;
  if PN(l-i) == '\'
     break;
  end   
end

if s ~= 1
  s = s+1;
end  

% s now points to location of first character of file name
FN = [];
switch(action);
   
case('path');
  out = PN(1:s-1);

case('full')		% filename plus all extensions
  out = PN(s:end);
  
case('name')		% filename sans extensions
  for i = s:l		% add chars until you get to the first '.'
    if PN(i) == '.'
      break
    end
    FN = [FN PN(i)];
  end
  out = FN;
   
end