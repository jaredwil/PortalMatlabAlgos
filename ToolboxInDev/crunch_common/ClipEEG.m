function ClipEEG(InFile, OutPathFileName, StartDTVec, StopDTVec);
global eeghdr;

if ~isempty(InFile)
    InName = GetName('full',InFile);   % file name with extensions
    InPath = GetName('path',InFile);   % path
    out = GetEEGData('init', InFile);
    if isempty(out)
        out = 0;
        fprintf('No file %s found.\n', InFile);
        return
    else
        out = 1;
    end
else
    InName = GetEEGData('getfilename');
    InPath = GetEEGData('getpathname');
end

if strcmp(InPath, OutPathFileName)
    fprintf('Source and destination paths cannot be the same. Aborting\n');
    return
end
OutName = OutPathFileName;



hunk = 50000;

starttick = GetEEGData('datetime2tick', StartDTVec);
stoptick = GetEEGData('datetime2tick', StopDTVec);


% write to output files
data = GetEEGData('getdata',[starttick, hunk]);
write2bni([],OutName(1:end-4),eeghdr.rate,StartDTVec,[],eeghdr.labels,eeghdr.UvPerBit, eeghdr.avifile);
write2bni(data');
for i = starttick+hunk:hunk:stoptick
    if i+hunk > stoptick
        grab = stoptick - i;  % what is left of this file
    else
        grab = hunk;
    end
    data = GetEEGData('getdata',[i, grab]);
    write2bni(data');
end

% close files
%write2bni(data, 'newfile', OutRate, [eeghdr.starttime eeghdr.ExtraMS],eeghdr.startdate);
write2bni([]);  % close last output data file
GetEEGData('closedatafile'); % close last input data file

