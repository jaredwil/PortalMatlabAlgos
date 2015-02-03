function data = PCA_RemoveNoise(data,pct);

[signals, pc, v] = pca1(data');

% v are the variances, normalize and print to screen
v = v/sum(v);

% find the weights needed to build the channels from the signals
cc = cov([data signals']);                       % calculate co-variance matrix
cc = cc./repmat(diag(cc),1,size(cc,1));     % normalize by the variance
w = cc(1+size(cc,1)/2:end, 1:size(cc,2)/2); % these are the channel weights of each signal
w
cutoff = find(cumsum(v) > 1-pct);

for chan = 1:size(data,2)
for i = cutoff'
    data(:,chan) = data(:,chan) - w(i,chan)*signals(i,:)';
end
end
