function [out, res] = GetRatData(action, data);
global grd;
global eeghdr;


% loads and indexes all the sessions of a rat that are in the same
% directory.
% then you can use just like GetEEGData

if ~exist('action', 'var') | isempty(action)
    action = 'init';
end

switch action
    case 'init'
        if ~exist('data', 'var')
            out = GetEEGData;    % init a file, so we can get
        else
            out = GetEEGData(action, data);
        end

        if ~isempty(out)
            grd = [];
            GetRatData('findandindexfiles');
        end

    case 'findandindexfiles'
        FN = GetEEGData('getfilename');
        inx = findstr(FN, '_');
        grd.RatID = FN(1:inx(1)-1);

        % find all the stuff after the session number: this has to be the
        % same
        if length(inx) == 1
            einx = findstr(FN, '.');
            grd.extraname = FN(einx(1):end);
        elseif length(inx) > 1
            grd.extraname = FN(inx(2):end);
        else
            grd.extraname = [];  % can't find the session number
        end

        % we have the rat ID we want to use this to find all the sessions,
        % for each session, we will save information from each data file getting the list
        % from eeghdr

        % only want sessions that are at the same rate!
        grd.rate = GetEEGData('getrate');
        grd.nchans  = GetEEGData('getnumberofchannels');


        grd.SessionList = [];
        %this should not be empty, since the file we loaded should be here


        % now lets assume that this data may be in a subdirectory, and other
        % subdirectories may hold more sessions

        % find the parent directory (if it exists)
        PN = GetEEGData('getpathname');
        inx = findstr(PN, '\');     % assume a PC
        if length(inx > 1)          % then we are in a sub directory since PN will always end in '\'
            rootPath = PN(1:inx(end-1));
            a = dir(rootPath);
            for j = 1:length(a)
                if a(j).isdir           % if it is a dir then look inside for data
                    testPN = [rootPath a(j).name '\'];
                    b = dir([testPN grd.RatID '_*' grd.extraname]);
                    for i = 1:length(b)
                        % open each file on the list
                        out = GetEEGData('init', [testPN b(i).name]);

                        if ~isempty(out) & grd.rate == GetEEGData('getrate')  % if valid and same rate add to list
                            sesno = GetEEGData('getsession', a(i).name)+1;
                            grd.SessionList(sesno).seshdr = eeghdr;
                            grd.SessionList(sesno).FileName = [GetEEGData('getpathname') GetEEGData('getfilename')];
                        end
                    end
                end
            end

        else    % then there is no subdirectory, so just look in this directory
            % first look in the current directory for all RatID * .eeg files
            b = dir([PN grd.RatID '_*' grd.extraname]);

            for i = 1:length(b)
                % open each file on the list
                out = GetEEGData('init', [PN b(i).name]);

                if ~isempty(out) & grd.rate == GetEEGData('getrate')  % if valid and same rate add to list
                    sesno = GetEEGData('getsession', b(i).name);
                    grd.SessionList(sesno).seshdr = eeghdr;
                end
            end
        end


        % run though the sessions to find the start and stop second indexes
        % for each seession
        first = 1;
        for i = 1:length(grd.SessionList)
            if ~isempty(grd.SessionList(i).seshdr)
                if first
                    grd.SessionList(i).startsec = 0;
                    grd.SessionList(i).endsec = grd.SessionList(i).seshdr.npts/grd.rate;
                    startdv = grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec;
                    first = 0;
                else
                    grd.SessionList(i).startsec = etime(grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec, startdv);
                    grd.SessionList(i).endsec = grd.SessionList(i).seshdr.npts/grd.rate + grd.SessionList(i).startsec;
                end

                grd.SessionList(i).session = i-1;
            end

        end

        % we should have found at least the session that was clicked on to
        % start the process.

        GetRatData('setverbose', 1);
        GetRatData('printsessionsfound');
        fprintf('\n');

        % get rid of empty sessions
        for i = length(grd.SessionList):-1:1
            if isempty(grd.SessionList(i).seshdr)
                grd.SessionList(i) = [];
            end
        end

        % set gap size in seconds
        grd.SessionList(1).gap = 0;
        for i = 2:length(grd.SessionList)
            grd.SessionList(i).gap = grd.SessionList(i).startsec - grd.SessionList(i-1).endsec;
            if grd.SessionList(i).gap < 2
                grd.SessionList(i).gap = 0;
            end

        end


        GetRatData('setlimitchannels', 'all');
        GetRatData('setstartenddatevec');  % also resets current session to the first valid session
        GetRatData('setstart', grd.startdatevec);
        GetRatData('setstop', grd.enddatevec);
        GetRatData('setblocksize', 1);
        out = length(grd.SessionList);


    case 'gettotalblocks'
        out = ceil((grd.SessionList(end).endsec+1)/grd.sechunk);
        out = (grd.stopsec - grd.startsec)/grd.sechunk;
        
    case 'gettotaldatablocks'
        i = 1;
        while grd.SessionList(i).endsec < grd.startsec
            i = i+1;
        end
        
            
        startstoplist(1,1) = grd.startsec - grd.SessionList(i).startsec;
        startstoplist(1,2) = grd.SessionList(i).endsec;
        j = 1;
        for k = 2:length(grd.SessionList);
            if ~grd.SessionList(k).gap
              startstoplist(j,2) = grd.SessionList(k).endsec;               
            else
              j = j+1;
              startstoplist(j,2) = grd.SessionList(k).endsec;
              startstoplist(j,1) = grd.SessionList(k).startsec;
            end
            
        end
        
        % now have merged all sessions without gaps, so look how many
        % blocks are needed
        out = 0;
        for i = 1:size(startstoplist,1);
            if startstoplist(j,2) >= grd.stopsec
                out = out+ceil((startstoplist(i,2)-startstoplist(i,1))/grd.sechunk);
            else
                out = out+ceil((grd.stopsec-startstoplist(i,1))/grd.sechunk);
                break
            end
        end
        %startstoplist
        
    case 'setverbose'
        grd.verbose = data;
        if grd.verbose
            fprintf('\tSet verbose to on.\n');
        else
            fprintf('\tSet verbose to off.\n');
        end

    case 'setstartenddatevec';
        for i = 1:length(grd.SessionList)
            if ~isempty(grd.SessionList(i).seshdr)
                grd.startdatevec = grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec;
                break
            end
        end
        grd.enddatevec = grd.SessionList(end).seshdr.PtIndx(end).enddatetimevec;


    case 'printsessionsfound'
        if isempty(grd.SessionList) return; end
        spacer1 = ' ';
        for j = 1:length(GetEEGData('getfilename'))-7
            spacer1 = [spacer1  ' '];
        end
        spacer2 = ' ';
        for j = 1:length(GetEEGData('getpathname'))-3
            spacer2 = [spacer2  ' '];
        end

        gap = '         ';
        stop = [];
        fprintf('\nRatID: %s     Rate: %dHz     Channels: %d\n', grd.RatID, round(grd.rate), grd.nchans);
        fprintf('\n\tses  filename%spath%s gap         start                  stop                   duration\n', spacer1, spacer2);
        for i = 1:length(grd.SessionList)
            if isempty(grd.SessionList(i).seshdr)
                fprintf('\t%03d   <    >\n', i-1);
            else
                start = grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec;
                if ~isempty(stop)
                    h = floor(etime(start, stop)/(60*60));
                    m = floor(etime(start, stop)/60 - h*60);
                    s = floor(etime(start, stop) - h*60*60 - m*60);
                    gap = sprintf('%03d:%02d:%02d', h,m,s);
                end
                stop = grd.SessionList(i).seshdr.PtIndx(end).enddatetimevec;
                h = floor(etime(stop, start)/(60*60));
                m = floor(etime(stop, start)/60 - h*60);
                s = floor(etime(stop, start) - h*60*60 - m*60);
                duration = sprintf('%03d:%02d:%02d', h,m,s);


                fprintf('\t%03d  %s  %s   %s   %s   %s   %s\n', i-1, grd.SessionList(i).seshdr.fname, grd.SessionList(i).seshdr.DataPath, gap, datestr(start), datestr(stop), duration );
            end
        end


    case('setlimitchannels')
        if isempty(data) | ischar(data) | length(data) >= grd.SessionList(grd.currentsessionindx).seshdr.nchan
            grd.limitchannels = [];  % empty means do all
            if grd.verbose
                fprintf('\tSet active channels to ALL.\n');
            end

        else
            % limit to valid channels
            grd.limitchannels = data(find(data <= grd.SessionList(grd.currentsessionindx).seshdr.nchan & data > 0));
            if grd.verbose
                fprintf('\tSet active channels to');
                fprintf(' %d', grd.limitchannels);
                fprintf('\n');
            end
        end
        try   % if there is a file already open then limit its channels
            GetEEGData('limitchannels', grd.limitchannels);
        end

        
    case 'setsession'
        GetRatData('setstart', data);
        GetRatData('setstop', data);
        
    case('setblocksize');
        grd.sechunk = data;
        grd.ptshunk = grd.rate*grd.sechunk;
        if grd.verbose
            fprintf('\tSet data block size to %3.1f seconds\n', grd.sechunk);
        end


    case('setstart')
        out = 0;
        if size(data,2) ~= 6
            if isnumeric(data) & data < 100
                % then we think it is a session number, so start at the
                % beginning of that session
                try
                    for i = 1:length(grd.SessionList)
                        if grd.SessionList(i).session == data
                            grd.currenttime = grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec;
                            
                            break
                        end
                    end
                catch
                    return  % failed so just exit
                end
            end
            try  % now we think it is either a datestr or a datenum
                grd.currenttime = datevec(data);
            catch
                return  % failed so just exit
            end
        else

        try
            grd.currenttime = datevec(datestr(data));
        end
        end
        grd.starttime = round(grd.currenttime);
        grd.currenttime = etime(grd.starttime, grd.startdatevec);
        grd.startsec = grd.currenttime;
        if grd.verbose
            fprintf('\tSet start time to %s\n', datestr(grd.starttime));
            fprintf('\tSet pointer to %d seconds\n', grd.currenttime);
        end

        [grd.currentsessionindx, grd.secoffset]  = GetRatData('findsessionfromtime', grd.starttime);
        GetEEGData('init', grd.SessionList(grd.currentsessionindx).FileName );
        GetEEGData('limitchannels', grd.limitchannels);

        out = 1;

    case('setstop')
        out = 0;
        if size(data,2) ~= 6
            if isnumeric(data) & data < 100
                % then we think it is a session number, so start at the
                % beginning of that session
                try
                    for i = 1:length(grd.SessionList)
                        if grd.SessionList(i).session == data
                            grd.stoptime = grd.SessionList(i).seshdr.PtIndx(end).enddatetimevec;
                            
                            break
                        end
                    end
                catch
                    return  % failed so just exit
                end
            end
            try  % now we think it is either a datestr or a datenum
                grd.stoptime = datevec(data);
            catch
                return  % failed so just exit
            end
        else
        try
            grd.stoptime = datevec(datestr(data));
        end
        end
        grd.stoptime = round(grd.stoptime);
        grd.stopsec  = etime(grd.stoptime, grd.startdatevec);
        if grd.verbose
            fprintf('\tSet stop time to %s\n', datestr(grd.stoptime));
        end

        out = 1;


    case('findsessionfromtime')  % returns the session and second offset from a passed time
        d = datenum(data);
        for i = 1:length(grd.SessionList)
            if ~isempty(grd.SessionList(i).seshdr)
                if d < datenum(grd.SessionList(i).seshdr.PtIndx(end).enddatetimevec);
                    out = i;
                    res = etime(data, grd.SessionList(i).seshdr.PtIndx(1).startdatetimevec);
                    return
                end
            end
        end
        %past end of data for this rat, return the last
        out = i;
        res = etime(d, datenum(grd.SessionList(end).seshdr.PtIndx(end).startdatetimevec));


    case 'getnext'
        % get the data
        res = grd.currenttime;
        if grd.currenttime > grd.stopsec
            out = [];
            return
        end
        out = GetEEGData('seconds', [grd.secoffset, grd.sechunk]);

        % increment pointer
        grd.secoffset = grd.secoffset+grd.sechunk;
        grd.currenttime = grd.currenttime+grd.sechunk;

        % return the current second into the rat's data

        % if no data then we should jump to the next session
        if isempty(out)
            try     % try to go to the next session, if none, nothing will happen
                grd.currentsessionindx = grd.currentsessionindx+1;
                GetEEGData('init', grd.SessionList(grd.currentsessionindx).FileName );
                %fprintf('opened file %s\n', grd.SessionList(grd.currentsessionindx).FileName);
                GetEEGData('limitchannels', grd.limitchannels);
                grd.currenttime = grd.SessionList(grd.currentsessionindx).startsec;
                grd.secoffset = 0;
            end
            return
        end


        %if data is too small then need more: check to see if there is
        %a gap-free next session, if we are in a gap, or if we are at
        %the end of the data
        if size(out,1) ~= grd.ptshunk
            % if no gap then just go to the next session
            if ~grd.SessionList(grd.currentsessionindx+1).gap
                grd.currentsessionindx = grd.currentsessionindx+1;
                GetEEGData('init', grd.SessionList(grd.currentsessionindx).FileName );
                %fprintf('opened file %s\n', grd.SessionList(grd.currentsessionindx).FileName);
                GetEEGData('limitchannels', grd.limitchannels);
                out = [out; GetEEGData('ticks', [0, grd.ptshunk-size(out,1)])];
                grd.secoffset = round((grd.ptshunk-size(out,1))/grd.rate);
                grd.currenttime = grd.SessionList(grd.currentsessionindx).startsec + grd.secoffset;
            end
        end

    otherwise

end