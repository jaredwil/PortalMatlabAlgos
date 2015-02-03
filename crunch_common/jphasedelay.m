function out = jphasedelay(data, rate)

sz = size(data,1);
nobins = floor(sz/rate);
pd = zeros(rate/2, nobins);
j = 0;
for i = 1:rate:size(data,1)-rate+1
    j = j+1;
    ph1 = fftshift(angle(fft(data(i:i+rate-1,1))));
    ph2 = fftshift(angle(fft(data(i:i+rate-1,2))));
    ph1 = ph1-ph2;
    pd(:,j) = ph1(rate/2+1:end);
end
pd(find(pd < -pi/8)) = pd(find(pd < -pi/8)) + 2*pi;
if size(pd,2) == 1
    out = ceil((pd+pi/8)*4/pi);
else
    qud = hist(pd', 0:pi/4:15*pi/8);
    [m2,out] = max(qud);
end


