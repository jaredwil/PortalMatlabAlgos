function DownSampleEEGtemp(InFile, OutPath, OutRate, chans);
global eeghdr;

InName = GetName('full',InFile);   % file name with extensions
InPath = GetName('path',InFile);   % path

if strcmp(InPath, OutPath)
    fprintf('Source and destination paths cannot be the same. Aborting\n');
    return
end
OutName = [OutPath InName];

%if strcmp(InFile(end-3:end),'.eeg')
%    InFile(end-3:end) = '.bni';
%end

out = GetEEGData('init', InFile);

if isempty(out)
    out = 0;
    return
else
    out = 1;
end

hunk = 500000;

% write to output files
for j = 1:length(eeghdr.PtIndx)
    dat = GetEEGData('getdata',[eeghdr.PtIndx(j).first, hunk]);
    if isempty(dat)
        break
    end
    dat = dat(:, chans);  % only take passed chans
    dat = dat';   
    data = [];
    for k = 1:size(dat,1)
         data(k,:) = resample(double(dat(k,:)), OutRate, eeghdr.rate);
    end
    
    % init output files
    if j == 1
        write2bni([],OutName(1:end-4),OutRate,[eeghdr.starttime eeghdr.ExtraMS],eeghdr.startdate,eeghdr.labels(chans,:),eeghdr.UvPerBit, eeghdr.avifile);
        write2bni(data);
    else
        write2bni(data, 'newfile', OutRate, [eeghdr.starttime eeghdr.ExtraMS],eeghdr.startdate);
    end
    
    for i = eeghdr.PtIndx(j).first+hunk:hunk:eeghdr.PtIndx(j).last
        if i+hunk > eeghdr.PtIndx(j).last
            grab = eeghdr.PtIndx(j).last - i;  % what is left of this file
        else
            grab = hunk;
        end
        dat = GetEEGData('getdata',[i, grab]);
        dat = dat(:, chans);  % only take passed chans
        dat = dat';
        data = [];
        for k = 1:size(dat,1)
            data(k,:) = resample(double(dat(k,:)), OutRate, eeghdr.rate);
        end
        write2bni(data);
    end
    
end

% close files
%write2bni(data, 'newfile', OutRate, [eeghdr.starttime eeghdr.ExtraMS],eeghdr.startdate);
write2bni([]);  % close last output data file
GetEEGData('closedatafile'); % close last input data file

