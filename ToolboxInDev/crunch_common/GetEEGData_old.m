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
%   GetEEGData('getdata',[x1,n])   returns data (points x1 to x1+n-1) from opened file
%   GetEEGData('gettimerange', ['00:00:00', '01:23:34']) returns data in
%       the relative time range passed.  Times must be in the
%       format hr:mn:sc.  Won't currently work if the hour is > 99.

global eeghdr;   % header information of the eeg file
global fltr;

if ~exist('action')
    action = 'init';
end

switch action
    
    case ('init');
        if ~exist('data', 'var')
            source = ['*.eeg'];
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
        eeghdr.fid = [];
        fltr = 0;
        eeghdr.FileName(end-2:end) = 'bni';
        out = GetEEGData('readHeader');
        seeg = eeghdr;
        
        
        if ~isempty(out)
            GetEEGData('indexfileticks',[eeghdr.DataPath eeghdr.FileName]);
            pH = eeghdr.PtIndx;
            eeghdr = seeg;  % reset to data from first file in series
            eeghdr.PtIndx = pH;
            
            GetEEGData('getdata', [0 1]);
            out = eeghdr;
        else
            eeghdr = [];
            out = [];
        end
        
    case('filteron')
        fltr = 1;
        
    case('filteroff')
        fltr = 0;
        
    case('readHeader')
        out = [];
        if strcmp(eeghdr.FileName(end-2:end), 'eeg')
            eeghdr.FileName(end-2:end) = 'bni';
        end
        out = GetEEGData('readbni');
      
        
        
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
        
        if strcmp(eeghdr.FileName(end-7:end-4), '.eeg')
            if size(dir([eeghdr.DataPath eeghdr.FileName(1:end-8) '.bni']),1) == 1
                fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-8) '.bni'], 'r');
            else
                %fprintf('File not found: %s\n', [eeghdr.DataPath eeghdr.FileName(1:end-8) '.bni']);
            end
        else
            if size(dir([eeghdr.DataPath eeghdr.FileName]),1) == 1
                fid = fopen([eeghdr.DataPath eeghdr.FileName], 'r');
            else
                %fprintf('File not found: %s\n', [eeghdr.DataPath eeghdr.FileName]);
            end
        end
        if fid == -1
            % try tag file
            %fprintf('No bni file for: %s\n', [eeghdr.DataPath eeghdr.FileName]);
            %			out = GetEEGData('readtag');
            out = [];
            return
        end
        eeghdr.nxtfile = [];
        while 1,
            line = fgetl(fid);
            if ~isstr(line), break; end
            if ~isempty(findstr('Filename',line))
                eeghdr.fname = sscanfname(line,'Filename = %s');
                eeghdr.fname = deblank(eeghdr.fname);
                eeghdr.fname = GetName('full',eeghdr.fname);
                %eeghdr.fname = eeghdr.fname(1:end-4);
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
            %if ~isempty(findstr('NextFile',line))
            %    eeghdr.nxtfile = sscanf(line,'NextFile = %s');
            %    eeghdr.nxtfile = deblank(eeghdr.nxtfile);
            %    eeghdr.nxtfile = GetName('full',eeghdr.nxtfile);
            %end
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
        %get number of data points
        %if nargin < 2, [pa,fname,ext] = fileparts(fname); datafile = [fname ext]; end
        D = dir(deblank([eeghdr.DataPath eeghdr.FileName(1:end-4)]));
        if size(D,1) ~= 1  % if does not exist as a file
            D = dir(deblank([eeghdr.DataPath eeghdr.FileName(1:end-4) '.eeg']));
            eeghdr.FileName = [eeghdr.FileName(1:end-4) '.eeg.bni'];
        end
        eeghdr.npts = D.bytes;
        eeghdr.npts = eeghdr.npts./(2*eeghdr.nchan);
        tmp = eeghdr.startdate;
        eeghdr.startdate(1) = tmp(3);  % order start date properly!
        eeghdr.startdate(2) = tmp(1);
        eeghdr.startdate(3) = tmp(2);
        out = eeghdr;
        
        
        
    case('opengdfdatafile')
        out = 0;		
        if isempty(eeghdr.gdfDataPath)
            eeghdr.gdfDataPath = eeghdr.DataPath;
        end
        f = dir([eeghdr.gdfDataPath eeghdr.FileName(1:end-4) '*.gdf']);
        if isempty(f)
            source = [eeghdr.gdfDataPath eeghdr.FileName(1:end-4) '*.gdf'];
            FileName = [];
            [FileName, dpath] = uigetfile(source, 'Looking for gdf file');
            if ~(FileName)
                fprintf('No file selected, aborting\n');
                eeghdr.gdf = [];
                return
            end
            f(1).name = FileName;
            eeghdr.gdfDataPath = dpath;
        end
        
        eeghdr.gdf = load([eeghdr.gdfDataPath f(1).name]);
        eeghdr.gdf(:,2) = round(eeghdr.rate*eeghdr.gdf(:,2)/eeghdr.gdf(1,2));
        eeghdr.gdf(1,:) = [];
        out = 1;
        
        
    case('opendatafile')
        GetEEGData('closedatafile');
        switch eeghdr.FileName(end-2:end)
            case 'bni'
                eeghdr.fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4)],'r');
                if eeghdr.fid == -1
                    eeghdr.fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4) '.eeg'],'r');
                end
                %fprintf('Opening file %s\n',[eeghdr.DataPath eeghdr.FileName(1:end-4)]);
            case 'tag'
                eeghdr.fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4) '.eeg'],'r');
        end
        if eeghdr.fid == -1
            %fprintf('File %s not found.\n', [eeghdr.DataPath eeghdr.FileName]);
        end
        out = eeghdr.fid;
        
        
    case('datetime2tick');
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        out = eeghdr.rate*(etime(data, eeghdr.PtIndx(1).startdatetimevec));
        
        
    case('tick2datetime');
        % return the date and time of the tick number passed
        out = [];
        extraticks = [];
        if data < 0 data = 0; end
        
        for i = 1:size(eeghdr.PtIndx,2)
            if eeghdr.PtIndx(i).first > data
                extraticks = data - eeghdr.PtIndx(i-1).first;
                tm = eeghdr.PtIndx(i-1).startdatetimevec;
                break
            end
        end
        if isempty(extraticks) & data <= eeghdr.PtIndx(end).last
            extraticks = data - eeghdr.PtIndx(end).first;
            tm = eeghdr.PtIndx(end).startdatetimevec;
            
        end
        
        if ~isempty(extraticks)
            tm(end) = tm(end) + round(extraticks/eeghdr.rate);
            out = datevec(datenum(tm));
        end
        
        
    case('opennextfile');
        out = -1;
        if isempty(eeghdr.nxtfile)
            fprintf('Reached end of data.\n');
            return
        end
        eeghdr.FileName = [eeghdr.nxtfile '.bni'];
        GetEEGData('readbni');
        eeghdr.fname = eeghdr.FileName(1:end-4);
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
        
        
    case('getgdfdata');
        out = [];
        f = GetEEGData('findfilefromtick', data(1));
        if isempty(f)
            fprintf('Requested data is past end of range.\nValid range is 0 to %d.\n', eeghdr.PtIndx(end).last);
            return
        end
        if GetEEGData('opengdfdatafile') > 0
            out = eeghdr.gdf(find(eeghdr.gdf(:,2) > data(1)-f.first & eeghdr.gdf(:,2) <= sum(data)-f.first),:);
            
            while (sum(data)-f.first) > eeghdr.gdf(end,2)
                if GetEEGData('opennextfile') > 0
                    if GetEEGData('opengdfdatafile') > 0
                        eeghdr.gdf(:,2) = eeghdr.gdf(:,2) + out(end,2);
                        edata = eeghdr.gdf(find(eeghdr.gdf(:,2) <= sum(data)-f.first),:);
                        out = [out; edata];
                    end
                end
            end
        end
        if ~isempty(out)
            out(:,2) = out(:,2) - data(1) + f.first;
        end
        
    case('getdata')
        out = [];
        data = round(data);  % need to be integers
        f = GetEEGData('findfilefromtick', data(1));
        if isempty(f)
            fprintf('Requested data is past end of range.\nValid range is 0 to %d.\n', eeghdr.PtIndx(end).last);
            return
        end
        if isempty(GetEEGData('readbni'))
            return
        end
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
        
        if exist('data')
            eeghdr.FileName = [GetName('name',data) '.bni'];
            eeghdr.DataPath = GetName('path',data);
        end
        if ~exist([eeghdr.DataPath eeghdr.FileName], 'file')
            eeghdr.FileName = [GetName('name',eeghdr.FileName) '.001.bni'];
        end
        GetEEGData('readbni');
        eeghdr.PtIndx = [];
        pts = 0;
        i =1;
        
        while 1
            eeghdr.PtIndx(i).first = pts;
            eeghdr.PtIndx(i).last = pts+eeghdr.npts-1;
            eeghdr.PtIndx(i).name = [eeghdr.DataPath eeghdr.FileName];
            eeghdr.PtIndx(i).startdatetimevec = [eeghdr.startdate eeghdr.starttime];
            endtm = eeghdr.PtIndx(i).startdatetimevec;
            endtm(end) = endtm(end) + round(eeghdr.npts/eeghdr.rate);
            eeghdr.PtIndx(i).enddatetimevec = datevec(datenum(endtm));

            %fprintf('file: %s  first tick: %d\n', eeghdr.FileName(end-7:end-4), pts);
            pts = pts + eeghdr.npts; % this is the first data point of the next data file
            
            if isempty(eeghdr.nxtfile)
                break
            end
            eeghdr.FileName = [eeghdr.nxtfile '.bni'];
            a = GetEEGData('readbni');
            if isempty(a)
                break
            end
            i = i+1;
        end
        
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