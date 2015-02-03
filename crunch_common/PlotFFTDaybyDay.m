function out = PlotFFTDaybyDay

out = [];
if isempty(GetEEGData)
    return
end

startday = GetEEGData('getstartdatevec');
startday(3) = startday(3) + 1;          % set the start time to midnight the next day
startday (4:6) = [0 0 0];
startday = datevec(datenum(startday));  % in case we moved to the next month/year in doing this

GetEEGData('limitchannels', 1);
rate = GetEEGData('getrate');

hunk = 10;

% now we just get the data, day by day, until we are out
while 1
    data = GetEEGData('minutes', [0, hunk]);
    fdata = pwelch(data, rate, [], rate, rate);  % init the array with the first data set
    for i = hunk:hunk:(24*60)/hunk % 24 hours of time
        data = GetEEGData('minutes', [i, hunk]);
        fdata = fdata + pwelch(data, rate, [], rate, rate);
    end
   
    for i = 61:60:length(fdata)
        try
            fdata(i-1:i+1) = [];
        end
    end
    plot(fdata'.*(1:length(fdata)).*(1:length(fdata)))
    out = fdata;
    return
end

