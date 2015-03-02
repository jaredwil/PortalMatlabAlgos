function out = flatspec(data,rate)

out = log10(pwelch(data,[],[],rate,rate));
fact = 1:length(out);
out = out.*fact';
%out = detrend(10*log10(out), 'linear');)