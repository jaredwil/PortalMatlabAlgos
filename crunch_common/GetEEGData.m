function [out,  time, gapinfo] = GetEEGData(action, data)
%function out = GetEEGData(action, data);
% edited 26June2009 so output on file open is either 1 for success or 0 for fail
% jgk 21Dec2005
% USAGE:
% initalizing a session:
%   GetEEGData  opens dialogue box to open the eeg file
%   GetEEGData(ID) opens all files assocated with the ID passed, eg, GetEEGData('r108');
%   GetEEGData('init','completepathandfilename')  opens the eeg specified eeg file
%   GetEEGData('nameinit','filename')  opens dialogbox with the passed
%       filename. Use if you want to open a particular eeg session but do not
%       know its path
%
%       the above methods return 0 if the file has not been successfully
%       opened;  1 if the file has been opened successfully
%
%   GetEEGData('getNextSession')  opens the session following the session of the currently
%       opened eeg file.  The next session is assumed to be current session number +1
%       session number should be after the first '_' and end with another
%       '_' or at the extension, ie: r001_000.eeg or r001_001_moreinformation.eeg
%       on success returns out as 1, time as the datevec of the start of the session 
%       and gapinfo as the gap between sessions in seconds. if failed (no next session)
%       returns out as 0
%   GetEEGData('setsession', [ses])  opens the session number passed (ses
%       is a number).  Opens session 0 if ses is not passed.
%       on success returns out as 1, time as the datevec of the start of the session 
%       If failed (no next session) returns out as 0
%
%
% Once a session or ID has been initialized you can do any of the following.
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
%   [data, time, gap] = GetEEGData('getnext')       returns the next hunk of data, the datetimenum of the first
%       data point, and the size of any gap occurring in the data returned.  Uses
%       lastindexaccessed to march through all the data.  Runs across
%       sessions until out of data for the rat, or there is a gap between
%       sessions.  See GetEEGData('resetindex', [session]) and GetEEGData('sethunksize', number_of_seconds)
%       and  GetEEGData('sethunkadvance', number_of_seconds)
%   GetEEGData('resetindex', [session])     resets the index of the
%       lastindexaccessed to start at the beginning of the session number
%       passed.  Starts at the beginning of session 0 if no session number
%       is passed.
%   GetEEGData('settickindex', tick)       sets the tick index for the
%       start of the next getnext call.  Use after resetindex, as
%       resetindex sets the start to 0
% 
%   GetEEGData('sethunksize', number_of_seconds) sets the number of seconds of data to be
%       returned with each GetEEGData('getnext') call.  No default.  Must
%       be set before 'getnext' is used.
%   GetEEGData('sethunkadvance', number_of_seconds) sets the number of
%       seconds to advance after each GetEEGData('getnext') call.  Default is
%       one second.
%   GetEEGData('limitchannels', chans);  limits the channels to be returned
%       to the set passed.  Chans are the column number of the returned
%       data.  Pass 'all' , [], or the entire channel set to get all channels.
%       Default is 'all';
%   GetEEGData('getdatafromsession', [session, ticktime, preseconds, totalseconds])
%       returns the data from the session passed, at ticktime minus
%       preseconds.  returns total seconds of data. returns [] if no such
%       session or otherwise invald.
%
%
% retreiving information about the data:
%   GetEEGData('getfilename')  returns the name of the eeg file, ie 'Data000.eeg'
%   GetEEGData('getTEXfilename') for printing using the TeX editor - for example in titles of figures
%   GetEEGData('getpathname')  returns the path of the eeg file, ie 'C:\data\'
%   GetEEGData('getsession')  returns the number of the session, ie 0 or 10
%   GetEEGData('getrate')  returns the data sampling rate
%   GetEEGData('getlabels')  returns the channel labels
%   GetEEGData('getnumberofchannels')  returns the number of channels
%   GetEEGData('getchannelfromlabel', l)  returns the channel associated with the label l
%   GetEEGData('getlabelfromchannel', c)  returns the label associated with the channel c
%   GetEEGData('getlasttick') returns the number of last data tick in the session
%   GetEEGData('getidentifier') returns the rat ID, for example 'r018'
%   GetEEGData('getsession') returns the session of the last data accessed, as a number
%   GetEEGData('getcagenumber') returns the cage number that the rat was in, if possible, else []
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
%   GetEEGData('getvideotime') returns the datevec associated with the last
%       data point retrieved.  This is the actual time rounded to the
%       nearest second
%   [session, tick] = GetEEGData('datevec2sessionandtick')  passed a datevec, this returns
%       the session and tick value equivalent to the datevec
%       time.  The data files must be opened, ie, it will return [] if you
%       only opened session 2 and the data is in session 1.  So you should
%       open using the animal id for best use of this call.
%
% events:
%   GetEEGData('getMDevents', [str]) returns the events in the associated MD file,
%       limited to the data in str.  Returns all events if list is
%       omitted.  The returned value is a structure with the fields
%       ticktime, channel, channellabel, and text for each event;  Partial matches
%       will be returned.  For example if str = 'seiz' all event markings
%       containing 'seiz' ('seizure', 'noseiz') will be returned. Matching is case
%       sensitive. If a correctly named MD file is not found in the directory of the
%       eeg file, the program will look for a rev file
%    GetEEGData('getAllMDevents' [str])  see 'getMDevents', except this
%       gets the events from all sessions.  Additional fields of session and
%       datevec are in the structure returned.
%    GetEEGData('getstiminfo')  returns the information about any
%    stimulation that has occurred.  Empty if file is missing
%    (IDstiminfo.txt) or no stims have occurred.
%
%
% closing:
%       Open sessions are closed automatically when opening a new session.
%       If you are done and want to close the remaining open data file use
%   GetEEGData('close')
%
%
% utilities:
%   GetEEGData('verifyfiles');
%       prints to the screen the starttime and stop time of the total
%       recording (all sessions).  Also indicates any missing files or sessions, and
%       prints out the size of gaps between sessions





global eeghdr;   % header information of the eeg file
out = 1;         % assume success

if ~exist('action', 'var')
    action = 'init';
end

