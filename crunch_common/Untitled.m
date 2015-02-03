L = 1250;
X = zeros(1,L);
s_i = .008;  % 250 Hz
t = (1:L)*s_i;
for N = 1:1
    X = X+N*sin(N*pi*t);
end
figure;
subplot(2,1,1);
s = 31;
e = 1;
xx = [];
xx(:,1) = X(s:s+1000-1);
xx(:,2) = X(e:e+1000-1);
plot(xx);
subplot(2,1,2);
out = jphasetemp(xx, 250);
%te = jphasedelay(xx,250);
%out(1:10)
p = [1 1 1 1 1 1 1 1];

p(out(2)) = p(out(2)) + 10;
jpie(p);