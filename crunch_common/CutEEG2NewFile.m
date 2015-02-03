function out = CutEEG2NewFile(starttick, secstocut, OutName);
global eeghdr;

%result = GetEEGData;
%if isempty(result)
%    fprintf('Exiting because no input file was selected.\n');
%end

StartTimeVec = eeghdr.PtIndx(1).startdatetimevec;
StartTimeVec(6) = StartTimeVec(6) + starttick/eeghdr.rate;
StartTimeVec = datevec(datenum(StartTimeVec));

data = GetEEGData('getdata', [starttick secstocut*eeghdr.rate]);
data(:,5) = [];
lab = eeghdr.labels;
lab(end, :) = [];
write2bni([], OutName, eeghdr.rate, StartTimeVec, [], lab, eeghdr.UvPerBit, []);      % open file to write to
write2bni(data');
write2bni([]);


