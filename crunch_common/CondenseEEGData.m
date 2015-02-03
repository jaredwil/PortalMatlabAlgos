function out = CondenseEEGData(OutPath);
global eeghdr;

try
    dp = GetResultsDataPath;
catch
    dp = [];
end
source = [dp '*_Seizures_*.mat'];
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
    return
end

% list of tick times of (approximate) seizure onset;
list = sf.gdf(find(sf.gdf(:,1) == 990),2);  

% try to open at last directory
out = [];
try
    out  = GetEEGData('init', [GetEEGData('getpathname') sf.DataFile]);
end

%open the data file: this will only work if it is in the same place as when analyzed
if isempty(out)
    out  = GetEEGData('init', [sf.DataPath sf.DataFile]);
end
% if the data is not there then you have to as the user to find it
if isempty(out)
	out = GetEEGData;
end
 
if isempty(out)
	fprintf('Aborting because no data file opened.\n');
	return
end

% factor to get the right tick in case the data has been downsampled
inrate = GetEEGData('getrate');
f = inrate/sf.rate; 

list = round(list*f);  % index to the right place
fprintf('Found times of %d seizures\n', length(list));

OutName = [OutPath GetEEGData('getfilename')];
OutName = [OutName(1:end-4) '_szs'];  % add _szs' to the name so it does not overwrite
OutRate = 250;
write2bni([],OutName,OutRate,[eeghdr.starttime eeghdr.ExtraMS],eeghdr.startdate,eeghdr.labels,eeghdr.UvPerBit, eeghdr.avifile);
InitMDFile('init', OutName);

space = zeros(eeghdr.nchan, 250*4);
for i = 1:length(list)
   fprintf('Retreiving data from seizure at %s\n', datestr(GetEEGData('tick2datetimevec', list(i))));
   d = GetEEGData('ticks', [list(i)-60*5*inrate ((60*10)-4)*inrate]);   % get 5 minutes before and 5 minutes after
   for j = 1:size(d,2)
       dd(:,j) = resample(d(:,j), 250, inrate);  % downsample if necessary
   end
   InitMDFile('writeline', (i-1)*10*60*250+1, ['tick:' num2str((list(i)-60*5*inrate)*(250/inrate))]);
   InitMDFile('writeline', (i-1)*10*60*250 + 5*60*250, ['Seizure: ' num2str(i)]);
   write2bni(dd');
   write2bni(space);
end

% close the files
write2bni([]);
InitMDFile('close');
GetEEGData('closedatafile'); % close last input data file