if isnumeric(action) || isstruct(action)
    %then it might be a datevec or datenum, convert to a datestring for
    %lookup
    an_error = 0;
    try
        action = datenum(action);
    catch
        %   it might be a structure from getMDevents
        if sum(isfield(action,[{'ticktime'},{'channel'},{'channellabel'}, {'text'}])) == 4
            %then change current file to that in the structure (if
            %present) and set the datevect for the event time
            if isfield(action, {'session'})
                if GetEEGData('getsession',1) ~= action.session
                    an_error = ~GetEEGData('setsession', action.session);
                end
                action = datestr(action.datevec);
            else
                % no session field so it is the current session
                action = datestr(GetEEGData('tick2datetime', action.ticktime));
            end

        else
            an_error = 1;
        end
        
    end
    if an_error
        out = 0;
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
        [FileName, DPath] = uigetfile(source, 'Open an eeg file');
        if ~(FileName)
            fprintf('No file selected, aborting\n');
            eeghdr = [];
            out = 0;
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
                fprintf('No file selected, aborting\n');
                eeghdr = [];
                out = 0;
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
        eeghdr.lastindexaccessed = -1;
        eeghdr.lastfileindexaccessed = -1;
        eeghdr.stiminfo = [];
        eeghdr.verbose = 1;
        eeghdr.Sessionstruct = [];
        eeghdr.secwindowadv = 1;
        eeghdr.session = [];

        out = GetEEGData('readbni');
        seeg = eeghdr;  % reset to data from first file in series
        if out
            GetEEGData('indexfileticks');
            pH = eeghdr.PtIndx;
            eeghdr = seeg;  % reset to data from first file in series
            eeghdr.PtIndx = pH;
            eeghdr.actual_rate = eeghdr.PtIndx(end).actualrate;  % last actual_rate is best individual estimate of actual rate
        else
            eeghdr = [];
            out = 0;
            return
        end
        eeghdr.currentindex = 0;
        GetEEGData('opendatafile', 1);
        eeghdr.session = GetEEGData('getsession');
        GetEEGData('getMDevents');   %returns the markings associated with the event

        
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
            out = 0;  % can't find the session number
            return
        end
        newfile(end-2:end) = 'eeg';
        endtime = GetEEGData('getenddatevec');
        if exist(newfile, 'file');
            savedhead = eeghdr.dispH;
            savedisp = eeghdr.display;
            savedispsp = eeghdr.displayspacer;
            savenchan = eeghdr.nchan;
            savelimitchan = eeghdr.limitchans;
            saveverb = eeghdr.verbose;
            saveSS = eeghdr.Sessionstruct;
            savesp = eeghdr.secwindowadv;
            GetEEGData('closedatafile');
            out = GetEEGData('init', newfile);
            if savenchan == eeghdr.nchan
                eeghdr.limitchans = savelimitchan;
            else
                if saveverb
                    fprintf('Number of channels has changed between sessions.  Resetting limitchannels to ''all''\n');
                end
               eeghdr.limitchans = [];
            end
            eeghdr.secwindowadv = savesp;
            eeghdr.Sessionstruct = saveSS;
            eeghdr.display = savedisp;
            eeghdr.displayspacer = savedispsp;
            eeghdr.dispH = savedhead;
            eeghdr.verbose = saveverb;
        else
            out = 0;
        end
        if out
            time = GetEEGData('getstartdatevec');
            gapinfo = etime(GetEEGData('getstartdatevec'),endtime);
            eeghdr.session = GetEEGData('getsession');
        end
   
        
    case 'setsession'
        if ~exist('data', 'var') || isempty(data)
            data = 0;
        end
        % session number should be after the first '_' and end with another
        % '_' or at the extension, ie: r001_000.eeg or r001_001_moreinformation.eeg
        sinx = findstr(eeghdr.FileName, '_');
        einx = findstr(eeghdr.FileName, '.');
        if length(sinx) == 1
            ses = str2double(eeghdr.FileName(sinx(1)+1:einx(1)-1));
            sses = sprintf('%03d', data);
            newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(einx(1):end)];

        elseif length(sinx) > 1
            ses = str2double(eeghdr.FileName(sinx(1)+1:sinx(2)-1));
            sses = sprintf('%03d', data);
            newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(sinx(2):end)];
        else
            if eeghdr.verbose
                fprintf('Can''t find session number: filename %s is in an unknown format!\nAborting setsession.\n', eeghdr.FileName);
            end
            out = 0;  % can't find the session number
            return
        end
        
        newfile(end-2:end) = 'eeg';
        endtime = GetEEGData('getenddatevec');
        if exist(newfile, 'file');
            savedhead = eeghdr.dispH;
            savedisp = eeghdr.display;
            savedispsp = eeghdr.displayspacer;
            savenchan = eeghdr.nchan;
            savelimitchan = eeghdr.limitchans;
            saveverb = eeghdr.verbose;
            saveSS = eeghdr.Sessionstruct;
            savesp = eeghdr.secwindowadv;
            GetEEGData('closedatafile');
            out = GetEEGData('init', newfile);
            if savenchan == eeghdr.nchan
                eeghdr.limitchans = savelimitchan;
            else
                if saveverb
               fprintf('Number of channels has changed between sessions.  Resetting limitchannels to ''all''\n');
                end
               eeghdr.limitchans = [];
            end
            eeghdr.secwindowadv = savesp;
            eeghdr.Sessionstruct = saveSS;
            eeghdr.display = savedisp;
            eeghdr.displayspacer = savedispsp;
            eeghdr.dispH = savedhead;
            eeghdr.verbose = saveverb;
        else
            out = 0;
        end
        if out
            eeghdr.session = GetEEGData('getsession');
            time = GetEEGData('getstartdatevec');            
        end
        
        
    case 'verifyfiles'
        out = 0;
        infiles = 1;   % first file we look for should exist session 0 file eeg
        sinx = findstr(eeghdr.FileName, '_');
        einx = findstr(eeghdr.FileName, '.');
        filelist = zeros(100,3);
        endtime = [];
        maxnpts = 0;
        for ses = 0:99
            if length(sinx) == 1
                sses = sprintf('%03d', ses);
                newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(einx(1):end)];
            else
                sses = sprintf('%03d', ses);
                newfile = [eeghdr.DataPath  eeghdr.FileName(1:sinx(1)) sses eeghdr.FileName(sinx(2):end)];
            end
            % session number set


            bnierror = 0;
            if ~isempty(dir([newfile(1:end-4) '*']))
                databnifilelist = zeros(1001,2);
                for f = -1:999
                    if f < 0
                        eegfile = [newfile(1:end-4) '.eeg'];
                        bnifile = [newfile(1:end-4) '.bni'];
                        % if the extension is not eeg, then we need to append .bni to the file name
                    else
                        fnum = sprintf('%03d', f);
                        eegfile = [newfile(1:end-3) fnum];
                        bnifile = [newfile(1:end-3) fnum '.bni'];
                    end
                    dataexists = ~isempty(dir(eegfile));
                    bniexists = ~isempty(dir(bnifile));

                    if dataexists+bniexists>=1  % file exists
                        % then need to update last found
                        filelist(ses+1, 1) = ses+1;  % this session exists
                        filelist(ses+1, 2) = f+2;  % last complete datafile/bni
                        databnifilelist(f+2,1) = dataexists;
                        databnifilelist(f+2,2) = bniexists;
                    end
                    if bniexists
                        try
                            if isempty(GetEEGData('readbni', eegfile))
                                fprintf('\n     Error reading bnifile %s!', bnifile);
                                bnierror = 1;
                            else
                                maxnpts = max(eeghdr.npts, maxnpts);
                                starttime = [eeghdr.startdate, eeghdr.starttime];
                                if f < 0 && ~isempty(endtime)
                                    secs = etime(starttime,endtime);
                                    if abs(secs/60) > 10
                                        fprintf('        Gap: %1.2f minutes; start of gap: %s\n', secs/60, datestr(endtime));
                                        if lastnpts < maxnpts
                                            fprintf('        Okay.\n')
                                        else
                                            fprintf('        CHECK FOR ADDITIONAL FILES!\n')
                                        end
                                    end
                                else
                                    endtime = starttime;
                                    endtime(6) = endtime(6) + round(eeghdr.npts/eeghdr.rate);
                                    endtime = datevec(datenum(endtime));
                                    lastnpts= eeghdr.npts;
                                end

                            end
                        catch
                            fprintf('\n     Error reading bnifile %s!', bnifile);
                            bnierror = 1;
                        end
                    end
                end
            end

            if filelist(ses+1,1)  % then at least one file from this session exists
                lastpresent = find(databnifilelist(:,1));
                lastbnipresent =find(databnifilelist(:,2));
                lastp = max(lastpresent(end), lastbnipresent(end));
                missingdata = find(~databnifilelist(1:lastp,1));  %Find any zeros
                missingbni = find(~databnifilelist(1:lastp,2));   %Find any zeros
                filelist(ses+1,3) = length(missingdata)+length(missingbni);

                if filelist(ses+1,3)
                    if bnierror; fprintf('\n'); end
                    fprintf('%d Missing files from %s session %s!\n', filelist(ses+1,3),newfile(1:end-8), sses);
                    fprintf('     data:');
                    if ~databnifilelist(1,1)
                        fprintf(' eeg');
                    end
                    fprintf(' %d', find(~databnifilelist(2:lastp,1))-1);
                    fprintf('\n');
                    fprintf('     bni :');
                    if ~databnifilelist(1,2)
                        fprintf(' eeg');
                    end
                    fprintf(' %d', find(~databnifilelist(2:lastp,2))-1);
                    fprintf('\n');
                    if bnierror; fprintf('\n'); end
                else
                    if bnierror; fprintf('\n'); end

                    if lastp-2 < 0
                        last = 'eeg';
                    else
                        last = sprintf('%03d',lastp-2);
                    end
                    fprintf('Session %s: no files missing; last found: %s\n', sses, last);
                    if bnierror; fprintf('\n'); end
                end
            end
        end

        if lastnpts < maxnpts
            fprintf('        Okay.\n')
        else
            fprintf('        CHECK FOR ADDITIONAL FILES!\n')
        end

        % now have a list of all existing sessions and the last file in them
        sessions = find(filelist(:,1));
        missingsessions = find(~filelist(1:sessions(end),2));

        % print out any sessions missing between the first and the last
        % found
        if ~isempty(missingsessions)
            fprintf('Missing Sessions!\n');
            for i = 1:length(missingsessions)
                fprintf('Session %s missing!\n', sprintf('%03d', missingsessions(i)-1));
            end
        end

        endtime = [eeghdr.startdate, eeghdr.starttime];
        endtime(6) = endtime(6) + round(eeghdr.npts/eeghdr.rate);
        endtime = datevec(datenum(endtime));
        fprintf('Recording ends: %s\n\n', datestr(endtime));

        out = 1;

        
    case 'getstiminfo'
        if isempty(eeghdr.stiminfo)
            GetEEGData('readstimfile');
        end
        out = eeghdr.stiminfo;
        
        
    case 'readstimfile'
        eeghdr.stiminfo = [];
        if exist('data', 'var')
            fid = fopen([data 'stiminfo.txt'], 'r', 'l');
        else
            fid = fopen([eeghdr.DataPath GetEEGData('getidentifier') 'stiminfo.txt'], 'r', 'l');
        end
        if fid < 0  % no file
            if eeghdr.verbose
                fprintf('No stimfile found.\n');
            end
            out = 0;
            return
        else
            line = fgetl(fid);
            while 1,
                if ~ischar(line), break; end  % done
                if ~isempty(findstr('stim on:',line))
                    eeghdr.stiminfo(end+1).ontime = datevec(line(9:28));
                    line = fgetl(fid);
                    eeghdr.stiminfo(end).offtime = datevec(line(10:29));
                    line = fgetl(fid);
                    eeghdr.stiminfo(end).params = line(9:end); 
                    line = fgetl(fid);
                    eeghdr.stiminfo(end).comments = [];
                    while ~isempty(line)
                        eeghdr.stiminfo(end).comments{end+1} = line;
                        line = fgetl(fid);
                        if length(line)>7 && ~strcmp('stim on:',line(1:8))
                            break
                        end
                    end
                else
                    line = fgetl(fid);
                end
            end
        end
        out = eeghdr.stiminfo;


    case 'setdisplay'
        eeghdr.display = data;

    case 'setdisplayspacer'
        eeghdr.displayspacer = data;


    case('readbni');
        %  npts - total number of data points
        %  rate - sampling rate
        %  nchan - number of channels
        %  sens - scale factor (uV/bit)
        %  starttime - vector of beginning time of recording [hrs mins secs]
        %  labels - channel labels
        %  nxtfile - filename of next file in sequence
        eeghdr.cagenumber = [];
        if exist('data', 'var')
            eeghdr.DataPath = GetName('path',data);
            eeghdr.FileName = GetName('full',data);
        end
        fid = -1;

        % try to open associated bni file
        try  %will fail for various reasons, so then it is not a valid eegfile
            % if the file has the extension .eeg, then  replace it with .bni
            if strcmp(eeghdr.FileName(end-3:end), '.eeg')
                fid = fopen([eeghdr.DataPath eeghdr.FileName(1:end-4) '.bni'], 'r', 'l');

                % if the extension is not eeg, then we need to append .bni to the file name
            else
                fid = fopen([eeghdr.DataPath eeghdr.FileName '.bni'], 'r', 'l');
            end
        catch
            fid = -1;
        end
        if fid == -1   %bni or eeg file is missing

            %fprintf('No bni file for: %s\n', [eeghdr.DataPath eeghdr.FileName]);
            out = 0;
            return
        end


        % bni file is open so read the information inside
        eeghdr.nxtfile = [];
        while 1,
            line = fgetl(fid);
            if ~ischar(line), break; end
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
            if ~isempty(findstr('Examiner',line)), eeghdr.actual_rate = sscanf(line, 'Examiner = %f Hz'); end
            if ~isempty(findstr('NchanFile',line)), eeghdr.nchan = sscanf(line, 'NchanFile = %d'); end
            if ~isempty(findstr('location',line)), eeghdr.cagenumber = sscanf(line, 'location = %d'); end
            if ~isempty(findstr('UvPerBit',line)) %) & (~exist('sens')),
                if strcmp(line(1:8), 'UvPerBit')
                    eeghdr.UvPerBit = sscanf(line, 'UvPerBit = %f');
                end
            end
            if ~isempty(findstr('MontageRaw',line) & ~exist('labels', 'var')), %#ok<AND2>
                try
                    eeghdr.labels = [];
                    I = findstr(line,',');
                    eeghdr.labels = strvcat(eeghdr.labels,line(14:I(1)-1));
                    for chan = 1:length(I)-1,
                        ind1 = I(chan)+1;
                        ind2 = I(chan+1)-1;
                        eeghdr.labels = strvcat(eeghdr.labels,line(ind1:ind2));
                    end
                catch
                    disp(lasterr);
                end
            end
            txt = line;
            eeghdr.montage = [];
            eeghdr.events = [];
            if ~isempty(findstr('[Events]',txt)),
                nmpg = 0;
                txt = fgetl(fid);
                while isempty(findstr('NextFile',txt)) & ischar(txt) %#ok<AND2>
                    redoline = 0;
                    % find montage settings
                    if ~isempty(findstr('Montage:',txt)),
                        I = findstr('Montage:',txt);
                        txt = txt(I(1):end);
                        I = findstr(txt,'Selected');
                        if ~isempty(I),
                            mtgfmt = 'Montage: Selected Lines: %d';
                            nlines = sscanf(txt,mtgfmt);
                        else
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
                    else
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

        tmp = eeghdr.startdate;
        eeghdr.startdate(1) = tmp(3);  % order start date properly!
        eeghdr.startdate(2) = tmp(1);
        eeghdr.startdate(3) = tmp(2);

        %get number of data points in the data file
        D = dir(deblank([eeghdr.DataPath eeghdr.FileName]));
        try
            eeghdr.npts = D.bytes;
        catch
            eeghdr.npts = 0;
            out = 0;
            return
        end
        eeghdr.npts = eeghdr.npts./(2*eeghdr.nchan);
        if isempty(eeghdr.cagenumber)  % then look to see if we can figure it out from the labels
            if length(eeghdr.labels(1,:)) == 5 && strcmp(eeghdr.labels(1,1:3), 'ch_')
                eeghdr.cagenumber =  round( (str2double(eeghdr.labels(1,4:5))  -1)/4 +1);
            end
        end

        
    case 'getcagenumber'
        out = eeghdr.cagenumber;

        
    case 'opendatafile'
        if data ~= eeghdr.currentindex  % if it is a new file
            GetEEGData('closedatafile');  % close previously open data file, if any
            eeghdr.fid = fopen(eeghdr.PtIndx(data).name,'r', 'l');
            eeghdr.currentindex = data;
        end
        out = (eeghdr.fid > 0);
        if ~out
            fprintf('Error opening file %s!!\n', eeghdr.PtIndx(data).name);
        end

        
    case 'datetime2sessionandtick'
        %returns [session, tick] as out and time.  session = [] if the data
        %is outside the loaded data range
        out = [];
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        d = datenum(data);
        
        if length(eeghdr.Sessionstruct) > 1
        for j = 2:length(eeghdr.Sessionstruct)
            if eeghdr.Sessionstruct(j).PtIndx(1).startdatenum-d > 0
                j = j-1; %#ok<FXSET>
                break
            end
        end
        else
            j = 1;
        end
        
        if length(eeghdr.Sessionstruct(j).PtIndx) > 1
        for i = 2:length(eeghdr.Sessionstruct(j).PtIndx)
            if eeghdr.Sessionstruct(j).PtIndx(i).startdatenum-d > 0
                i = i-1; %#ok<FXSET>
                break
            end
        end
        else
            i = 1;
        end
        
        if ~isempty(eeghdr.Sessionstruct(j).actual_rate)
            r = eeghdr.Sessionstruct(j).PtIndx(i).actualrate;  % if know actual rate
        else
            r = eeghdr.rate;                    % older files don't know actual rate
        end
        time = round(r*etime(data, eeghdr.Sessionstruct(j).PtIndx(i).startdatetimevec)) + eeghdr.Sessionstruct(j).PtIndx(i).first;
        out = j;


    case 'datevec2sessionandsec';
        %    [session, tick] = GetEEGData('datevec2sessionandtick')  passed a datevec, this returns
        %        the session and tick value equivalent to the datevec
        %        time.  The data files must be opened, ie, it will return [] if you
        %        only opened session 2 and the data is in session 1.  So you should
        %        open using the animal id for best use of this call.
        tryi = length(eeghdr.Sessionstruct);
        for i = 1:length(eeghdr.Sessionstruct)
            sec = etime(eeghdr.Sessionstruct(i).sesstart, data);
            if sec > 0
                % if the start of this session is greater than the data
                tryi = i-1;
                break
            end
        end
        if ~tryi
            % then requested data is before first session loaded
            out = -1;
            time = -1;
            return
        end
        sec = etime(data, eeghdr.Sessionstruct(tryi).sesstart);
        lastsec = (eeghdr.Sessionstruct(tryi).lasttick/eeghdr.Sessionstruct(tryi).actual_rate); 
        if sec > lastsec
            % then beyond the end of data of this session
            if tryi == length(eeghdr.Sessionstruct)
                % then the data requested is beyond the data available
                out = -1;
                time = -1;
                return

            else
                % figure out if this is a 'real' gap
                gap = sec-lastsec;
                % if not a real gap then grab the number of seconds from
                % the session before - 
                if gap < 100  % 100 seconds - seom arbitrary smallish number for a non real gap
                    out = eeghdr.Sessionstruct(tryi).session;
                    time = lastsec-gap;   % make it an integral tick
                    return
                end
                % if it is then
                % in a gap
                % out = -1 'cause no data and time tells number of seconds
                % till data again
                out = -1;
                time = etime(eeghdr.Sessionstruct(tryi+1).sesstart, data);
                return
            end
        else
            out = eeghdr.Sessionstruct(tryi).session;
            time = round(sec*eeghdr.rate)/eeghdr.rate;   % make it an integral tick
        end
        
        


    case('datetime2tick');
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        d = datenum(data);
        
        if length(eeghdr.PtIndx) > 1
        for i = 2:length(eeghdr.PtIndx)
            if eeghdr.PtIndx(i).startdatenum-d > 0
                i = i-1; %#ok<FXSET>
                break
            end
        end
        else
            i = 1;
        end
        
        if ~isempty(eeghdr.actual_rate)
            r = eeghdr.PtIndx(i).actualrate;  % if know actual rate
        else
            r = eeghdr.rate;                    % older files don't know actual rate
        end
