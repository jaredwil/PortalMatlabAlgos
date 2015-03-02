function out = plotszfinder(sf);
global eeghdr;

work = sf.gdf;
if ~size(work, 1)
    return
end

%eeghdr.rate = 2000;
work(:,2) = work(:,2)/(eeghdr.rate*60*60);  % covert to hours
seiz = work(find(work(:,1) == 990),2);
buzz = work(find(work(:,1) == 970),2);
spikes = work(find(work(:,1) == 960),2);

dsz = diff(seiz);
dbz = diff(buzz);
dsp = diff(spikes);

figure
subplot(3,2,1);
x = [0.5:19.5];
%hist(dsz, x);
xlabel('hours');
ylabel('frequency')
title('histogram of inter-seizure periods');

subplot(3,2,2);
%bar(dsz);
xlabel('seizure number');
ylabel('inter-seizure period (hr)')
title('inter-seizure time vs seizure number');
ax = axis;
ax(3) = 0;
ax(4) = 10;
axis(ax);

subplot(3,2,3);
x = [0.5:19.5];
%hist(dbz, x);
xlabel('hours');
ylabel('frequency')
title('histogram of inter-buzz periods');

subplot(3,2,4);
%bar(dbz);
xlabel('buzz number');
ylabel('inter-buzz period (hr)')
title('inter-buzz time vs buzz number');



%bottom figure

halfday = 12*60*60;

d = eeghdr.PtIndx(1).startdatetimevec;
n = d;
n(5:6) = 0;
n(4) = 19;   % night at 7pm

if d(4) > 7 & d(4) < 19
    % then daytime
    FirstDarkPeriodTick = eeghdr.rate*(etime(n,d));
else
    % nighttime  % want a negative number so starts off dark
    if d(4) > 18
        FirstDarkPeriodTick = eeghdr.rate*(etime(n,d));
    else  
        FirstDarkPeriodTick = eeghdr.rate*(etime(n,d) -2*halfday);
    end
end

tick = FirstDarkPeriodTick/(eeghdr.rate*60*60);
night = [];
while tick < work(end,2) + 12
    night = [night; [tick tick+12]];
    tick = tick + 24;
end

%subplot(3,1,3)
subplot(1,1,1)
for i = 1:size(night,1);
    fill([night(i,1) night(i,1) night(i,2) night(i,2)], [0 11500 11500 0], [0.6 0.6 0.6], 'edgecolor', 'w');
    hold on
end

plotenergy;

if ~isempty (seiz)
  plot(seiz, 6000, '.r', 'MarkerSize', 12);
end
%plot(night', [0.5 0.5], 'k', 'linewidth', 2);
if ~isempty(buzz)
    plot(buzz, 7000, '.g', 'MarkerSize', 12, 'color', [1 0 1]);
end
if ~isempty(spikes)
    plot(spikes, 8000, '.k', 'MarkerSize', 12);
end

axis([0 work(end,2) 0 12000]);
xlabel('hours');
set(gca,'ytickmode', 'manual');
set(gca,'ytick', [6000 7000 8000]);
set(gca, 'yticklabel', ['  seiz';'  buzz';'spikes']);
%set(gca, 'yticklabel', ['    ';'seiz';'buzz';'    ']);
