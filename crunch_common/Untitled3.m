L = 1250;
rate = 250;
X = zeros(1,L);
s_i = .008;  % 250 Hz
t = (1:L)*s_i;
for N = 1:3
    X = X+N*sin(N*pi*t);
end
figure;
res = [];
s = 31;
e = 1;
xx = [];
xx(:,1) = X(s:s+rate-1);
xx(:,2) = X(e:e+rate-1);
%  ph1 = fftshift(angle(fft(xx(:,1))));
%  ph2 = fftshift(angle(fft(xx(:,2))));
%  ph1 = ph1-ph2;
%  pd = ph1(rate/2+1:end);
%  pd(find(pd < -pi/8)) = pd(find(pd < -pi/8)) + 2*pi;
% % pd = floor(pd/8);
out = jphasedelay(xx, rate);
plot(xx)
fprintf('phase delay 1Hz: %d\n', (out(2)-1)*45);
fprintf('phase delay 2Hz: %d\n', (out(3)-1)*45);
fprintf('phase delay 4Hz: %d\n', (out(5)-1)*45);
