function out = test5

GetEEGData;
a = GetEEGData('getMDevents');
b = [];  % begin
t = [];  % detect no stim
tw = []; % detect - stim
e = [];  % end
for i = 1:length(a)
    if strcmp(a(i).text, 'b');
        b(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 't');
        t(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 'tw');
        tw(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 'e');
        e(end+1) = a(i).ticktime;
    end
end
b = sort(b);

e = sort(e);

detect = [];
stim = [];
missedsz = [];
rate = GetEEGData('getrate');
for i = 1:length(b)
    a = t(find(t>b(i) & t<e(i)));
    if ~isempty(a)  % then detection only
        detect(end+1,1) = b(i);
        detect(end,2) = a;
        detect(end,3) = e(i);
        detect(end,4) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
        detect(end,5) = (e(i)-b(i))/rate;  % duration in seconds
        detect(end,6) = (a-b(i))/rate;     % no secs 'till detection
        
        adata = GetEEGData('ticks', [b(i) (e(i)-b(i))]);
        detect(end,7) = ofeat_AE(adata(:,1), rate) + ofeat_AE(adata(:,2), rate);  % ipsilateral energy
        detect(end,8) = ofeat_AE(adata(:,3), rate) + ofeat_AE(adata(:,4), rate);  % contralateral energy
        
    else
        a = tw(find(tw>b(i) & tw<e(i)));
        if ~isempty(a)  % then detection and stim
            stim(end+1,1) = b(i);
            stim(end,2) = a;
            stim(end,3) = e(i);
            stim(end,4) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
            stim(end,5) = (e(i)-b(i))/rate;  % duration in seconds
            stim(end,6) = (a-b(i))/rate;     % no secs 'till detection/stim
            adata = GetEEGData('ticks', [b(i) (e(i)-b(i))]);
            stim(end,7) = ofeat_AE(adata(:,1), rate) + ofeat_AE(adata(:,2), rate);  % ipsilateral energy
            stim(end,8) = ofeat_AE(adata(:,3), rate) + ofeat_AE(adata(:,4), rate);  % contralateral energy
        else
            missedsz(end+1,1) = b(i);
            missedsz(end,2) = e(i);
            missedsz(end,3) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
            missedsz(end,4) = (e(i)-b(i))/rate;  % duration in seconds
        end
    end
end

figure
subplot('position', [0.1 0.1 0.6 0.8]);
hold on
%plot(missedsz(:,3), missedsz(:,4), '.k', 'markersize', 15);
plot(detect(:,4), detect(:,5), '.b', 'markersize', 15);
%plot(stim(:,4), stim(:,5), '.r', 'markersize', 15);

dtc = detect;
st = stim;

GetEEGData;
a = GetEEGData('getMDevents');
b = [];  % begin
t = [];  % detect no stim
tw = []; % detect - stim
e = [];  % end
for i = 1:length(a)
    if strcmp(a(i).text, 'b');
        b(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 't');
        t(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 'tw');
        tw(end+1) = a(i).ticktime;
    end
    if strcmp(a(i).text, 'e');
        e(end+1) = a(i).ticktime;
    end
end
b = sort(b);

e = sort(e);

detect = [];
stim = [];
missedsz = [];
rate = GetEEGData('getrate');
for i = 1:length(b)
    a = t(find(t>b(i) & t<e(i)));
    if ~isempty(a)  % then detection only
        detect(end+1,1) = b(i);
        detect(end,2) = a;
        detect(end,3) = e(i);
        detect(end,4) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
        detect(end,5) = (e(i)-b(i))/rate;  % duration in seconds
        detect(end,6) = (a-b(i))/rate;     % no secs 'till detection
        adata = GetEEGData('ticks', [b(i) (e(i)-b(i))]);
        detect(end,7) = ofeat_AE(adata(:,1), rate) + ofeat_AE(adata(:,2), rate);  % ipsilateral energy
        detect(end,8) = ofeat_AE(adata(:,3), rate) + ofeat_AE(adata(:,4), rate);  % contralateral energy
       
    else
        a = tw(find(tw>b(i) & tw<e(i)));
        if ~isempty(a)  % then detection and stim
 %           stim(end+1,1) = b(i);
 %           stim(end,2) = a;
 %           stim(end,3) = e(i);
 %           stim(end,4) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
 %           stim(end,5) = (e(i)-b(i))/rate;  % duration in seconds
 %           stim(end,6) = (a-b(i))/rate;     % no secs 'till detection/stim
        else
            missedsz(end+1,1) = b(i);
            missedsz(end,2) = e(i);
            missedsz(end,3) = datenum(GetEEGData('tick2datevec', b(i)));  % start datevec
            missedsz(end,4) = (e(i)-b(i))/rate;  % duration in seconds
        end
    end