%        out = round(eeghdr.rate*(etime(data, eeghdr.PtIndx(1).startdatetimevec)))
        out = round(r*etime(data, eeghdr.PtIndx(i).startdatetimevec)) + eeghdr.PtIndx(i).first;
        

    case('tick2datevec');
        % return the date and time of the tick number passed
        for i = 1:length(eeghdr.PtIndx)
            if eeghdr.PtIndx(i).last - data >= 0
                break
            end
        end
        if ~isempty(eeghdr.actual_rate)
            r = eeghdr.PtIndx(i).actualrate;  % if know actual rate
        else
            r = eeghdr.rate;                    % older files don't know actual rate
        end
        secs = (data-eeghdr.PtIndx(i).first)/r;
        out = eeghdr.PtIndx(i).startdatetimevec;
        out(6) = out(6) + secs;
        out = datevec(datenum(out));
        
%        secs = data/eeghdr.rate;
%        out = eeghdr.PtIndx(1).startdatetimevec;
%        out(6) = out(6) + secs;
%        out = datevec(datenum(out));

            
    case 'getactualrate'
        out = eeghdr.actual_rate;
        
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
            starttime = (str2double(st(1:2))*60 + str2double(st(4:5)))*60 + str2double(st(7:8));
            endtime = (str2double(sp(1:2))*60 + str2double(sp(4:5)))*60 + str2double(sp(7:8));
            starttick = round(starttime*eeghdr.rate);
            noticks = round(endtime*eeghdr.rate) - starttick;
            out = GetEEGData('getdata',[starttick, noticks]);

        catch
            fprintf('Invalid time format\n.Aborting\n');
            out = [];
        end

    case 'settickindex'
        eeghdr.lastindexaccessed = data-1;
        
    case 'sethunkadvance'
        eeghdr.secwindowadv = data;
        
    case 'getnext'
        %       returns the next hunk of data.  uses
        %       lastindexaccessed to march through all the data.  Runs across
        %       sessions until out of data for the rat
        %       See GetEEGData('resetindex', [session]) and GetEEGData('sethunksize', number_of_seconds)
        %       and GetEEGData('sethunkadvance', number_of_seconds)
        startsession = GetEEGData('getsession');
        time = datenum(GetEEGData('tick2datevec', eeghdr.lastindexaccessed+1));
        s = eeghdr.verbose;
        eeghdr.verbose= 0;
        out = GetEEGData('ticks', [eeghdr.lastindexaccessed+1 eeghdr.secondhunksize*eeghdr.rate]);
        eeghdr.verbose= s;
        gapinfo = 0;
        if size(out,1) ~= eeghdr.secondhunksize*eeghdr.rate
            points2get = eeghdr.secondhunksize*eeghdr.rate - size(out,1);
            % need more points, so have to see if there is another session
            gapinfo = GetEEGData('getNextSession');
            if isempty(gapinfo)
                return
            end

            if gapinfo > 10*60  % more than 10 minute gap
                fprintf('Large gap between sessions: %1.2f minutes!\n', gapinfo/60);
                out = [out; GetEEGData('ticks', [0 points2get])];
            else
                out = [out; GetEEGData('ticks', [0 points2get])];
            end
        end
        
        % if the session has changed during this call, and we have to back up, then we
        % might have to change the session back
        eeghdr.lastindexaccessed = eeghdr.lastindexaccessed-(eeghdr.secondhunksize-eeghdr.secwindowadv)*eeghdr.rate;
        if eeghdr.lastindexaccessed < 0 && GetEEGData('getsession') ~= startsession
            s = eeghdr.lastindexaccessed;
            GetEEGData('setsession', eeghdr.session-1);
            eeghdr.lastindexaccessed = s+eeghdr.PtIndx(end).last+1;
        end

        
    case 'findsession'
        %returns the session as out (0 to 999).  session = [] if the data
        %is outside the loaded data range
        out = [];
        if length(data) ~=6
            % if not already a datevec, ie, a datenum or datestr
            data = datevec(data);
        end
        d = datenum(data);
        
        % check if request is before the start of the first session
        if d-eeghdr.Sessionstruct(1).PtIndx(1).startdatenum < 0
            return
        end
        
        if length(eeghdr.Sessionstruct) > 1
        for j = 2:length(eeghdr.Sessionstruct)
            if eeghdr.Sessionstruct(j).PtIndx(1).startdatenum-d > 0
                j = j-1; %#ok<FXSET>
                break
            end
        end
        else
            j = 1;
        end
        out = j-1;  % session
