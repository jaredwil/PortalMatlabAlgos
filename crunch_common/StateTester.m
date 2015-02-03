function [result, x] = StateTester(d)


secbinsz = 5;
chan = 1;
if ~exist('d', 'var') || isempty(d)
result = zeros(10000, 1);
GetEEGData('limitchannels', chan);
lasttick = GetEEGData('getlasttick');
rate = GetEEGData('getrate');
startdv = GetEEGData('getstartdatevec');
usepassed = 0;
else
    lasttick = length(d);
    rate = 250;
    result = zeros(ceil(lasttick/(rate*secbinsz)),1);
    usepassed = 1;
end

k = 1;
for i = 1:rate*secbinsz:lasttick-1-rate*secbinsz
    if usepassed
        data = d(i:i+rate*secbinsz-1);
    else
        data = GetEEGData('ticks', [i, rate*secbinsz]);
    end
    result(k) = ofeat_Range(data, rate); 
    
    k = k+1;
   if k > length(result)
       break
   end
end

cc = result;
result = smooth(result-1700,15);
result(find(result > 1000)) = NaN;
result = sign(result);

result(k:end) = [];
x = 1:length(result);
%x = x*rate*secbinsz -rate*secbinsz/2;  % x is in seconds
x = x*secbinsz/(60*60);                         % x is in hours

% want to find day-night cycles
x = x + startdv(3) + startdv(4)/60;

plot(x, result); axis tight;
ax = axis;
ax(3) = -2;
ax(4) = 2;
axis(ax);

b = length(find(result > 0))/length(result);
fprintf('percent time in spikey state: %2.1f, percent time in theta state: %2.1f\n', b*100, (1-b)*100);

cc(k:end) = [];
result = cc;