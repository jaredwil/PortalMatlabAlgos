function [out, rms] = VSD(data, rate, lowfreq, hifreq);
% function [out, rms] = VSD(data, rate, lowfreq, hifreq);
% pass the data (a vector), the rate at which the data was taken,
% the low freq and hig freq range you want to estimate
% the voltage spectral density over.
% returns the voltage spectral density and the rms noise

[p, x] = pwelch(data,length(data),[], rate, rate);
indx = find(x>=lowfreq & x<=hifreq);
out = sqrt(mean(p(indx)));
rms = out/sqrt(hi-lo+1);