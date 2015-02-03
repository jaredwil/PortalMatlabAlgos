function out = NumZeroCrossings(data);

out = zeros(size(data,2), 1);

%set up to be ones and zeros
data(find(data > 0)) = 1;
data(find(data < 0)) = 0;

% find the differences
a =diff(data);

% take all non-zero  (that would be all ups and downs)
out = sum(abs(a));
