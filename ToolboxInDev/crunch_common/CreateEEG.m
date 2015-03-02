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
                CreateEEG('setname', [GetEEGData('getpathname') 'new_' GetEEGData('getfilename')]);
                CreateEEG('setrate', GetEEGData('getrate'));
                CreateEEG('setlabels', GetEEGData('getlabels'));
                CreateEEG('setstarttime', GetEEGData('getstartdatevec'));
                CreateEEG('setsensitivity', 1);
                CreateEEG('setfilesize', 500);
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
             %   try
             %       eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels(k,:))));
             %   catch
                    eegfile.montage = strvcat(eegfile.montage,sprintf('%s,,,,,,,EEG',deblank(eegfile.labels{k})));
             %   end
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
%        for k = 1:L,
%            fprintf(fid,'%f\t%d\t%d\tMPEG File Start: %s DeltaStartMs: 0 IframeOffsetMs: 0\n',eegfile.mpginfo(k).starttime,eegfile.mpginfo(k).mpgfile);
%            fprintf(fid,'%f\t%d\t%d\tMPEG File End: %s DeltaEndMs: 0\n',eegfile.mpginfo(k).endtime,eegfile.mpginfo(k).mpgfile);
%        end
        fprintf(fid,'NextFile = %s',eegfile.nextfile);
        fclose(fid);

 
        
        
        
    otherwise
        fprintf('''%s'' is not a defined action\n', action);
end


    
