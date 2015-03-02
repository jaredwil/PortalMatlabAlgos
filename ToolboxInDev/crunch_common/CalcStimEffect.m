function CalcStimEffect
GetEEGData;
a = GetEEGData('getMDevents', 'StimON');
if isempty(a)
    fprintf('no StimON mark found! Aborting.\n');
    return
end
startmin = a(1).ticktime/(GetEEGData('getrate')*60);  %time of onset of stim
startmin = startmin + 0.3333333333;  % start 10 seconds after 10 seconds of stim
chans = GetEEGData('getnumberofchannels');
res = zeros(480,chans);
for i = 1:480
    d = GetEEGData('minutes', [startmin 0.5]);  %get 30 seconds of data starting 10 sec after the end of stim
    res(i,:) = sum(abs(diff(d)));
    startmin = startmin+1;
end

plot(res);