function jWrite2BNI(data,outname,srate,stime,sdate,labels,sens,avifile)

%WRITE2BNI - Writes data chunk to BNI file
%	Write2BNI(data,outputfilename,sampling_rate,start_time,start_date,labels,sens)
%	data - nchan x npts matrix
%	outputfilename - basename of output file
%	sampling_rate - duh
%	start_time - 1 x 3 vector of clock time at start of file ([hrs mins secs])
%	start_date - 1 x3 vector of date at start of file ([year month day]), use 4 digit year
%	labels - nchan x ? matrix of labels (as strings, use strvcat to create)
%	sens - sensitivity of recording in uV/bit
%
%	USAGE:
%		On first pass, include all input parameters (there are no defaults):
%			Write2BNI(data,outputfilename,sampling_rate,start_time,start_date,labels,sens);
%		On subsequent passes, only input data matrix:
%			Write2BNI(data);
%		On last pass (EOF), input an empty matrix for data
%			Write2BNI([]);

%	CREATED: 5/26/2004 (SDC)
%	MODIFIED: 5/26/2004 (SDC)
%  dramatically changed multiple times by jeff

% use globals so that the file can be kept open until last chunk
global FILEID NPTS SEQNUM OUTFILE FILEHDR OUTFILESIZE

if nargin > 6, %first time through, start new session
    OUTFILESIZE = 2000000000;  % max file size 2 GIG
    outname = [outname '.eeg'];
    OUTFILE = outname;
    FILEID = fopen(outname,'w');
    NPTS = 0;
    SEQNUM = 1;
    % create hdr struct
    FILEHDR = jEEGHdrStruct;
    FILEHDR.rate = srate;
    FILEHDR.nchan = size(labels,1);
    FILEHDR.labels = labels;
    FILEHDR.sens = sens;
    if isempty(sdate)
        FILEHDR.datevec = stime;
        FILEHDR.ExtraMS = 0;
    else
        FILEHDR.datevec = [sdate stime(1:end-1)];
        FILEHDR.ExtraMS = stime(end);
    end
    FILEHDR.datevec = round(datevec(datenum(FILEHDR.datevec)));
    FILEHDR.avifile = avifile;
    FILEHDR.mpginfo(1).starttime = [0 0 26];
    FILEHDR.mpginfo(1).mpgfile = [outname '.mpg'];

elseif isempty(data) & nargin < 2, %close session
    % check to see of we are on a second boundary, if not, add zeros
    a = rem(NPTS, FILEHDR.rate);
    if a % then write data to make an even file: better to have zeros at the end than lose data
        data = zeros(FILEHDR.nchan, (FILEHDR.rate - a));
        NPTS = NPTS +size(data,2);
        fwrite(FILEID,data,'int16');
    end
%fprintf('Points off Boundary: %d\n',rem(NPTS,FILEHDR.rate));
    fclose(FILEID);
    fprintf('File %s created\n', OUTFILE);
    FILEHDR.mpginfo(1).endtime = [NPTS/FILEHDR.rate NPTS 27];
    jWriteBNIHdr;
    clear global FILEID NPTS SEQNUM OUTFILE FILEHDR
    
else, % new chunk for open session
    if ~exist('outname')
        outname = '';
    end
    data = int16(data);

    % check that we haven't written too much and open new file if so
    % and write the header
    if (size(data,2) + NPTS)*FILEHDR.nchan*2 > OUTFILESIZE | strcmp(outname, 'newfile')
        % calculate how many points we are currently from a second boundary
        a = rem(NPTS +size(data,2), FILEHDR.rate);
        if a
            %then we are not on a second boundary, so write enough data
            %points to get to the boundary
            pts2write = FILEHDR.rate - a;
            
            NPTS = NPTS + a;
            fwrite(FILEID,data(:, 1:pts2write),'int16');
            data(:,1:pts2write) = [];  % don't write the same data again in the next file
            
        end
