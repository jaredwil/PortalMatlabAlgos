function out = CatEEGFiles

out = 1;
a = GetEEGData('init',[], 'Open the first eeg file');
if isempty(a)
    fprintf('Aborting because no file choosen.\n');
    return
end
CreateEEG('init', 'fromEEG');
while ~isempty(a)
    lastsec = GetEEGData('getlasttick')/GetEEGData('getrate');
    for i = 0:600:lastsec
        data = GetEEGData('seconds', [i,600]);
        CreateEEG('data',data);
    end
    a = GetEEGData('init',[], 'Open the next eeg file - cancel to finish');
end
CreateEEG('close');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

function out = CreateEEG(action, data)
global eegfile;


out = 1;
switch action

    case 'init'
        % here we init the start of a new eegfile, we set defaults so
        % fields will not have to be filled unless choosen
        eegfile = [];
        switch data
            case 'fromEEG'  % make the fields the same as an existing (opened) eeg file
                CreateEEG('setname', [GetEEGData('getpathname') 'cat_' GetEEGData('getfilename')]);
                CreateEEG('setrate', GetEEGData('getrate'));
                CreateEEG('setlabels', GetEEGData('getlabels'));
                CreateEEG('setstarttime', GetEEGData('getstartdatevec'));
                CreateEEG('setsensitivity', 1);
                CreateEEG('setfilesize', 600);
                CreateEEG('setavifile', [eegfile.name(1:end-3) 'avi']);

            otherwise  %pass the name of the file to be made
                CreateEEG('setname', data);
                CreateEEG('setrate', 250);          % default rate
                CreateEEG('setlabels', []);
                CreateEEG('setstarttime', now);     % default starttime of data is now
                CreateEEG('setsensitivity', 1);     % default sensitivity
                CreateEEG('setfilesize', 500);      % default file size in MB
                CreateEEG('setavifile', 'none.avi');

        end
        eegfile.writing = 0;  % we will open the file and do final computations when first data is passed
        eegfile.ExtraMS = 0;   % not used anymore
        
    case 'getstate'
        if isempty(eegfile)
            out = 'closed';
            return
        end
        if eegfile.writing
            out = 'open';
        else
            out = 'closed';
        end
        
    case 'setname'
        eegfile.name = data;
        eegfile.mpginfo(1).mpgfile = [data(1:end-3) 'mpg'];
        eegfile.mpginfo(1).starttime = [];
        eegfile.mpginfo(1).endtime = [];
  
    case 'setrate'
        eegfile.rate = data;

    case 'setlabels'
        eegfile.labels = data;

    case 'setstarttime'
        if length(data) ~=6
            eegfile.starttime = datevec(data);
            eegfile.starttime(6) = round(eegfile.starttime(6));
        else
            eegfile.starttime = data;
        end
        
    case 'setsensitivity'
        eegfile.sensitivity = data;

    case 'setfilesize'
        eegfile.filesize = data;
        
    case 'setavifile'
        eegfile.aviname = data;

    case 'data'
        % data must be in the form rows =timepoints, columns = channels  
        data = int16(data); % data nust be a 16 bit integer
        
        if ~eegfile.writing % this is the first time through so need to open the file and use data to get num of channels
            eegfile.writing = 1;
            if ~strcmp(eegfile.name(end-3:end), '.eeg')  % needs to end in '.eeg'
                eegfile.name = [eegfile.name '.eeg'];
            end
            eegfile.fid = fopen(eegfile.name,'w');
            eegfile.npts = 0;       % no points written so far;
            eegfile.seqnum = 0;     % next data file extension number;
            eegfile.nchans = size(data,2);
            if isempty(eegfile.labels)  % if user has set no labels, make some up
                for i = 1:size(data,2)  % will blow up if more than 999 channels
                    eegfile.labels(i,:) = ['chan' sprintf('%03d',i)];
                end
                eegfile.labels = char(eegfile.labels);
            end
            
            % calculate the second boundary we will stop at
            eegfile.lastpt = floor((eegfile.filesize*1000000)/(eegfile.nchans*2*eegfile.rate));   % convert to number of time points
            eegfile.lastpt = round(eegfile.lastpt*eegfile.rate);    % round because rate might not be an integer                                       
        end

        while ~isempty(data)
        % we write as a loop in case the size of the data passed is larger
        % than the size if the files requested: in that case we loop
        % though several times until all the data is written
            if eegfile.npts + size(data,1) > eegfile.lastpt;
                % then writing this data will put us over the requested
                % file size, so write as many points as are needed to get
                % to the boundary
                timepts2write = eegfile.lastpt - eegfile.npts;  % get numpber of points to boundary
                fwrite(eegfile.fid,data(1:timepts2write,:)','int16');            % write them
                data(1:timepts2write,:) = [];
                eegfile.npts = eegfile.npts + timepts2write;
                CreateEEG('nextfile');                                          % open the next file
            else
                fwrite(eegfile.fid,data','int16');                               % write the data
                eegfile.npts = eegfile.npts + size(data,1);
                data = [];
            end
        end

    case 'nextfile'
        %close the current files
        fclose(eegfile.fid);
        fprintf('File %s created\n', eegfile.name);
        CreateEEG('writebnifile');
        
        %open the next file
        eegfile.name(end-2:end) = sprintf('%03d', eegfile.seqnum);
        eegfile.fid = fopen(eegfile.name,'w');
        eegfile.mpginfo(1).mpgfile = [eegfile.name '.mpg'];
        
        % get time of new data file
        eegfile.starttime(6) = round(eegfile.starttime(6) + (eegfile.npts/eegfile.rate));
        eegfile.starttime = datevec(datenum(eegfile.starttime)); % format the time properly
             
        % set the counters
        eegfile.npts = 0;
        eegfile.seqnum = eegfile.seqnum+1;
        
        
    case 'close'
        eegfile.writing = 0;  % finished writing
        try
            fclose(eegfile.fid);
            fprintf('File %s created\n', eegfile.name);
        catch
        end
      %  try
            CreateEEG('writebnifile');
      %  catch
      %      fprintf('Error creating bni file for %s\n', eegfile.name);                        
      %  end

        
        
    case 'writebnifile'    
        
        % calculate missing fields before writing
        
        
        % get bni filename
        try
        [pa,fn,ext] = fileparts(eegfile.name);
        catch
            return
        end
        if strcmpi(ext,'.eeg'),
            bnifile = fullfile(pa,[fn '.bni']);
        else
            bnifile = fullfile(pa,[fn ext '.bni']);
        end
        
        fprintf('Creating bni file: %s\n', bnifile);
        % create nextfile
        eegfile.nextfile = [eegfile.name(1:end-3) sprintf('%03d', eegfile.seqnum)];
        
        % create montage
        eegfile.montage = [];
        if eegfile.nchans == 1
            %try
            %    eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels(1,:)'))); %#ok<VCAT>
            %catch
                eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels{1})));
            %end
        else
            for k = 1:eegfile.nchans
                try
                    eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels{k})));
                catch
                    eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels(k,:))));
                end
            end
        end
        % create label string
        str = [];
        if iscell(eegfile.labels)
            for k = 1:length(eegfile.labels)
                str = [str deblank(char(eegfile.labels{k})) ',']; %#ok<AGROW>
            end
        else
            for k = 1:size(eegfile.labels,1)
                str = [str deblank(char(eegfile.labels(k,:))) ',']; %#ok<AGROW>
            end
        end
        
        % update avi file name
        [pa,fn,ext] = fileparts(eegfile.aviname);
        eegfile.aviname = fullfile(pa,sprintf('%s.%03d-1.avi',fn(1:end-6),eegfile.seqnum));

        % events
        eegfile.events = [];
        

        % now write to the file
        fid = fopen(bnifile,'w');
        fprintf(fid,'FileFormat = BNI-1\r\n');
        fprintf(fid,'Filename = %s\r\n', eegfile.name);
        fprintf(fid,'Comment = %s\r\n', eegfile.aviname);
        [pa,fn,ext] = fileparts(eegfile.name);
        fprintf(fid,'PatientName = %s\r\n',fn);
        fprintf(fid,'PatientId = \r\n');
        fprintf(fid,'PatientDob = \r\n');
        fprintf(fid,'Sex = \r\n');
        fprintf(fid,'Examiner = \r\n');
        fprintf(fid,'Date = %02d/%02d/%04d\r\n',eegfile.starttime([2 3 1]));
        fprintf(fid,'Time = %02d:%02d:%02d\r\n',eegfile.starttime([4 5 6]));
        fprintf(fid,'Rate = %1.4f Hz\r\n', eegfile.rate);
        fprintf(fid,'EpochsPerSecond = 1\r\n');
        fprintf(fid,'NchanFile = %d\r\n',eegfile.nchans);
        fprintf(fid,'NchanCollected = %d\r\n',eegfile.nchans);
        fprintf(fid,'UvPerBit = %f\r\n',eegfile.sensitivity);
        fprintf(fid,'MontageRaw = %s\r\n',str);
        fprintf(fid,'DataOffset = %d\r\n', eegfile.ExtraMS);
        fprintf(fid,'eeg_number = %s\r\n',fn);
        fprintf(fid,'technician_name = \r\n');
        fprintf(fid,'last_meal = \r\n');
        fprintf(fid,'last_sleep = \r\n');
        fprintf(fid,'patient_state = \r\n');
        fprintf(fid,'activations = \r\n');
        fprintf(fid,'sedation = \r\n');
        fprintf(fid,'impressions = \r\n');
        fprintf(fid,'summary = \r\n');
        fprintf(fid,'age = \r\n');
        fprintf(fid,'medications = \r\n');
        fprintf(fid,'history = \r\n');
        fprintf(fid,'diagnosis = \r\n');
        fprintf(fid,'interpretation = \r\n');
        fprintf(fid,'correlation = \r\n');
        fprintf(fid,'medical_record_number = \r\n');
        fprintf(fid,'location = \r\n');
        fprintf(fid,'referring_physician = \r\n');
        fprintf(fid,'technical_info = \r\n');
        fprintf(fid,'sleep = \r\n');
        fprintf(fid,'indication = \r\n');
        fprintf(fid,'RefName = \r\n');
        fprintf(fid,'DCUvPerBit = 0\r\n');
        fprintf(fid,'[Events]\r\n');
        fprintf(fid,'0.000000\t0\t7	Montage: Selected Lines: %d\n',eegfile.nchans);

        for k = 1:size(eegfile.montage,1),
            fprintf(fid,'%s\n',deblank(eegfile.montage(k,:)));
        end
        for k = 1:size(eegfile.events,1),
            fprintf(fid,'%s\n',deblank(eegfile.events(k,:)));
        end
        L = length(eegfile.mpginfo);
        for k = 1:L,
            fprintf(fid,'%f\t%d\t%d\tMPEG File Start: %s DeltaStartMs: 0 IframeOffsetMs: 0\n',eegfile.mpginfo(k).starttime,eegfile.mpginfo(k).mpgfile);
            fprintf(fid,'%f\t%d\t%d\tMPEG File End: %s DeltaEndMs: 0\n',eegfile.mpginfo(k).endtime,eegfile.mpginfo(k).mpgfile);
        end
        fprintf(fid,'NextFile = %s',eegfile.nextfile);
        fclose(fid);

 
        
        
        
    otherwise
        fprintf('''%s'' is not a defined action\n', action);
end


    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
function out = GetEEGData(action, data, openboxtitle)
%function out = GetEEGData(action, data);
% jgk 21Dec2005
% USAGE:
% initalizing a session:
%   GetEEGData  opens dialogue box to open the eeg file
%   GetEEGData('init','completepathandfilename')  opens the eeg specified eeg file
%   GetEEGData('nameinit','filename')  opens dialogbox with the passed
%       filename. Use if you want to open a particular eeg session but do not
%       know its path
%   GetEEGData('getNextSession')  opens the session following the session of the currently
%       opened eeg file.  The next session is assumed to be current session number +1
%       session number should be after the first '_' and end with another
%       '_' or at the extension, ie: r001_000.eeg or r001_001_moreinformation.eeg
%       on success returns the gap in seconds between sessions, if failed (no next session) returns [] 
%
%
%
% Once a session has been initialized you can do any of the following.
%
% retreiving data:
%       All data is returned in units of uV.  Requests for data outside the
%       range will return data from the portion of the request which is
%       valid, or empty if their is no valid data in the requested range.
%   GetEEGData('getall'); returns all the data (from all the currently non-limited channels)
%   GetEEGData('ticks',[start,n])   returns data (points start to start+n-1) for each channel from opened file
%   GetEEGData('seconds',[start,n])   returns data (seconds start to start+n-1) for each channel from opened file
%   GetEEGData('minutes',[start,n])   returns data (minutes start to start+n-1) for each channel from opened file
%       a 'd' in front of either 'ticks', 'seconds' or 'minutes' returns
%       the data and displays it on a new figure (ie, 'dticks', 'dseconds',
%       or 'dminutes')
%   GetEEGData(date,[offset,n])   returns n seconds of data starting at at date (a datevec,
%       datestr, or datenum) with an offset in seconds (offset)
%   GetEEGData('gettimerange', ['00:00:00', '01:23:34']) returns data in
%       the relative time range passed.  Times must be in the
%       format hr:mn:sc.  Won't currently work if the hour is > 99.
%   GetEEGData('limitchannels', chans);  limits the channels to be returned
%       to the set passed.  Chans ar the column number of the returned
%       data.  Pass 'all' or the entire channel set to get all channels.
%       Default is 'all';
%
%
% retreiving information about the data:
%   GetEEGData('getfilename')  returns the name of the eeg file, ie 'Data000.eeg'
%   GetEEGData('getpathname')  returns the path of the eeg file, ie 'C:\data\'
%   GetEEGData('getsession')  returns the number of the session, ie 0 or 10
%   GetEEGData('getrate')  returns the data sampling rate
%   GetEEGData('getlabels')  returns the channel labels
%   GetEEGData('getnumberofchannels')  returns the number of channels
%   GetEEGData('getchannelfromlabel', l)  returns the channel associated with the label l
%   GetEEGData('getlabelfromchannel', c)  returns the label associated with the channel c
%   GetEEGData('getlasttick') returns the number of last data tick in the session
%
%
% time:
%   GetEEGData('getstartdatevec')  returns the datevec of the start of recording
%   GetEEGData('getenddatevec')  returns the datevec of the end of recording
%   GetEEGData('datetime2tick') returns the tick index number of the passed
%       date (datevec, datestr or datenum).  This can be outside the vaild
%       data range.
%   GetEEGData('tick2datevec') returns the datevec associated with the
%       tick index number passed.  This can be outside the valid data
%       range.
%
% events:
%   GetEEGData('getMDevents', [list]) returns the events in the associated MD file,
%       limited to the data in list.  Returns all events if list is
%       omitted.  The returned value is a structure with the fields
%       ticktime, channel, channellabel, and text for each event;  list can be a list of
%       channel numbers, or a text value.  If a text value partial matches
%       will be returned.  For example if list = 'seiz' all event markings
%       containing 'seiz' ('seizure', 'noseiz') will be returned. Matching is case
%       sensitive. If a correctly named MD file is not found in the directory of the
%       eeg file, a dialog box will be opened for the user to choose which
%       MD file to open.
%
% closing:
%       Open sessions are closed automatically when opening a new session.
%       If you are done and want to close the remaining open data file use
%   GetEEGData('close')



global eeghdr;   % header information of the eeg file
out = 1;

if ~exist('action', 'var')
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
    case('nameinit')
        try
            p = eeghdr.DataPath;
        catch
            p = [];
        end
        source = [p  data];
        FileName = [];
        [FileName, DPath] = uigetfile(source, openboxtitle);
        if ~(FileName)
            out = [];
            fprintf('No file selected, aborting\n');
            eeghdr = [];

            return
        end
        out = GetEEGData('init', [DPath FileName]);



    case ('init');
        if ~exist('data', 'var') | isempty(data)
            try
                p = eeghdr.DataPath;
            catch
                p = [];
            end
            source = [p '*.eeg'];
            FileName = [];
            [FileName, DPath] = uigetfile(source, openboxtitle);
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
        eeghdr.MD = [];
        eeghdr.limitchans = [];

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
            return
        end
        eeghdr.currentindex = 0;
        GetEEGData('opendatafile', 1);


    case 'getNextSession'
        % session number should be after the first '_' and end with another
        % '_' or at the extension, ie: r001_000.eeg or r001_001_moreinformation.eeg
        sinx = findstr(eeghdr.FileName, '_');
        einx = findstr(eeghdr.FileName, '.');
        if length(sinx) == 1
            ses = str2double(eeghdr.FileName(sinx(1)+1:einx(1)-1));
            sses = sprintf('%03d', ses+1);
            newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(einx(1):end)];

        elseif length(sinx) > 1
            ses = str2double(eeghdr.FileName(sinx(1)+1:sinx(2)-1));
            sses = sprintf('%03d', ses+1);
            newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(sinx(2):end)];
        else
            out = [];  % can't find the session number
            return
        end
        newfile(end-2:end) = 'eeg';
        endtime = GetEEGData('getenddatevec');
        if exist(newfile, 'file');
            out = GetEEGData('init', newfile);
        else
            out = [];
        end
        if ~isempty(out)
            out = etime(GetEEGData('getstartdatevec'),endtime);
        end
            
        
    case 'setdisplay'
        eeghdr.display = data;

    case 'setdisplayspacer'
        eeghdr.displayspacer = data;


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
        try  %will fail for various reasons, so then it is not a valid eegfile
            % if the file has the extension .eeg, then  replace it with .bni
            if strcmp(eeghdr.FileName(end-3:end), '.eeg')
                fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4) '.bni'], 'r');

                % if the extension is not eeg, then we need to append .bni to the file name
            else
                fid = fopen([eeghdr.DataPath eeghdr.FileName '.bni'], 'r');
            end
        catch
            fid = -1;
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
                if strcmp(line(1:8), 'UvPerBit')
                    eeghdr.UvPerBit = sscanf(line, 'UvPerBit = %f');
                end
                %if isempty(findstr('DCUvPerBit',line))
                %    fprintf('%2.3f\n', eeghdr.UvPerBit);
                %end
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
                while isempty(findstr('NextFile',txt)) & isstr(txt)
                    redoline = 0;
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
                            % check to see if there really is a montage to read
                            if findstr('MPEG', txt)
                                redoline = 1;
                                break
                            end
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
                        A = sscanf(txt,'%f\t%f\t%d\t%s');
                        eeghdr.mpginfo(nmpg).endtime = A(1:3);
                    else,
                        eeghdr.events = strvcat(eeghdr.events,txt);
                    end
                    if ~redoline
                        txt = fgetl(fid);
                    end
                end
                line = txt;
                if ~isempty(findstr('NextFile',line))
                    %eeghdr.nxtfile = sscanf(line,'NextFile = %s');
                    eeghdr.nxtfile = line(12:end);
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
        if data ~= eeghdr.currentindex  % if it is a new file
            GetEEGData('closedatafile');  % close previously open data file, if any
            eeghdr.fid = fopen(eeghdr.PtIndx(data).name,'r');
            eeghdr.currentindex = data;
        end
        out = (eeghdr.fid > 0);
        if ~out
            fprintf('Error opening file %s!!\n', eeghdr.PtIndx(data).name);
        end


    case('datetime2tick');
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        out = eeghdr.rate*(etime(data, eeghdr.PtIndx(1).startdatetimevec));
        %if out < 0 | out > eeghdr.PtIndx(end).last
        %    out = [];  % data not in this file so return empty;
        %end


    case('tick2datevec');
        % return the date and time of the tick number passed
        secs = round(data/eeghdr.rate);
        out = eeghdr.PtIndx(1).startdatetimevec;
        out(6) = out(6) + secs;
        out = datevec(datenum(out));

    case('getrate')
        out = eeghdr.rate;


    case('opennextfile');
        if eeghdr.currentindex+1 > size(eeghdr.PtIndx,2)
            fprintf('Reached end of data.\n');
            out = 0;
            return
        end
        out = GetEEGData('opendatafile',eeghdr.currentindex+1);



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
        % problem with current code is that if you try to get data from
        % more than two files with one call it will not return the proper
        % data!
        out = [];
        data = round(data);  % need to be integers
        f = GetEEGData('findfilefromtick', data(1));
        if isempty(f) | sum(data)-1 < 0
            fprintf('Requested data [%d to %d] is outside of range.\nValid range is 0 to %10.0d.\n', data(1), sum(data)-1, eeghdr.PtIndx(end).last);
            return
        end
        last = eeghdr.PtIndx(f).last;           % get the first data point in the current file
        first = eeghdr.PtIndx(f).first;         % get the last data point in the current file
        if GetEEGData('opendatafile', f) > 0    % make sure the file still exists and can be opened
            if sum(data) <= last+1              % then all the data is in this data file
                data(1) = data(1) - first;      % get proper offset for this file
                if data(1) < 0                  % check for data request before start of recording
                    fprintf('Requested data is before start of data recording. Returning valid data points.\n');
                    data(2) = sum(data)-1;
                    data(1) = 0;
                end
                if isempty(eeghdr.limitchans)
                    fseek(eeghdr.fid, eeghdr.nchan*(data(1))*2, -1);
                    out = fread(eeghdr.fid,[eeghdr.nchan data(2)],'int16')';
                else
                    for chan = 1:length(eeghdr.limitchans)
                        fseek(eeghdr.fid, eeghdr.nchan*(data(1))*2, -1);
                        status = fseek(eeghdr.fid, (eeghdr.limitchans(chan)*2)-2, 'cof'); % Skip to next channel to be read
                        out(:,chan) = fread(eeghdr.fid, [1, data(2)], 'int16', 2*eeghdr.nchan - 2);
                    end
                end
                out = out*eeghdr.UvPerBit;
            else  % need to get some data from the next file
                extra = sum(data) - last - 1;
                if isempty(eeghdr.limitchans)
                    fseek(eeghdr.fid, eeghdr.nchan*(data(1)-first)*2, -1);
                    out = fread(eeghdr.fid,[eeghdr.nchan data(2)-extra],'int16')';
                else
                    for chan = 1:length(eeghdr.limitchans)
                        fseek(eeghdr.fid, eeghdr.nchan*(data(1)-first)*2, -1);
                        status = fseek(eeghdr.fid, (eeghdr.limitchans(chan)*2)-2, 'cof'); % Skip to next channel to be read
                        out(:,chan) = fread(eeghdr.fid, [1, data(2)-extra], 'int16', 2*eeghdr.nchan - 2);
                    end
                end
                if GetEEGData('opennextfile') > 0
                    if extra > eeghdr.npts
                        extra = eeghdr.npts;
                        fprintf('Requested data is past end of range.\nValid range is 0 to %d.\n', eeghdr.PtIndx(end).last);
                        fprintf('Returning valid data points.\n');
                    end

                    if isempty(eeghdr.limitchans)
                        fseek(eeghdr.fid,0, -1);
                        out = [out; fread(eeghdr.fid,[eeghdr.nchan extra],'int16')'];
                    else
                        for chan = 1:length(eeghdr.limitchans)
                            fseek(eeghdr.fid, 0, -1);
                            status = fseek(eeghdr.fid, (eeghdr.limitchans(chan)*2)-2, 'cof'); % Skip to next channel to be read
                            temp(:,chan) = fread(eeghdr.fid, [1, extra], 'int16', 2*eeghdr.nchan - 2);
                        end
                        out = [out; temp];
                    end
                    out = out*eeghdr.UvPerBit;
                else
                    fprintf('Requested data (%d to %d) is past end of range\nValid range is 0 to %d.\n', data(1), sum(data)-1, eeghdr.PtIndx(end).last);
                    fprintf('Returning %d valid data points.\n', size(out, 1));
                end
            end
        end


    case 'close'
        GetEEGData('closedatafile');

    case('closedatafile')
        try
            fclose(eeghdr.fid);
        catch
        end
        eeghdr.fid = [];



    case('findfilefromtick');
        out = [];
        if data < 0 data = 0; end  % can't ask for data < 0, returns data from 0

        for i = 1:size(eeghdr.PtIndx,2)
            if eeghdr.PtIndx(i).first > data
                out = i-1;
                eeghdr.FileName = GetName('full',eeghdr.PtIndx(i-1).name);
                eeghdr.DataPath = GetName('path',eeghdr.PtIndx(i-1).name);
                return
            end
        end
        if data <= eeghdr.PtIndx(end).last
            out = size(eeghdr.PtIndx,2);
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

    case 'readMDfile'
        if isempty(eeghdr.MD)  % then not read yet

            FN = [GetEEGData('getpathname') GetEEGData('getfilename')];
            FN = [FN(1:end-3) 'md']';
            if ~exist(FN, 'file')
  %              [FileName, DPath] = uigetfile(FN, ['Open the MD file to associate with ' GetEEGData('getfilename')]);
  %              if ~(FileName)
                    eeghdr.MD = -1;
                    return
  %              else
  %                  FN = [DPath FileName];
  %              end
            end

            % read the events in the md file
            fid = fopen([FN], 'rt');
            i = 1;
            textline = fgetl(fid);
            while 1
                if ~ischar(textline)  % textline == -1 for eof
                    break
                end

                [s,r] = strtok(textline, [',' ' ']);  % read to first ',' delimited str into s, r is the remainder
                eeghdr.MD(i).ticktime = str2num(s); % read the ticktime into the file
                sortticktime(i) = eeghdr.MD(i).ticktime;

                [s,r] = strtok(r, [',' ' ']);  % read channel
                eeghdr.MD(i).channel = str2num(s);

                [s,r] = strtok(r, [',' ' ']);  % read channel label
                eeghdr.MD(i).channellabel = s;

                [s,r] = strtok(r, [',' ' ']);  % read channel mark
                eeghdr.MD(i).text = s;  % read text of the marking


                % get the next line
                textline = fgetl(fid);
                i = i+1;
            end
            fclose(fid);

            % need to sort by time so eeasy to use later
            [s, i] = sort(sortticktime, 'ascend');
            eeghdr.MD = eeghdr.MD(i);
        end

        try
            if eeghdr.MD == -1  % already searched for a file and couldn't find it
            out = [];
            return
            end
        catch
            out = eeghdr.MD;
        end


    case 'getMDevents'
        % returns the ticktimes of the label passed in data
        out = [];
        if isempty(eeghdr.MD)
            GetEEGData('readMDfile');
        end
        try
            if eeghdr.MD < 0;
                eeghdr.MD = [];
                out = GetEEGData('getREVevents');
                return
            end
        catch
            if ~exist('data', 'var')
                out = eeghdr.MD;
                return
            end
            k = 1;
            if ischar(data)
                for i = 1:length(eeghdr.MD)
                    if ~isempty(strfind(eeghdr.MD(i).text, data))
                        out(k).ticktime = eeghdr.MD(i).ticktime;
                        out(k).channel = eeghdr.MD(i).channel;
                        out(k).channellabel = eeghdr.MD(i).channellabel;
                        out(k).text = eeghdr.MD(i).text;
                        k = k+1;
                    end
                end
            else
                for i = 1:length(eeghdr.MD)
                    if ~isempty(intersect(eeghdr.MD(i).channel, data))
                        out(k).ticktime = eeghdr.MD(i).ticktime;
                        out(k).channel = eeghdr.MD(i).channel;
                        out(k).channellabel = eeghdr.MD(i).channellabel;
                        out(k).text = eeghdr.MD(i).text;
                        k = k+1;
                    end
                end
            end
        end


    case 'readREVfile'
        if isempty(eeghdr.MD)  % then not read yet

            FN = [GetEEGData('getpathname') GetEEGData('getfilename')];
            FN = [FN(1:end-3) 'rev']';
            if ~exist(FN, 'file')
                eeghdr.MD = -1;
                return
            end

            % read the events in the md file
            fid = fopen([FN], 'rt');


            event = 1;
            textline = fgetl(fid);
            i = 1;
            while 1
                if strcmp(textline, '<event separator>')
                    event = event+1;
                    textline = fgetl(fid);
                end
                if ~ischar(textline)  % textline == -1 for eof
                    break
                end
 
                [s,r] = strtok(textline);  % read first whitespace delimited str into s, r is the remainder
                %s is seconds into the file
                [s,r] = strtok(r);  %#ok<STTOK> %read the second: tick number

                eeghdr.MD(i).ticktime = str2double(s); % read the ticktime into the file
                sortticktime(i) = eeghdr.MD(i).ticktime;

                colons = strfind(r, ':');
                semic = strfind(r, ';');
                eeghdr.MD(i).channellabel = r(colons(1)+1:semic(1)-1);
                eeghdr.MD(i).channel = GetEEGData('getchannelfromlabel', eeghdr.MD(i).channellabel);
                eeghdr.MD(i).text = r(colons(end)+1:end);  % read text of the marking
 
                textline = fgetl(fid);
                i = i+1;
            end
            fclose(fid);

            % need to sort by time so eeasy to use later
            [s, i] = sort(sortticktime, 'ascend');
            eeghdr.MD = eeghdr.MD(i);

        end
        try
            if eeghdr.MD == -1  % already searched for a file and couldn't find it
                out = [];
                return
            end
        catch
            out = eeghdr.MD;
        end



    case 'getREVevents'
        % returns the ticktimes of the label passed in data
        out = [];
        if isempty(eeghdr.MD)
            GetEEGData('readREVfile');
        end
        try 
            if eeghdr.MD < 0;
            fprintf('No markings available\n');
            return
            end
        catch
            if ~exist('data', 'var')
                out = eeghdr.MD;
                return
            end
            k = 1;
            if ischar(data)
                for i = 1:length(eeghdr.MD)
                    if ~isempty(strfind(eeghdr.MD(i).text, data))
                        out(k).ticktime = eeghdr.MD(i).ticktime;
                        out(k).channel = eeghdr.MD(i).channel;
                        out(k).channellabel = eeghdr.MD(i).channellabel;
                        out(k).text = eeghdr.MD(i).text;
                        k = k+1;
                    end
                end
            else
                for i = 1:length(eeghdr.MD)
                    if ~isempty(intersect(eeghdr.MD(i).channel, data))
                        out(k).ticktime = eeghdr.MD(i).ticktime;
                        out(k).channel = eeghdr.MD(i).channel;
                        out(k).channellabel = eeghdr.MD(i).channellabel;
                        out(k).text = eeghdr.MD(i).text;
                        k = k+1;
                    end
                end
            end
            
        end
        
        
        
        
    case 'limitchannels'
        if isempty(data) | ischar(data) | length(data) >= eeghdr.nchan
            eeghdr.limitchans = [];  % empty means do all
        else
            % limit to valid channels
            eeghdr.limitchans = data(find(data <= eeghdr.nchan & data > 0));
        end

    case 'getstartdatevec'
        out = eeghdr.PtIndx(1).startdatetimevec;

    case 'getenddatevec'
        out = eeghdr.PtIndx(end).enddatetimevec;

    case 'getlasttick'
        out = eeghdr.PtIndx(end).last;

    case 'getnumberofchannels'
        out = eeghdr.nchan;

    case ('getfilename')
        out = [GetName('name', eeghdr.FileName) '.eeg'];

    case ('getpathname')
        out = eeghdr.DataPath;
        
    case 'getidentifier'
        sinx = findstr(eeghdr.FileName, '_');
        out =  eeghdr.FileName(1:sinx(1)-1);
        
    case 'getsession'
        % session number should be after the first '_' and end with another
        % '_' or at the extension, ie: r001_000.eeg or r001_001_moreinformation.eeg
        sinx = findstr(eeghdr.FileName, '_');
        einx = findstr(eeghdr.FileName, '.');
        if length(sinx) == 1
            out = str2double(eeghdr.FileName(sinx(1)+1:einx(1)-1));
        elseif length(sinx) > 1
            out = str2double(eeghdr.FileName(sinx(1)+1:sinx(2)-1));
        else
            out = [];  % can't find the session number
        end

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

    case 'getlabels'
        if ~isempty(eeghdr.limitchans)
            out = eeghdr.labels(eeghdr.limitchans,:);
        else
            out = eeghdr.labels;
        end


    case 'dticks'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatevec'), data/GetEEGData('getrate'));
        eedhdr.display = savedisplay;

    case 'dseconds'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatevec'), data);
        eedhdr.display = savedisplay;

    case 'dminutes'
        % inadditon to returning data, will also display data
        savedisplay = eeghdr.display;
        eeghdr.display = 1;
        out = GetEEGData(GetEEGData('getstartdatevec'), 60*data);
        eedhdr.display = savedisplay;

    case 'ticks'
        out = GetEEGData('getdata', data);

    case 'seconds'
        out = GetEEGData('getdata', data*eeghdr.rate);

    case 'minutes'
        out = GetEEGData('getdata', data*eeghdr.rate*60);
        
    case 'getall'
        out = GetEEGData('ticks', [0 GetEEGData('getlasttick')]);


    otherwise
        % action = a datevec, datestr or datenum
        % data = [offset_start_second  number_of_seconds_of_data_to_return]);

        try
            action = datevec(action);
        catch
            fprintf('Action ''%s'' is not valid for GetEEGData.\nUse ''help GetEEGData'' for a list of valid actions.\n', action);
            return
        end
        % if a date was passed, action is now a datevec

        out = GetEEGData('datetime2tick', action);
        if ~isempty(out)  % if requested time is in this session
            out = GetEEGData('getdata', [out+round(data(1)*eeghdr.rate) round(data(2)*eeghdr.rate)]);
            if isempty(out)  % if no data returned
                return
            end

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
                ytk = [];
                for j = 1:size(out,2)
                    d(:,j) = out(:,j) - displayspacer*(j-1);    % offset each channel: data is returned in units of uV
                    ytk = [-displayspacer*(j-1) ytk];
                end

                x = 1:size(d,1);
                if data(1) < 0
                    data(1) = 0;
                end
                x = (x + data(1)*GetEEGData('getrate'))/GetEEGData('getrate');
                plot(x,d, 'color', [1 1 0.7]);
                grid on;
                ax = axis;
                ax(1) = x(1)-1;
                ax(2) = x(end)+1;
                axis(ax);
                %set(gcf, 'color', );
                set(gca, 'color', [0 0.3 0.3]);
                set(gca, 'xcolor', 'k');
                set(gca, 'ycolor', 'k');
                xa =get(gca, 'ytick');
                ys = num2str(xa(2) - xa(1));
                set(gca,'ytick', ytk);
                set(gca, 'yticklabel', flipud(GetEEGData('getlabels')));
                xlabel(['seconds'] );
                ylabel(['grid = ' ys 'uV'] );
                dv =GetEEGData('tick2datevec', (GetEEGData('datetime2tick', action)+round(data(1)*eeghdr.rate)));
                title([GetEEGData('getfilename') '  ' datestr(dv)]);
                set(gcf, 'name', datestr(dv));
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

