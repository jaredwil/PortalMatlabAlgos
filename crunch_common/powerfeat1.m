function out = powerfeat1(data,rate)

b = pwelch(data,[],[],rate,rate);
out = log10(sum(b(6:16)))/log10(sum(b(25:30)));