%fprintf('Points off Boundary: %d\n',rem(NPTS,FILEHDR.rate));
        
        fclose(FILEID);
        fprintf('File %s created\n', OUTFILE);
        FILEHDR.mpginfo(1).endtime = [NPTS/FILEHDR.rate NPTS 27];
        jWriteBNIHdr;
        [pa,fn,ext] = fileparts(OUTFILE);
        OUTFILE = fullfile(pa,sprintf('%s.%03d',fn,SEQNUM));
        FILEHDR.mpginfo(1).mpgfile = [OUTFILE '.000.mpg'];
        FILEID = fopen(OUTFILE,'w');
        SEQNUM = SEQNUM + 1;
        
        % change the header datevec
        if ~exist('sdate')
        		FILEHDR.datevec(6) = FILEHDR.datevec(6) + NPTS/FILEHDR.rate;
        		FILEHDR.datevec = round(datevec(datenum(FILEHDR.datevec)));
        else
            if isempty(sdate)
                FILEHDR.datevec = stime;
                FILEHDR.ExtraMS = 0;
            else
                FILEHDR.datevec = [sdate stime(1:end-1)];
                FILEHDR.ExtraMS = stime(end);
            end
        end
        FILEHDR.datevec = round(datevec(datenum(FILEHDR.datevec)));
        NPTS = 0;
    end
    
    
    % either not time to start a new file so just write data, or write the
    % rest of the data to the new file
    NPTS = NPTS + size(data,2);
    fwrite(FILEID,data,'int16');
    nbytes = NPTS*FILEHDR.nchan*2;
    
    
end


function jWriteBNIHdr
global OUTFILE FILEHDR SEQNUM
[pa,fn,ext] = fileparts(OUTFILE);
if strcmp(lower(ext),'.eeg'),
    bnihdrfile = fullfile(pa,[fn '.bni']);
else,
    bnihdrfile = fullfile(pa,[fn ext '.bni']);
end
FILEHDR.nextfile = fullfile(pa,sprintf('%s.%03d',fn,SEQNUM));
FILEHDR.montage = [];
for k = 1:FILEHDR.nchan,
    try
        FILEHDR.montage = strvcat(FILEHDR.montage,sprintf('%s,,,,,,,EEG',deblank(FILEHDR.labels(k,:))));
    catch
        FILEHDR.montage = strvcat(FILEHDR.montage,sprintf('%s,,,,,,,EEG',deblank(FILEHDR.labels{k})));
    end
