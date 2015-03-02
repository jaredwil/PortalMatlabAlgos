function out = GetNonZeroRanges(data)
% function out = GetNonZeroRanges(data)
% returns the start and stop indicies of the non-zero ranges in the vector data
% out is a 2 column vector, the first column indicates the indicie of the
% start of a non-zero range, the second indicates the indicie of the end of
% that range

out = [];
datai = find(data);   % find the indicies of the non-zero elements
if isempty(datai)
    return
end
dataii = find(diff(datai) > 1);
if isempty(dataii)
    out = [datai(1) datai(end)];
    return
end
out = [datai(1) datai(dataii(1))];
for i = 1:length(dataii)-1
    out = [out; [datai(dataii(i)+1) datai(dataii(i+1))]];
end
out  = [out; [datai(dataii(end)+1) datai(end)]];