%         ?????? this has to be rewirtten
%         % pass a datenum and get the session number that the data is in returned
%         out = [];
%         if ~isempty(eeghdr.Sessionstruct)
%             if datenum(eeghdr.Sessionstruct(1).sesstart) > data
%                 % data is before start of all data
%                 return
%             end
%             for i = 2:length(eeghdr.Sessionstruct)
%              if datenum(eeghdr.Sessionstruct(i).sesstart) > data
%                  out = i-2;
%                  break
%              end
%             end
%         end
        
        
    case 'resetindex'
        %   GetEEGData('resetindex', [session])     resets the index of the
        %       lastindexaccessed to start at the beginning of the session
        %       number
        %       passed.  Starts at the beginning of session 0 if nocc session number
        %       is passed.
        if ~exist('data', 'var') || isempty(data)
            data = 0;
        end
        if ~isempty(GetEEGData('setsession', data))
            eeghdr.lastindexaccessed = -1;
            eeghdr.lastfileindexaccessed = -1;
        else
            fprintf('No such session: %d.  Aborting\n', data);
            out = 0;
        end


    case 'sethunksize'
        eeghdr.secondhunksize = data;



    case('getdata')
        % problem with current code is that if you try to get data from
        % more than two files with one call it will not return the proper
        % data!
        out = [];
        data = round(data);  % need to be integers
        if data(1) < 0 && ~isempty(eeghdr.Sessionstruct)
            % find the previous session            
            for i = 2:length(eeghdr.Sessionstruct)
                if eeghdr.Sessionstruct(i).session == eeghdr.session
                    GetEEGData('setsession', eeghdr.Sessionstruct(i).session-1);
                    data(1) = data(1) + eeghdr.Sessionstruct(i).lasttick+1;
                end
            end
        end
        save = sum(data);    % for keeping track of where we are in the session
        f = GetEEGData('findfilefromtick', data(1));
        if isempty(f) || sum(data)-1 < 0
            if eeghdr.verbose
            fprintf('Requested data [%d to %d] is outside of range.\nValid range is 0 to %10.0d.\n', data(1), sum(data)-1, eeghdr.PtIndx(end).last);
            end
            return
        end
        last = eeghdr.PtIndx(f).last;           % get the first data point in the current file
        first = eeghdr.PtIndx(f).first;         % get the last data point in the current file
        if GetEEGData('opendatafile', f) > 0    % make sure the file still exists and can be opened
            if sum(data) <= last+1              % then all the data is in this data file
                data(1) = data(1) - first;      % get proper offset for this file
                if data(1) < 0                  % check for data request before start of recording
            if eeghdr.verbose
                    fprintf('Requested data is before start of data recording. Returning valid data points.\n');
            end
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
            if eeghdr.verbose
                        fprintf('Requested data is past end of range.\nValid range is 0 to %d.\n', eeghdr.PtIndx(end).last);
                        fprintf('Returning valid data points.\n');
            end
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
                                if eeghdr.verbose

                    fprintf('Requested data (%d to %d) is past end of range\nValid range is 0 to %d.\n', data(1), sum(data)-1, eeghdr.PtIndx(end).last);
                    fprintf('Returning %d valid data points.\n', size(out, 1));
                                end
                end
            end
            eeghdr.lastindexaccessed = min(eeghdr.PtIndx(end).last,save-1);
            eeghdr.lastfileindexaccessed = eeghdr.lastindexaccessed - eeghdr.PtIndx(eeghdr.currentindex).first;
            
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
        if data < 0; data = 0; end  % can't ask for data < 0, returns data from 0

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
            eeghdr.PtIndx(i).startdatenum = datenum(eeghdr.PtIndx(i).startdatetimevec);
            eeghdr.PtIndx(i).actualrate = eeghdr.actual_rate;
            endtm = eeghdr.PtIndx(i).startdatetimevec;
            endtm(end) = endtm(end) + round(eeghdr.npts/eeghdr.rate);
            eeghdr.PtIndx(i).enddatetimevec = datevec(datenum(endtm));
            pts = pts + eeghdr.npts; % this is the first data point of the next data file
            if isempty(eeghdr.nxtfile)
                break
            end
            eeghdr.FileName = eeghdr.nxtfile;
            if ~GetEEGData('readbni')
                break
            end
            i = i+1;
        end
        for i = 2:length(eeghdr.PtIndx)
            dur(i-1) = etime(eeghdr.PtIndx(i).startdatetimevec, eeghdr.PtIndx(i-1).startdatetimevec);
            ticks(i-1) = eeghdr.PtIndx(i-1).last-eeghdr.PtIndx(i-1).first;
            eeghdr.PtIndx(i-1).actualrate = ticks(i-1)/dur(i-1);
        end

        if length(eeghdr.PtIndx) > 1
            eeghdr.PtIndx(end).actualrate = eeghdr.PtIndx(end-1).actualrate;  % guess at the rate for the last one
        else
            eeghdr.PtIndx(end).actualrate = eeghdr.actual_rate;  % guess at the rate for the last one            
        end



        
    case 'readMDfile'
        if isempty(eeghdr.MD)  % then not read yet

            FN = [GetEEGData('getpathname') GetEEGData('getfilename')];
            FN = [FN(1:end-3) 'md']';
            if ~exist(FN, 'file')
  %              [FileName, DPath] = uigetfile(FN, ['Open the MD file to associate with ' GetEEGData('getfilename')]);
  %              if ~(FileName)
                    eeghdr.MD = -1;
                    out = 0;
                    return
  %              else
  %                  FN = [DPath FileName];
  %              end
            end

            % read the events in the md file
            fid = fopen(FN, 'rt');
            i = 1;
            textline = fgetl(fid);
            while 1
                if ~ischar(textline)  % textline == -1 for eof
                    break
                end

                [s,r] = strtok(textline, [',' ' ']);  % read to first ',' delimited str into s, r is the remainder
                eeghdr.MD(i).ticktime = str2double(s); % read the ticktime into the file
                sortticktime(i) = eeghdr.MD(i).ticktime;

                [s,r] = strtok(r, [',' ' ']);  % read channel
                eeghdr.MD(i).channel = str2double(s);

                [s,r] = strtok(r, [',' ' ']);  % read channel label
                eeghdr.MD(i).channellabel = s;

                [s,r] = strtok(r, [',' ' ']);  % read channel mark
                eeghdr.MD(i).text = s;  % read text of the marking


                % get the next line
                textline = fgetl(fid);
                i = i+1;
            end
            fclose(fid);

            % need to sort by time so easy to use later
            if exist('sortticktime', 'var')
            [s, i] = sort(sortticktime, 'ascend');
            else
                out = 0;
            return;
            end
            eeghdr.MD = eeghdr.MD(i);
        end
        try
            if eeghdr.MD == -1  % already searched for a file and couldn't find it
            out = 0;
            return
            end
        catch
            out = eeghdr.MD;
        end

        
    case 'getAllMDevents'
        % returns all the md events in all the available sessions
        out = [];
        if ~exist('data', 'var'); data = []; end
        saveses = GetEEGData('getsession');
        i = 0;
        j = 0;
        more = GetEEGData('setsession', i);
        eeghdr.Sessionstruct = [];
        while more
            if eeghdr.verbose
            fprintf('ses %d: ', i);
            end
            e = GetEEGData('getMDevents', data);
            if isstruct(e)
                if eeghdr.verbose
                fprintf('%d marking(s) found\n', length(e));
                end
                if ~isempty(e)
                out = [out, e];
                end
            else
                if eeghdr.verbose
                fprintf('0 markings found\n');
                end
                e = [];
            end

            eeghdr.Sessionstruct(i+1).sesstart = GetEEGData('getstartdatevec');
            eeghdr.Sessionstruct(i+1).sesend = GetEEGData('getenddatevec');
            eeghdr.Sessionstruct(i+1).marks = e;
            eeghdr.Sessionstruct(i+1).nchan = GetEEGData('getnumberofchannels');
            eeghdr.Sessionstruct(i+1).labels = GetEEGData('getlabels');
            eeghdr.Sessionstruct(i+1).session = GetEEGData('getsession');
            eeghdr.Sessionstruct(i+1).lasttick = eeghdr.PtIndx(end).last;
            eeghdr.Sessionstruct(i+1).PtIndx = eeghdr.PtIndx;  % keep all the timing information
            eeghdr.Sessionstruct(i+1).actual_rate = eeghdr.actual_rate;  % keep all the timing information
            
            i = i+1;
            more = GetEEGData('setsession', i+j);
            if ~more  % skip over 5 sessions looking for the next one
                while ~more
                    j = j+1;
                    more = GetEEGData('setsession', i+j);
                    if j == 5
                        i = i+j;
                        break;
                    end
                end
            end

        end
        % need to get accurate actual_rate for last files of individual
        % sessions, and to fill empty actual_rate fields with resonable
        % estimates
        for i = 1:length(eeghdr.Sessionstruct)
            if isempty(eeghdr.Sessionstruct(i).actual_rate)
                secdur = etime(eeghdr.Sessionstruct(i).sesend,eeghdr.Sessionstruct(i).sesstart);
                eeghdr.Sessionstruct(i).actual_rate = eeghdr.Sessionstruct(i).lasttick/secdur;
            end
        end
        
        GetEEGData('setsession', saveses);

        
    case 'getSessionStruct'
        out = eeghdr.Sessionstruct;
  
        
    case 'displaymarkings'
        save = GetEEGData('getverbose');
        GetEEGData('setverbose', 0);
        a = GetEEGData('getAllMDevents');
        GetEEGData('setverbose', save);
        if isempty(a)
            fprintf('\nNo markings present.\n\n');
            return
        end
        for i = length(a):-1:1
            if isempty(a(i).text)
                a(i) = [];
            end
        end
        for i = 1:length(a)
            b{i} = a(i).text;
        end
        [c,k,j] = unique(b);
        fprintf('\ntext         frequency\n');
        spaces = '                   ';
        for i = 1:length(c)
            ss = 14-length(c{i});
            if ss < 1; ss = 1; end
            fprintf('%s%s%d\n', c{i}, spaces(1:ss), length(find(j == i)));
        end
        fprintf('\n');
       
        
    case 'setverbose'
        if ischar(data)
            if strcmp('on', data)
                eeghdr.verbose = 1;
            else
                eeghdr.verbose = 0;
            end
        else
            eeghdr.verbose = logical(data);
        end
        
        
    case 'getverbose'
        out = eeghdr.verbose;

    case 'parseracine'
        a = findstr(data, '_r');
        if isempty(a); out = []; return;
        else
            out = str2double(data(a(1)+2));  % there should only be one instance of '_r', but if more take the first
        end
        
    case 'parsebehaviors'
        a = findstr(data, '_b');
        out = [];
        if isempty(a); return;            
        else
            inx = a(1)+2;
            while inx < length(data)
                out = [out, str2double(data(inx:inx+1))]; %#ok<AGROW>  % two digit strings 00-99
                inx = inx+2;
                if inx > length(data) || strcmp('_', data(inx))  % if we run into another field separator break
                    break
                end
            end
        end
        
        
      case 'getMDevents'
        out = [];
        %eeghdr.MD is -1 if already looked for and none exist;
        %eeghdr.MD is [] if not looked for yet;
        %eeghdr.MD is a structure if some codes exist;
