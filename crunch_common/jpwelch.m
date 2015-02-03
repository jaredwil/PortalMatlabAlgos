function [p,x] = jpwelch(data, rate)
% data must enter as rows = time, cols = streams

for i = 1:size(data,2)
    [p(:,i), x(:,i)] = pwelch(data(:,i), size(data,1), [], rate, rate);
end