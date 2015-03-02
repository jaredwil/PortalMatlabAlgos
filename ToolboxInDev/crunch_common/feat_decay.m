function out = feat_decay(data, rate)

% returns the total number consecutive datapoints with the second less than the first
a = diff(data(:,1));
out = length(find(a < 0))/length(a);

%normalize
out = 2*abs(out-0.5);
out = (out*10)^2;
out = out/10;