%        try
%            if eeghrd.MD == -1
%                return
%            end
%        catch
%        end
                
        % returns the ticktimes of the label passed in data
        eeghdr.MD = [];
        if ~isstruct(eeghdr.MD) && ~isempty(eeghdr.MD)
            if ~exist('data', 'var') || isempty(data)
                out = eeghdr.MD;
            else
                k = 1;
                if ischar(data)

                    for i = 1:length(eeghdr.MD)
                        if ~isempty(strfind(eeghdr.MD(i).text, data))
                            out(k).ticktime = eeghdr.MD(i).ticktime;
                            out(k).channel = eeghdr.MD(i).channel;
                            out(k).channellabel = eeghdr.MD(i).channellabel;
                            out(k).text = eeghdr.MD(i).text;
                            out(k).session = eeghdr.MD(i).session;
                            out(k).datevec = eeghdr.MD(i).datevec;
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
                            out(k).session = eeghdr.MD(i).session;
                            out(k).datevec = eeghdr.MD(i).datevec;
                            k = k+1;
                        end
                    end
                end

            end
            return
        end

        if isempty(eeghdr.MD)
            GetEEGData('readMDfile');
        end
        try
            if eeghdr.MD < 0;
                eeghdr.MD = [];
                out = GetEEGData('getREVevents');
            end
        catch
        end

        if isstruct(eeghdr.MD)
        for i = length(eeghdr.MD):-1:1
            if isnan(eeghdr.MD(i).ticktime);
                eeghdr.MD(i) = [];
            else
                eeghdr.MD(i).session = GetEEGData('getsession');
                eeghdr.MD(i).datevec = GetEEGData('tick2datevec', eeghdr.MD(i).ticktime);
                a = findstr(eeghdr.MD(i).text, '_');
                if ~isempty(a)
                    temp = eeghdr.MD(i).text(a(1):end);
                    eeghdr.MD(i).racine = GetEEGData('parseracine', temp);
                    eeghdr.MD(i).behaviors = GetEEGData('parsebehaviors', temp);
                    eeghdr.MD(i).text =  eeghdr.MD(i).text(1:a(1)-1);  % remove any fields separated by '_'
                else
                    eeghdr.MD(i).racine = [];
                    eeghdr.MD(i).behaviors = [];
                end
            end
        end
        end
        
        if ~exist('data', 'var') || isempty(data)
            out = eeghdr.MD;
            return
        end
        if ~isstruct(eeghdr.MD)
            return
        end

        k = 1;
        if ischar(data)
            out = [];
            for i = 1:length(eeghdr.MD)
                if ~isempty(strfind(eeghdr.MD(i).text, data))
                    out(k).ticktime = eeghdr.MD(i).ticktime;
                    out(k).channel = eeghdr.MD(i).channel;
                    out(k).channellabel = eeghdr.MD(i).channellabel;
                    out(k).text = eeghdr.MD(i).text;
                    out(k).session = eeghdr.MD(i).session;                    
                    out(k).datevec = eeghdr.MD(i).datevec;
                    k = k+1;
                end
            end
        else
            out = [];
            for i = 1:length(eeghdr.MD)
                if ~isempty(intersect(eeghdr.MD(i).channel, data))
                    out(k).ticktime = eeghdr.MD(i).ticktime;
                    out(k).channel = eeghdr.MD(i).channel;
                    out(k).channellabel = eeghdr.MD(i).channellabel;
                    out(k).text = eeghdr.MD(i).text;
                    out(k).session = eeghdr.MD(i).session;                    
                    out(k).datevec = eeghdr.MD(i).datevec;
                    k = k+1;
                end
            end
        end


        
    case 'readREVfile'
        if isempty(eeghdr.MD)  % then not read yet

            FN = [GetEEGData('getpathname') GetEEGData('getfilename')];
            FN = [FN(1:end-3) 'rev']';
            if ~exist(FN, 'file')
                eeghdr.MD = -1;
                out = 0;
                return
            end

            % read the events in the md file
            fid = fopen(FN, 'rt');


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
                out = 0;
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
 %           fprintf('No markings available\n');
            out = 0;
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
        data = unique(data);  % get rid of any duplicates
        if isempty(data) || ischar(data) || length(data) >= eeghdr.nchan
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
        
    case 'getTEXfilename'
        % for printinf using the TeX editor -- for example in titles of
        % figures
        % replace '_' with '\_'
        f = eeghdr.FileName;
        sinx = findstr(eeghdr.FileName, '_');
        out = [f(1:sinx(1)-1) '\_'];
        for i =2:length(sinx)
            out = [out f(sinx(i-1)+1:sinx(i)-1) '\_'];
        end
        out = [out f(sinx(end)+1:end)];

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
        catch
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

    case 'getPtIndx'
        out = eeghdr.PtIndx;
        
        
    case 'getdatafromsession'
        % data should be [session, ticktime, preseconds, totalseconds]
        out = [];
        if length(data)~=4; return; end
        if ~GetEEGData('setsession', data(1)); return; end
        out = GetEEGData('seconds', [data(2)/GetEEGData('getrate')-data(3), data(4)]);
        
        
    case 'seconds2ticks'
        % converts seconds from the start of the session to ticks
        dv = GetEEGData('getstartdatevec');
        dv(6) = dv(6) + data;
        out = GetEEGData('datetime2tick', datenum(dv));
                
    case 'ticks2seconds'
        % converts ticks from the start of the session to seconds
        t = GetEEGData('tick2datevec', data);
        out = etime(t, GetEEGData('getstartdatevec'));
        
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
        out = GetEEGData('getdata', [GetEEGData('seconds2ticks', data(1)), GetEEGData('seconds2ticks', data(2))]);

    case 'minutes'
        out = GetEEGData('getdata', [GetEEGData('seconds2ticks', data(1)*60), GetEEGData('seconds2ticks', data(2)*60)]);
        
    case 'getall'
        out = GetEEGData('ticks', [0 GetEEGData('getlasttick')]);

    case 'display_data'
        % draw data on eeghdr.dispH figure
        cf = findobj('tag', 'GetEEGData');
        if isempty(cf)
            eeghdr.dispH = figure('tag', 'GetEEGData','CloseRequestFcn', 'GetEEGData closereq;');
        else
            eeghdr.dispH = cf;
        end
        figure(eeghdr.dispH);
        
        if ~isempty(eeghdr.displayspacer)
            displayspacer = eeghdr.displayspacer;
        else
            displayspacer = 1.5*max(max(abs(data)));
        end
        ytk = [];
        for j = 1:size(data,2)
            d(:,j) = data(:,j) - displayspacer*(j-1);    % offset each channel: data is returned in units of uV
            ytk = [-displayspacer*(j-1) ytk];
        end

        x = 1:size(d,1);
        x = x/GetEEGData('getrate');
