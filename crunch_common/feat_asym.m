function out = feat_asym(data, rate)


f = hist(diff(data), -2000:200:2000);
j = fliplr(f);
out = max(f-j)-10;
out = out(end);