function [f,c] = jphasetemp(data, rate)

vals = jphasedelay(data, rate);
[m,f] = max(vals');
c = 1:length(f);
