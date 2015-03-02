function out = SzDuration(startstr, stopstr)

out = [];
if isempty(GetEEGData)
    return
end

rate = GetEEGData('getrate');
list = GetEEGData('getMDevents');

start = zeros(1,length(list));
startinx = 1;
stop = zeros(1,length(list));
stopinx = 1;
for i = 1:length(list)
    if strcmp(startstr, list(i).text)
        start(startinx) = list(i).ticktime;
        startinx = startinx+1;
    elseif strcmp(stopstr, list(i).text)
        stop(stopinx) = list(i).ticktime;
        stopinx = stopinx+1;
    end
    if strcmp('startstim', list(i).text)
        stim =  = list(i).ticktime;
    end
end

try
    before = length(find(start < stim));
catch
    fprintf('No ''startstim'' mark found in md file\n');
end
start = sort(start);
stop = sort(stop);
fprintf('There are %d starts and %d stops\n', length(start), length(stop));
if startinx ~= stopinx
    % then we have some kind of mismatch between number of starts and stops
    fprintf('One or more mismatches between start and stop!\n');
    for i = 1:min(length(start), length(stop))
        if stop(i) - start(i) < 10*rate || stop(i) - start(i) > 3*60*rate
            break
        end
    end
    fprintf('A mismatch exits somewhere near tick %d\n', start(i));
    return
else
    duration = (stop-start)/rate;
    fprintf('\n   Start Tick      Stop Tick      Duration(seconds)\n');
    for i = 1:length(start)
        fprintf('%15d%15d%14.1f\n', start(i), stop(i), duration(i)); 
    end
    fprintf('\nTotal seizure duration %1.2f seconds\n', sum((stop-start)/rate));
end

name = GetEEGData('getfilename');
figure
if exists('before', 'var')    
    subplot(1,2,1);
    hist(duration(1:before, 1:10:200));
    title([name ': Before stim seizure duration (seconds)']);    
    subplot(1,2,2);
    hist(duration(before+1:end, 1:10:200));
    title([name ': During stim seizure duration (seconds)']);    
else
    hist(duration, 1:10:200);
    title([name ': Seizure duration (seconds)']);
end
