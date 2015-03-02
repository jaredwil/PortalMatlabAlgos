function out = CheckFileSize;
global eeghdr;

a = GetEEGData;
if isempty(a)
    return
end


for i = 1:length(eeghdr.PtIndx)
    numpts = eeghdr.PtIndx(i).last - eeghdr.PtIndx(i).first;
    if rem(numpts,eeghdr.rate)
        fprintf('%s data files do not end on a second boundary!\n', GetEEGData('getfilename'));
        return
    end
end
fprintf('No problem.\n');