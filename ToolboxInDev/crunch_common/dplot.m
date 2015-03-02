function dplot(data);

m = max(max(data));
n = -min(min(data));
if n > m
    m = 1.5*n;
else
    m = 1.5*m;
end;

for i = 1:size(data,2)
    data(:,i) = data(:,i) -m*i;
end

x = 1:size(data,1);
x = x/GetEEGData('getrate');
plot(x,data, 'color', [1 1 0.7]);
%plot(x,data, 'r');
grid on;
ax = axis;
ax(1) = 0;
ax(2) = x(end)+1;
ax(3) = (size(data,2)+1) * -m+1;
ax(4) = -size(data,2);
axis(ax);
set(gca, 'yticklabel', flipud(GetEEGData('getlabels')));
set(gca, 'color', [0 0.3 0.3]);
set(gca, 'xcolor', 'k');
set(gca, 'ycolor', 'k');
xlabel('seconds')