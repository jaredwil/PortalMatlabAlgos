function out = GetEEGData(action, data);

% for GetEEGData('getdata',[0, 100]);
%		(data(1) is the first point to get, data(2) is the number of points to
%		get, in terms of data points, not time first point is 0 - pointer
%		position in file
%reads data from the open eeg file
%start and NoPts are the number of digitized samples
%for each channel that exists in the file
%values are in uv
% 0 is returned for data times out of range
%
%   USAGE:
%   GetEEGData  opens dialogue box to open file
%   GetEEGData('init','path/filename')  opens eeg file (specify bni file)
%   GetEEGData('getdata',[x1,n])   returns data (points x1 to x1+n-1) for each channel from opened file
%   GetEEGData('gettimerange', ['00:00:00', '01:23:34']) returns data in
%       the relative time range passed.  Times must be in the
%       format hr:mn:sc.  Won't currently work if the hour is > 99.

global eeghdr;   % header information of the eeg file
global fltr;

if ~exist('action')
    action = 'init';
end

if isnumeric(action)
    %then it might be a datevec or datenum, convert to a datestring for
    %lookup
    try
        action = datestr(action);
    catch
        return
    end
end

switch action
    case('partialinit')
        try
            p = eeghdr.DataPath;
        catch
            p = [];
        end
        source = [p  data '.eeg'];
        FileName = [];
        [FileName, DPath] = uigetfile(source, 'Open an eeg file');
        if ~(FileName)
            out = [];
            fprintf('No file selected, aborting\n');
            eeghdr = [];
            
            return
        end
        out = GetEEGData('init', [DPath FileName]);

        

    case ('init');
        if ~exist('data', 'var')
            try
                p = eeghdr.DataPath;
            catch
                p = [];
            end
            source = [p '*.eeg'];
            FileName = [];
            [FileName, DPath] = uigetfile(source, 'Open an eeg file');
            if ~(FileName)
                out = [];		
                fprintf('No file selected, aborting\n');
                eeghdr = [];
                return
            end
        else
            FileName = GetName('full',data);
            DPath = GetName('path',data);
        end
        eeghdr.FileName = FileName;
        eeghdr.DataPath = DPath;
        eeghdr.gdfDataPath = [];
        eeghdr.display = 0;
        eeghdr.displayspacer = [];
        eeghdr.dispH  = [];
        eeghdr.fid = [];
        fltr = 0;
        out = GetEEGData('readbni');
        seeg = eeghdr;  % reset to data from first file in series
        
        if ~isempty(out)
            GetEEGData('indexfileticks');
            pH = eeghdr.PtIndx;
            eeghdr = seeg;  % reset to data from first file in series
            eeghdr.PtIndx = pH;
            out = eeghdr;
        else
            eeghdr = [];
            out = [];
        end
        
    case 'setdisplay'
        eeghdr.display = data;
        
    case 'setdisplayspacer'
        eeghdr.displayspacer = data;
           
    case('filteron')
        fltr = 1;
        
    case('filteroff')
        fltr = 0;
        
        
    case('readbni');
        %EEGbni - gets parameters from nicolet .bni header file
        %  [npts, rate, nchan, sens, starttime, labels, nxtfile, startdate] = EEGbni(filename)
        %  npts - total number of data points
        %  rate - sampling rate
        %  nchan - number of channels
        %  sens - scale factor (uV/bit)
        %  starttime - vector of beginning time of recording [hrs mins secs]
        %  labels - channel labels
        %  nxtfile - filename of next file in sequence
        out = [];
        if exist('data', 'var')
            eeghdr.DataPath = GetName('path',data);
            eeghdr.FileName = GetName('full',data);
        end
        fid = -1;

        % try to open associated bni file
        % if the file has the extension .eeg, then  replace it with .bni

        if strcmp(eeghdr.FileName(end-3:end), '.eeg')
            fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4) '.bni'], 'r');

        % if the extension is not eeg, then we need to append .bni to the file name    
        else
            fid = fopen([eeghdr.DataPath eeghdr.FileName '.bni'], 'r');
        end
        if fid == -1
            %fprintf('No bni file for: %s\n', [eeghdr.DataPath eeghdr.FileName]);
            out = [];
            return
        end
        
        
        % bni file is open so read the information inside
        eeghdr.nxtfile = [];
        while 1,
            line = fgetl(fid);
            if ~isstr(line), break; end
            if ~isempty(findstr('Filename',line))
                eeghdr.fname = sscanfname(line,'Filename = %s');
                eeghdr.fname = deblank(eeghdr.fname);
                eeghdr.fname = GetName('full',eeghdr.fname);
            end
            if ~isempty(findstr('Date = ',line)), eeghdr.startdate = sscanf(line,'Date = %d/%d/%d')'; end
			if ~isempty(findstr('Comment = ',line)), eeghdr.avifile = sscanf(line,'Comment = %s'); end
			if ~isempty(findstr('DataOffset = ',line)), eeghdr.ExtraMS = sscanf(line,'DataOffset = %d'); end
            if ~isempty(findstr('Time =',line)), eeghdr.starttime = sscanf(line,'Time = %d:%d:%d')'; end
            if ~isempty(findstr('Rate',line)), eeghdr.rate = sscanf(line, 'Rate = %f Hz'); end
            if ~isempty(findstr('NchanFile',line)), eeghdr.nchan = sscanf(line, 'NchanFile = %d'); end
            if ~isempty(findstr('UvPerBit',line)) %) & (~exist('sens')), 
                if isempty(findstr('DCUvPerBit',line))
                    eeghdr.UvPerBit = sscanf(line, 'UvPerBit = %f'); 
                end
            end
            if ~isempty(findstr('MontageRaw',line)) & (~exist('labels')),
                try,
                    eeghdr.labels = [];
                    I = findstr(line,',');
                    eeghdr.labels = strvcat(eeghdr.labels,line(14:I(1)-1));
                    for chan = 1:length(I)-1,
                        ind1 = I(chan)+1;
                        ind2 = I(chan+1)-1;
                        eeghdr.labels = strvcat(eeghdr.labels,line(ind1:ind2));
                    end
                catch, disp(lasterr);
                end
            end
            txt = line;
            eeghdr.montage = [];
            eeghdr.events = [];
            if ~isempty(findstr('[Events]',txt)),
                nmpg = 0;
                txt = fgetl(fid);
                while isempty(findstr('NextFile',txt)) & isstr(txt),
                    % find montage settings
                    if ~isempty(findstr('Montage:',txt)),
                        I = findstr('Montage:',txt);
                        txt = txt(I(1):end);
                        I = findstr(txt,'Selected');
                        if ~isempty(I), 
                            mtgfmt = 'Montage: Selected Lines: %d';
                            nlines = sscanf(txt,mtgfmt);
                        else, 
                            mtgfmt = 'Montage: %s Lines: %d';
                            A = sscanf(txt,mtgfmt);
                            nlines = A(end);
                        end
                        for k = 1:nlines,
                            txt = fgetl(fid);
                            eeghdr.montage = strvcat(eeghdr.montage,txt); %can parse this later for clipping
                        end
                        % get MPEG info
                    elseif ~isempty(findstr(txt,'MPEG File Start:')),
                        I = findstr(txt,'MPEG File Start:');
                        nmpg = nmpg + 1;
                        I2 = findstr(txt,'DeltaStartMs:');
                        try
                        eeghdr.mpginfo(nmpg).mpgfile = deblank(txt(I(1)+17:I2(1)-1));
                        A = sscanf(txt,'%f\t%d\t%d\t%s');
                        eeghdr.mpginfo(nmpg).starttime = A(1:3);
                        catch
                            A = sscanf(txt,'%f\t%d\t%d\t%s');
                            eeghdr.mpginfo(nmpg).endtime = A(1:3);
                        end
                    elseif ~isempty(findstr(txt,'MPEG File End:')),
                        I = findstr(txt,'MPEG File End:');
                        A = sscanf(txt,'%f\t%d\t%d\t%s');
                        eeghdr.mpginfo(nmpg).endtime = A(1:3);
                    else,
                        eeghdr.events = strvcat(eeghdr.events,txt);
                    end
                    txt = fgetl(fid);
                end
                line = txt;
                if ~isempty(findstr('NextFile',line))
                    eeghdr.nxtfile = sscanf(line,'NextFile = %s');
                    eeghdr.nxtfile = deblank(eeghdr.nxtfile);
                    eeghdr.nxtfile = GetName('full',eeghdr.nxtfile);
                end
            end
           
            
            
        end
        
        fclose(fid);

        %get number of data points in the data file
        D = dir(deblank([eeghdr.DataPath eeghdr.FileName]));
        eeghdr.npts = D.bytes;
        eeghdr.npts = eeghdr.npts./(2*eeghdr.nchan);
        tmp = eeghdr.startdate;
        eeghdr.startdate(1) = tmp(3);  % order start date properly!
        eeghdr.startdate(2) = tmp(1);
        eeghdr.startdate(3) = tmp(2);
        out = eeghdr;
        
       
        
    case('opendatafile')
        GetEEGData('closedatafile');
        eeghdr.fid = fopen([eeghdr.DataPath eeghdr.FileName],'r');
        GetEEGData('readbni');
       % if eeghdr.fid == -1
       %     fprintf('File %s not found.\n', [eeghdr.DataPath eeghdr.FileName]);
       % end
        out = eeghdr.fid;
        
        
    case('datetime2tick');
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        out = eeghdr.rate*(etime(data, eeghdr.PtIndx(1).startdatetimevec));
        %if out < 0 | out > eeghdr.PtIndx(end).last
        %    out = [];  % data not in this file so return empty;
        %end
        
        
    case('tick2datetimevec');
        % return the date and time of the tick number passed
        secs = round(data/eeghdr.rate);
        out = eeghdr.PtIndx(1).startdatetimevec;
        out(6) = out(6) + secs;
        out = datevec(datenum(out));
        
    case('getrate')
        out = eeghdr.rate;
       
        
    case('opennextfile');
        out = -1;
        if isempty(eeghdr.nxtfile)
            fprintf('Reached end of data.\n');
            return
        end
        eeghdr.FileName = eeghdr.nxtfile;
        GetEEGData('readbni');
        out = GetEEGData('opendatafile');
        
        
    case('gettimerange')
        try
            if size(data,1) ==1
                st = data(1:8);
                sp = data(9:16);
            else
                st = data(1,:);
                sp = data(2,:);
            end
            starttime = (str2num(st(1:2))*60 + str2num(st(4:5)))*60 + str2num(st(7:8));
            endtime = (str2num(sp(1:2))*60 + str2num(sp(4:5)))*60 + str2num(sp(7:8));
            starttick = round(starttime*eeghdr.rate);
            noticks = round(endtime*eeghdr.rate) - starttick;
            out = GetEEGData('getdata',[starttick, noticks]);
            
        catch
            fprintf('Invalid time format\n.Aborting\n');
            out = [];
        end
        

    case('getdata')
        out = [];
        data = round(data);  % need to be integers
        f = GetEEGData('findfilefromtick', data(1));
        if isempty(f)
            fprintf('Requested data is past end of range.\nValid range is 0 to %10.0d.\n', eeghdr.PtIndx(end).last);
            return
        end
        eeghdr.FileName = GetName('full', f.name);  % set the name of the file to opne to the correct one

        if GetEEGData('opendatafile') > 0
            if sum(data) <= f.last  % then all the data is in this data file
                data(1) = data(1) - f.first; % get proper offset for this file 
                fseek(eeghdr.fid, eeghdr.nchan*(data(1))*2, -1);
                out = fread(eeghdr.fid,[eeghdr.nchan data(2)],'int16')';
                out = out*eeghdr.UvPerBit;
            else  % need to get some data from the next file
                extra = sum(data) - f.last;
                fseek(eeghdr.fid, eeghdr.nchan*(data(1)-f.first)*2, -1);
                out = fread(eeghdr.fid,[eeghdr.nchan data(2)-extra],'int16')';
                if GetEEGData('opennextfile') > 0
                    if extra > eeghdr.npts
                        extra = eeghdr.npts;
                        fprintf('Requested data is past end of range.\nValid range is 0 to %d.\n', eeghdr.PtIndx(end).last);
                        fprintf('Returning valid data points.\n');            
                    end
                    fseek(eeghdr.fid,0*2, -1);
                    out = [out; fread(eeghdr.fid,[eeghdr.nchan extra],'int16')'];
                    out = out*eeghdr.UvPerBit;
                else
                    fprintf('Requested data (%d to %d) is past end of range\nValid range is 0 to %d.\n', data(1), sum(data), eeghdr.PtIndx(end).last);
                    fprintf('Returning %d valid data points.\n', size(out, 1));            
                end
            end
        end
        if fltr
            out = eegfilt(out, 70, 'hp');
        end
        
        
    case('closedatafile')
        if ~isempty(eeghdr.fid)
            try
                fclose(eeghdr.fid);		
            catch
            end
            eeghdr.fid = [];
        end
        
        
        
    case('findfilefromtick');
        out = [];
        if data < 0 data = 0; end
        
        for i = 1:size(eeghdr.PtIndx,2)
            if eeghdr.PtIndx(i).first > data
                out = eeghdr.PtIndx(i-1);
                eeghdr.FileName = GetName('full',eeghdr.PtIndx(i-1).name);
                eeghdr.DataPath = GetName('path',eeghdr.PtIndx(i-1).name);
                return
            end
        end
        if data <= eeghdr.PtIndx(end).last
            out = eeghdr.PtIndx(end);
            eeghdr.FileName = GetName('full',eeghdr.PtIndx(end).name);
            eeghdr.DataPath = GetName('path',eeghdr.PtIndx(end).name);
        end
        
        
    case('indexfileticks');
        % returns a nx2 array of [first tick  extension] ie, [10222030389 '001']  
        
        eeghdr.PtIndx = [];
        pts = 0;
        i =1;
        
        % come in with first bni file already loaded
        while 1
            eeghdr.PtIndx(i).first = pts;
            eeghdr.PtIndx(i).last = pts+eeghdr.npts-1;
            eeghdr.PtIndx(i).name = [eeghdr.DataPath eeghdr.FileName];
            eeghdr.PtIndx(i).startdatetimevec = [eeghdr.startdate eeghdr.starttime];
            endtm = eeghdr.PtIndx(i).startdatetimevec;
            endtm(end) = endtm(end) + round(eeghdr.npts/eeghdr.rate);
            eeghdr.PtIndx(i).enddatetimevec = datevec(datenum(endtm));

            pts = pts + eeghdr.npts; % this is the first data point of the next data file
            if isempty(eeghdr.nxtfile)
                break
            end
            eeghdr.FileName = eeghdr.nxtfile;
            a = GetEEGData('readbni');
            if isempty(a)
                break
            end
            i = i+1;
        end
        
    case 'getstartdatetimevec'
        out = eeghdr.PtIndx(1).startdatetimevec;
        
    case 'getenddatetimevec'
        out = eeghdr.PtIndx(end).enddatetimevec;

    case ('getfilename')
        out = [GetName('name', eeghdr.FileName) '.eeg'];
        
    case ('getpathname')
        out = eeghdr.DataPath;
        
    case 'closereq'
        try
          figure(eeghdr.dispH);
          eeghdr.dispH = [];
        end
        closereq;
        
    case 'getchannelfromlabel'
        out = [];
        for i = 1:size(eeghdr.labels, 1)
            if strfind(eeghdr.labels(i,:), data)
                out = i;
                break
            end
        end
        
    case 'getlabelfromchannel'
        out = eeghdr.labels(data,:);
        while 1
            if isspace(out(end))  % remove trailing spaces
                out(end) = [];
            else
                break
            end
        end
        
        
    case 'dticks'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), data/GetEEGData('getrate'));
        eedhdr.display = savedisplay;        
        
    case 'dseconds'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), data);
        eedhdr.display = savedisplay;        

    case 'dminutes'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), 60*data);
        eedhdr.display = savedisplay;        
        
    case 'ticks'
        % will not display data
        savedisplay = eeghdr.display;
        eeghdr.display = 0;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), data/GetEEGData('getrate'));
        eedhdr.display = savedisplay;        
        
    case 'seconds'
        % will not display data
        savedisplay = eeghdr.display;
        eeghdr.display = 0;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), data);
        eedhdr.display = savedisplay;        

    case 'minutes'
        % will not display data
        savedisplay = eeghdr.display;
        eeghdr.display = 0;
        out = GetEEGData(GetEEGData('getstartdatetimevec'), 60*data);
        eedhdr.display = savedisplay;        
        
        
    otherwise
        % action = a datevec, datestr or datenum
        % data = [offset_start_second  number_of_seconds_of_data_to_return]);

        try
            action = datevec(action);
        catch
            return
        end
        % if a date was passed, action is now a datevec

        out = GetEEGData('datetime2tick', action);
        if ~isempty(out)  % if requested time is in this session
            out = GetEEGData('getdata', [out+round(data(1)*eeghdr.rate) round(data(2)*eeghdr.rate)]);

            if eeghdr.display % if display has been toggled on
                
                 % see if there is a current figure, if so save it
                a = findobj('type', 'figure'); 
                if ~isempty(a)
                    b = gcf;
                end
                
                % draw data on eeghdr.dispH figure
                try
                    eeghdr.dispH = figure(eeghdr.dispH);                    
                catch
                    eeghdr.dispH = figure;
                end
                set(eeghdr.dispH, 'CloseRequestFcn', 'GetEEGData closereq');

                if ~isempty(eeghdr.displayspacer)
                    displayspacer = eeghdr.displayspacer;
                else
                    displayspacer = 1.5*max(max(abs(out)));
                end
                for j = 1:size(out,2)
                    d(:,j) = out(:,j) - displayspacer*(j-1);    % offset each channel by 5mV: data is returned in units of uV
                end

                x = 1:size(d,1);
                x = (x + data(1)*GetEEGData('getrate'))/GetEEGData('getrate');
                plot(x,d, 'color', [1 1 0.7]);
                grid on;
                %set(gcf, 'color', );
                set(gca, 'color', [0 0.3 0.3]);
                set(gca, 'xcolor', 'k');
                set(gca, 'ycolor', 'k');
                xa =get(gca, 'ytick');
                ys = num2str(xa(2) - xa(1));
                set(gca, 'yticklabel', '');
                xlabel(['seconds'] );
                ylabel(['grid = ' ys 'uV'] );
                title([GetEEGData('getfilename') '  ' datestr(action)]);
                drawnow
                
                % reset previous current figure if exists
                if ~isempty(a)
                    figure(b);
                end
            end

        end

            
 
end  % main switch
    
    




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



function filestr = sscanfname(filestr,leadstr)

%SSCANFNAME - sscanf function to deal with filenames that include spaces
%   filepath = sscanfname(filestr,leadstr)
%   filestr - string to be parsed
%   leadstr - optional string to be separated
%   example:
%   fname = sscanfname('Filename = c:\dir name\file name.ext','Filename = ')
%   Will return fpath = 'c:\dir name\file name.ext'
%   Normally sscanf cannont handle blanks in the middle of the string so
%        fpath = sscanf('Filename = c:\dir name\file name.ext','Filename = %s')
%   will return the string fpath = 'c:\dir' only
%
%   created: 2/7/03 (sdc)

if nargin < 2, leadstr = []; end

%first replace blanks in strings with dummy char
filestr = strrep(filestr,' ','$');
leadstr = strrep(leadstr,' ','$');
%now parse string with sscanf
leadstr = [leadstr '%s'];
filestr = sscanf(filestr, leadstr);
%now go back and insert blanks
filestr = strrep(filestr, '$',' ');
