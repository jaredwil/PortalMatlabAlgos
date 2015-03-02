function notcheddata = iirn(data,rate, fc)

wo = 2*fc/rate;
[b, a] = iirnotch(wo, wo/200);
notcheddata = filtfilt(b,a,data);
