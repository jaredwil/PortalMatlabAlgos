function out = GetDateDiff(dfirst,dsecond,units);
%function out = GetDateDiff(dfirst,dsecond,units);
% returns the difference between two datetimes in either h, m or s
% the second variabel should be 'h' or 'm' or 's'
% diff is in seconds
diff = etime(datevec(datenum(dsecond)), datevec(datenum(dfirst)));
if ~exist('units', 'var')
    units = 'h';
end
switch units
    case 'h;
        out = diff/(60*60);
    case 'm'
        out = diff/60;
    case 's'
        out = diff;
end