%            plot(x,d, 'color', [1 1 0.7]);
%            eeghdr.dispP = gca;
        cf = findobj('tag', 'GetEEGData_data_plot');
        if ~isempty(cf)
            plot(cf,x,d, 'color', [1 1 0.7]);
        else
            plot(x,d, 'color', [1 1 0.7]);
            eeghdr.dispP = gca;
            set(eeghdr.dispP, 'tag', 'GetEEGData_data_plot');
        end

        grid on;
        ax = axis;
        ax(1) = x(1)-0.5;
        ax(2) = x(end)+0.5;
        axis(ax);
        set(gca, 'color', [0 0.3 0.3]);
        set(gca, 'xcolor', 'k');
        set(gca, 'ycolor', 'k');
        xa =get(gca, 'ytick');
        ys = num2str(xa(2) - xa(1));
        set(gca,'ytick', ytk);
        set(gca, 'yticklabel', flipud(GetEEGData('getlabels')));
        xlabel('seconds');
        ylabel(['grid = ' ys 'uV'] );


    otherwise
        % action = a datevec, datestr or datenum or a structure returned
        % from getMDevents
        % data = [offset_start_second  number_of_seconds_of_data_to_return]);
        try
            action = datevec(action);
        catch
            % check to see if an animal ID has been passed
            gotit = 0;
            if length(action) == 4 & ~isempty(str2double(action(2:end))) %#ok<AND2>
                % then it might be an animal id, so try to open it
                for i = 90:-1:67  % start at Z: go to C:
                    if exist('data', 'var') % pass data as a string either '2000' or '250'
                        %                    fprintf('trying %s\n', [char(i) ':\' action '\Hz250\' action '_000.eeg']);
                        if GetEEGData('init', [char(i) ':\' action '\Hz' data '\' action '_000.eeg']);
                            gotit = 1;
                            break
                        end
                        %                    fprintf('trying %s\n', [char(i) ':\' action '\Hz250\h' action(2:end) '_000.eeg']);
                        if GetEEGData('init', [char(i) ':\' action '\Hz' data '\h' action(2:end) '_000.eeg']);
                            gotit = 1;
                            break
                        end
                    else
                        %                    fprintf('trying %s\n', [char(i) ':\' action '\Hz250\' action '_000.eeg']);
                        if GetEEGData('init', [char(i) ':\' action '\Hz250\' action '_000.eeg']);
                            gotit = 1;
                            break
                        end
                        if GetEEGData('init', [char(i) ':\downsampled\' action '_000.eeg']);
                            gotit = 1;
                            break
                        end
                        %                    fprintf('trying %s\n', [char(i) ':\' action '\Hz250\h' action(2:end) '_000.eeg']);
                        if GetEEGData('init', [char(i) ':\' action '\Hz250\h' action(2:end) '_000.eeg']);
                            gotit = 1;
                            break
                        end
                    end
                end
            end
            if ~gotit
                fprintf('Action ''%s'' is not valid for GetEEGData.\nUse ''help GetEEGData'' for a list of valid actions.\n', action);
                out = 0;
                return
            else
                % opened a file by being passed its id, show the codes
                % present
                GetEEGData('displaymarkings');
                return
            end
        end

        % if a date was passed, action is now a datevec
        out = GetEEGData('datetime2tick', action);
        if ~isempty(out)  % if requested time is in this session
            out = GetEEGData('getdata', [out+GetEEGData('seconds2ticks',data(1)) GetEEGData('seconds2ticks', data(2))]);
            if isempty(out)  % if no data returned
                return
            end

            if eeghdr.display % if display has been toggled on
                % see if there is a current figure, if so save it
%                 a = findobj('type', 'figure');
%                 if ~isempty(a)
%                     b = gcf;
%                 end

                GetEEGData('display_data', out);
                if data(1) < 0
                    data(1) = 0;
                end
                                
                dv =GetEEGData('tick2datevec', (GetEEGData('datetime2tick', action)+round(data(1)*eeghdr.rate)));
                title([GetEEGData('getTEXfilename') '  ' datestr(dv)]);
                set(gcf, 'name', datestr(dv));
                drawnow

                % reset previous current figure if exists
%                 if ~isempty(a)
%                     figure(b);
%                 end

            end

        end



end  % main switch






function out = GetName(action, PN)

l = length(PN);

% backup from end until we find '\', the next char is the first of the file name
for i = 1:l-1
    s = l-i;
%    if PN(l-i) == '\'
    if PN(l-i) == filesep
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
