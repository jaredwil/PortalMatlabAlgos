function [c,f] = jcohere(data, rate)
% data must enter as rows = time, cols = streams

data=detrend(data);
[c, f] = mscohere(data(:,1), data(:,2), [],[],rate,rate);%, size(data,1), [], rate, rate);
