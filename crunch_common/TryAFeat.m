function result = TryAFeat(d)

secbinsz = 1;
chan = 1;
if ~exist('d', 'var') || isempty(d)
result = zeros(5, 100000);
GetEEGData('limitchannels', chan);
lasttick = GetEEGData('getlasttick');
rate = GetEEGData('getrate');
usepassed = 0;
else
    lasttick = length(d);
    rate = 250;
    result = zeros(ceil(lasttick/(rate*secbinsz)),1);
    usepassed = 1;
end

tic
k = 1;
for i = 1:rate*secbinsz:lasttick-1-rate*secbinsz
    if usepassed
        data = d(i:i+rate*secbinsz-1);
    else
        data = GetEEGData('ticks', [i, rate*secbinsz]);
    end

    result(1,k) = feat_decay(data, rate); 
    result(2,k) = feat_AE(data, rate); 
    result(3,k) = feat_CL(data, rate); 
    result(4,k) = feat_ZEROX(data, rate); 
    result(5,k) = feat_asym(data, rate);

    k = k+1;
    if k > size(result,2) 
        break
    end
end
toc
figure
ax(1) = subplot(5,1,1);
plot(result(1,:));
ax(2) = subplot(5,1,2);
plot(result(2,:));
ax(3) = subplot(5,1,3);
plot(result(3,:));
ax(4) = subplot(5,1,4);
plot(result(4,:));
ax(5) = subplot(5,1,5);
plot(result(5,:));
linkaxes(ax,'x');