end

st = [st; detect];

%plot(missedsz(:,3), missedsz(:,4), '.k', 'markersize', 15);
%plot(detect(:,4), detect(:,5), '.r', 'markersize', 15);

plot(st(:,4), st(:,5), '.r', 'markersize', 15);
MyDateAxis('dd-mmm');
ax = axis;
ax(3)= 0;
ax(4)= 200;
axis(ax);
xlabel('Seizure onset date-time');
ylabel('Seizure duration (seconds)');

subplot('position', [0.75 0.1 0.2 0.48]);

m = 0:5:200;
n = histc(dtc(:,5),m);
plot(n,m+2.5, 'b', 'linewidth', 3);
hold on

n = histc(st(:,5),m);
plot(n,m+2.5, 'r','linewidth', 3);

xlabel('frequency');
axis([0 10 0 120]);

subplot('position', [0.75 0.65 0.2 0.25]);
sti = length(find(st(:,5) < 50));
de = length(find(dtc(:,5) < 50));


%plot(st(:,4), st(:,5), '.r', 'markersize', 15);
hold on
plot([1 1],[0 (100*de/length(dtc))], 'b', 'linewidth', 20);
plot([2 2],[0 (100*sti/length(st))], 'r', 'linewidth', 20);

set(gca, 'xtick', [1 2]);
set(gca, 'xticklabel', 'detect|stim');
axis([0.5 2.5 0 50]);
ylabel('% duration < 50sec');



set(gcf, 'color', 'w');

dtc(:,9) = 5;
dtc([1 2 30 31 32 33],9) = 4;
dtc(24,9) = 3;
dtc([23 27 28 29],9) = 2;
dtc([25 26],9) = 0;


st(:,9) = 5;  % stage

save stimdata st dtc

length(dtc)
length(st)

figure
set(gcf, 'color', 'w');

subplot(2,1,1);
d = [];
for i = 2:length(dtc(:,4))
    d(i-1) = (etime(datevec(dtc(i,4)), datevec(dtc(i-1,4))))/(60*60);
end
bar(d, 'b');

%plot(diff(dtc(:,1)), 'b');
%a = diff(dtc(:,1));
%a(find(a < 0)) = [];
fprintf('Mean inter-seizure interval (no stimulation): %1.1f hours\n', mean(d));
hold on

s = [];
for i = 2:length(st(:,4))
    s(i-1) = (etime(datevec(st(i,4)), datevec(st(i-1,4))))/(60*60);
end
%bar(s)

bar(length(d)+1:length(d)+length(s), s, 'r');

fprintf('Mean inter-seizure interval (stimulation): %1.1f hours\n', mean(s));

ylabel('inter-seizure interval (hours)');
xlabel('seizure number');
%title('Stimulation Results in Reduced Inter-Seizure Intervals', 'fontsize', 12);
title('Inter-Seizure Interval vs Seizure Number', 'fontsize', 12);



subplot(2,2,3);
plot(dtc(2:end,5), d, '.b', 'markersize', 15);
hold on
plot(st(2:end,5), s, '.r', 'markersize', 15);
ylabel('hours until next seizure');
xlabel('seizure duration (seconds)');
title('Inter-Seizure Interval vs Duration', 'fontsize', 12);

subplot(2,2,4);
plot(dtc(1:end-1,5), d, '.b', 'markersize', 15);
hold on
plot(st(1:end-1,5), s, '.r', 'markersize', 15);
ylabel('hours since last seizure');
xlabel('seizure duration (seconds)');
title('Inter-Seizure Interval vs Duration', 'fontsize', 12);