end
jwritebnihdr(bnihdrfile,OUTFILE,FILEHDR,(1:FILEHDR.nchan)',FILEHDR.labels);
[pa,fn,ext] = fileparts(FILEHDR.avifile);
FILEHDR.avifile = fullfile(pa,sprintf('%s.%03d-1.avi',fn(1:end-6),SEQNUM));



function jwritebnihdr(bnihdrfile,bnifile,hdr,channels,labels)

%jWRITEBNIHDR - writes the bni header file
%  jwritebnihdr(bnihdrfile,bnifile,sdate,stime,rate,nchan,sens,labels,nextfile,events)
global FILEHDR

sdate = hdr.datevec([2 3 1]);
stime = hdr.datevec(4:6);

if nargin < 4, channels = hdr.channels; end
if nargin < 5, labels = hdr.labels; end
nchan = length(channels);

%write bni header file
fid = fopen(bnihdrfile,'w');
fprintf(fid,'FileFormat = BNI-1\r\n');
fprintf(fid,'Filename = %s\r\n',bnifile);
fprintf(fid,'Comment = %s\r\n', FILEHDR.avifile);
[pa,fn,ext] = fileparts(bnifile);
fprintf(fid,'PatientName = %s\r\n',fn);
fprintf(fid,'PatientId = \r\n');
fprintf(fid,'PatientDob = \r\n');
fprintf(fid,'Sex = \r\n');
fprintf(fid,'Examiner = \r\n');
fprintf(fid,'Date = %02d/%02d/%04d\r\n',sdate);
fprintf(fid,'Time = %02d:%02d:%02d\r\n',stime);
fprintf(fid,'Rate = %d Hz\r\n', hdr.rate);
fprintf(fid,'EpochsPerSecond = 1\r\n');
fprintf(fid,'NchanFile = %d\r\n',nchan);
fprintf(fid,'NchanCollected = %d\r\n',nchan);
fprintf(fid,'UvPerBit = %f\r\n',hdr.sens);
str = [];
for k = 1:size(labels,1),
    str = [str deblank(char(labels(k,:))) ','];
    %    str = [str deblank(char(labels{k})) ','];
end
fprintf(fid,'MontageRaw = %s\r\n',str);
fprintf(fid,'DataOffset = %d\r\n', FILEHDR.ExtraMS);
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
fprintf(fid,'0.000000\t0\t7	Montage: Selected Lines: %d\n',nchan);
%if we're clipping eeg, most likely not all the channels are being saved.
%In that case, we only want to save the montages that contain valid channel labels
for k = 1:size(hdr.montage,1),
    if IsLabel(hdr.labels,deblank(hdr.montage(k,:))) | k == size(hdr.montage,1),
        fprintf(fid,'%s\n',deblank(hdr.montage(k,:)));
    end
end
for k = 1:size(hdr.events,1),
    fprintf(fid,'%s\n',deblank(hdr.events(k,:)));
end
L = length(hdr.mpginfo);
for k = 1:L,
    fprintf(fid,'%f\t%d\t%d\tMPEG File Start: %s DeltaStartMs: 0 IframeOffsetMs: 0\n',hdr.mpginfo(k).starttime,hdr.mpginfo(k).mpgfile);
    fprintf(fid,'%f\t%d\t%d\tMPEG File End: %s DeltaEndMs: 0\n',hdr.mpginfo(k).endtime,hdr.mpginfo(k).mpgfile);
end
if ~isstr(hdr.nextfile),
    fprintf(fid,'NextFile = %s.%03d',fn,1);
else,
    fprintf(fid,'NextFile = %s',hdr.nextfile);
end
fclose(fid);

function islbl = IsLabel(labels,txt)
I = findstr(txt,',');
islbl = 0;
if ~isempty(I),
    txt = txt(1:I(1)-1); %got the montage labels
    I = findstr(txt,'-');
    if ~isempty(I), %there are two labels, i.e. bipolar montage
        lbl1 = txt(1:I(1)-1);
        lbl2 = txt(I(1)+1:end);
        for k = 1:size(labels,1),
            if strcmp(deblank(labels(k,:)),lbl1) | strcmp(deblank(labels(k,:)),lbl1), islbl = islbl + 1; end
        end
        islbl = islbl==2;
    else, %only one label, referential
        for k = 1:size(labels,1),
            if strcmp(deblank(labels(k,:)),txt), islbl = 1; end
        end
    end
end



function hdr = jEEGHdrStruct;

%EEGHdrStruct - default structure for EEG files
%       npts - number of data points
%       rate - sampling rate
%       nchan - number of channels
%       sens - sensitivity (uV/bit)
%       stime - start time of file
%       sdate - start date of file
%       labels - channel labels
%       hdrtype - type of header: TAG, BNI, END
%       nextfile - next file in a sequence, if applicable
%       events - annotated events
%       mpgfile - mpeg file, if applicable

%   CREATED: 4/25/2004 (SDC)
%   MODIFIED: 4/26/2004 (SDC)

hdr = struct('npts',[],'rate',[],'nchan',[],'sens',[],'datevec',[],...
    'labels',[],'hdrtype',[],'nextfile',[],'events',[],'mpginfo',[],'hdrbytes',[],'etime',[],'montage',[]);



