function n = feat_ZEROX(data, rate);

% This function returns the number of zero-crossings from the detrended
% data.

data = detrend(data);
data2 = find(data>0);
n = 2*length(find(diff(data2)>1));


