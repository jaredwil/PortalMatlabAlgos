function out = PlotSeizures(event, eventend)

out = 1;

plotchannel = 1;
displayseconds = 160;
startoffsetseconds = -10;
nfc = [0.75 0.75 0.75]; % night fill color
if isempty(GetEEGData); return; end

events = GetEEGData('getAllMDevents', event);
GetEEGData('setverbose', 'off');

if length(events) < 1; fprintf('No events marked %s found!\n', event); return; end

% make sure the events start out in temporal order
t = zeros(length(events), 1);
for i = 1:length(events)
    t(i) = datenum(events(i).datevec);
end
[y, order] = sort(t);
events = events(order);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot in temporal order
%%
figure
hold on
f = GetEEGData('getfilename');
f(findstr('_',f)) = ' ';
title([f '  - seizures plotted in temporal order']);
m = min(length(events), 50);
data = GetEEGData(events(1), [startoffsetseconds displayseconds]);
normalize = 2*max(max(data));
x = 1:length(data);
x = x/GetEEGData('getrate');
x = x+startoffsetseconds;
for i = 1:m
    data = GetEEGData(events(i), [startoffsetseconds displayseconds]);
    data = data(:,plotchannel)/normalize;
    plot(data+i, x);
end
axis([-2 m+3 x(1)-1  x(end)+1]);
xlabel('seizure number');
ylabel('seconds');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot by time of day
%%
figure
hold on
title([f '  - seizures plotted by time of day']);
h =fill([-0.8 7 7 -0.8], [x(1) x(1) x(end) x(end)], nfc);
set(h, 'edgecolor', nfc);
h =fill([19 24.8 24.8 19], [x(1) x(1) x(end) x(end)], nfc);
set(h, 'edgecolor', nfc);
timeofday = zeros(m,1);
for i = 1:m
    data = GetEEGData(events(i), [startoffsetseconds displayseconds]);
    data = data(:,plotchannel)/(normalize*2);
    timeofday(i) = events(i).datevec(4) + events(i).datevec(5)/60;  
    plot(data+timeofday(i), x);
end
axis([-1 25 x(1)-1  x(end)+1]);
xlabel('hour');
ylabel('seconds');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot by inter-seizure interval
%%
figure
hold on
title([f '  - seizures plotted by interseizure interval']);
lastsz = events(1).datevec;
isi = zeros(m ,1);
for i = 2:m
    data = GetEEGData(events(i), [startoffsetseconds displayseconds]);
    data = data(:,plotchannel)/(normalize*10);
    isi(i) = etime(events(i).datevec, lastsz)/60;
    if isi(i) > 1
    lastsz = events(i).datevec;
    plot(data+log10(isi(i)), x);
    end
end
isiax = axis;
axis([isiax(1) isiax(2) x(1)-1  x(end)+1]);
xlabel('log_1_0 minutes');
ylabel('seconds');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot duration, energy - if eventend has been passed
%%
if ~exist('eventend', 'var') || isempty(eventend)
    return
end
eventsend = GetEEGData('getAllMDevents', eventend);
if length(eventsend) < 1; fprintf('No events marked %s found!\n', eventend); return; end

% sort eventsend by time
t = zeros(length(eventsend), 1);
for i = 1:length(eventsend)
    t(i) = datenum(eventsend(i).datevec);
end
[y, order] = sort(t);
eventsend = eventsend(order);

n = min(m, length(eventsend));

rate = GetEEGData('getrate');
duration = zeros(n, 1);
energy = zeros(n, 1);
for i = 1:n
    duration(i) = etime(eventsend(i).datevec, events(i).datevec);
    if duration(i) > 5*60 | duration < 1 %#ok<OR2>
        fprintf('There seems to be a problem with the markings at or around tick %d.\nOn %s in session %03d\nSeizure duration is apparently %1.1f minutes.\nAborting.\n', events(i).ticktime, datestr(events(i).datevec), events(i).session, duration(i)/60);
        return
    end
    
    data = GetEEGData(events(i), [0 etime(eventsend(i).datevec, events(i).datevec)]);
    energy(i) = feat_AE(data(:,plotchannel),rate); 
end


% plot duration
figure
subplot(2,2,1);
plot(duration, '.');
title([f '  - duration vs temporal order']);
xlabel('seizure number');
ylabel('seconds');
ax = axis;
axis([0 n 0 ax(4)]);

subplot(2,2,2);
hold on
h =fill([-0.8 7 7 -0.8], [0 0 ax(4) ax(4)], nfc);
set(h, 'edgecolor', nfc);
h =fill([19 24.8 24.8 19], [0 0 ax(4) ax(4)], nfc);
set(h, 'edgecolor', nfc);
plot(timeofday, duration, '.');    
title([f '  - duration vs time of day']);
axis([-1 25 0 ax(4)]);
xlabel('hour');
ylabel('seconds');

subplot(2,2,3);
plot(log10(isi), duration, '.');
axis([isiax(1) isiax(2) 0  ax(4)]);
title([f '  - duration vs interseizure interval']);
xlabel('log_1_0 minutes');
ylabel('seconds');
    


% plot energy    
figure
subplot(2,2,1);
plot(energy, '.');
title([f '  - energy vs temporal order']);
xlabel('seizure number');
ylabel('energy');
ax = axis;
axis([0 n 0 ax(4)]);

subplot(2,2,2);
hold on
h =fill([-0.8 7 7 -0.8], [0 0 ax(4) ax(4)], nfc);
set(h, 'edgecolor', nfc);
h =fill([19 24.8 24.8 19], [0 0 ax(4) ax(4)], nfc);
set(h, 'edgecolor', nfc);
plot(timeofday, energy, '.');    
title([f '  - energy vs time of day']);
axis([-1 25 0 ax(4)]);
xlabel('hour');
ylabel('energy');

subplot(2,2,3);
plot(log10(isi), energy, '.');
axis([isiax(1) isiax(2) 0  ax(4)]);
title([f '  - energy vs interseizure interval']);
xlabel('log_1_0 minutes');
ylabel('energy');
    