figure
set(gcf, 'color', 'w');
%st and dtc
%4 -  datenum sz onset
%5 -  duration in seconds
%6 -  seconds from onset until detection/stimulation
%7 -  ipsilateral average energy
%8 -  contralateral average energy
%9 -  behavioral stage
% d interseizure intervals (hours) detect only
% s interseizure intervals (hours) stim

%fprintf('total ipsilateral energy (no stim): %3.2f\n', sum(dtc(:,7))*sum(dtc(:,5))); 
%fprintf('total contralateral energy (no stim): %3.2f\n', sum(dtc(:,8))*sum(dtc(:,5))); 
%fprintf('total ipsilateral energy (stim): %3.2f\n', sum(st(:,7))*sum(st(:,7))); 
%fprintf('total contralateral energy (stim): %3.2f\n', sum(st(:,8))*sum(st(:,7))); 

fprintf('ipsilateral energy per sec (no stim): %3.2f\n', sum(dtc(:,7))/sum(dtc(:,5))); 
fprintf('contralateral energy per sec (no stim): %3.2f\n', sum(dtc(:,8))/sum(dtc(:,5))); 
fprintf('ipsilateral energy per sec (stim): %3.2f\n', sum(st(:,7))/sum(dtc(:,5))); 
fprintf('contralateral energy per sec (stim): %3.2f\n', sum(st(:,8))/sum(dtc(:,5))); 


subplot(2,2,1);
bar(dtc(:,7).*dtc(:,5), 'b');
hold on
bar((length(dtc(:,7))+1):(length(dtc(:,7))+length(st(:,7))), st(:,7).*st(:,5), 'r');
xlabel('seizure number');
ylabel('energy');
title('Energy per seizure (ipsilateral)');
axis([0 82 0 5000]);

subplot(2,2,2);
bar(dtc(:,8).*dtc(:,5), 'b');
hold on
bar((length(dtc(:,8))+1):(length(dtc(:,8))+length(st(:,8))), st(:,8).*st(:,5), 'r');
xlabel('seizure number');
ylabel('energy');
title('Energy per seizure (contralateral)');
axis([0 82 0 5000]);

subplot(2,2,3);
bar(dtc(:,7), 'b');
hold on
bar((length(dtc(:,8))+1):(length(dtc(:,8))+length(st(:,8))), st(:,8), 'r');
xlabel('seizure number');
ylabel('energy');
title('Energy per second (ipsilateral)');
axis([0 82 20 35]);

subplot(2,2,4);
bar(dtc(:,8), 'b');
hold on
bar((length(dtc(:,8))+1):(length(dtc(:,8))+length(st(:,8))), st(:,8), 'r');
xlabel('seizure number');
ylabel('energy');
title('Energy per second (contralateral)');
axis([0 82 20 35]);



figure
set(gcf, 'color', 'w');
%st and dtc
%4 -  datenum sz onset
%5 -  duration in seconds
%6 -  seconds from onset until detection/stimulation
%7 -  ipsilateral average energy
%8 -  contralateral average energy
%9 -  behavioral stage
% d interseizure intervals (hours) detect only
% s interseizure intervals (hours) stim
subplot(2,1,1);
plot(dtc(:,4), dtc(:,9), '.b', 'markersize', 20);
hold on
plot(st(:,4), st(:,9), '.r', 'markersize', 20);
ylabel('stage');
xlabel('seizure date');
title('Stage vs Seizure Date');
ax = axis;
ax(3) = -1;
ax(4) = 6;
axis(ax);
mydateaxis('dd-mmm');

subplot(2,2,3);
plot(dtc(:,7), dtc(:,9), '.b', 'markersize', 20);
hold on
plot(st(:,7), st(:,9)-0.2, '.r', 'markersize', 20);
ylabel('behavioral stage');
xlabel('energy per second');
title('Stage vs ipsilateral energy');
axis([20 35 -1 6]);

subplot(2,2,4);
plot(dtc(:,8), dtc(:,9), '.b', 'markersize', 20);
hold on
plot(st(:,8), st(:,9)-0.2, '.r', 'markersize', 20);
ylabel('behavioral stage');
xlabel('energy per second');
title('Stage vs contralateral energy');
axis([20 35 -1 6]);
