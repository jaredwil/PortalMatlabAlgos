load stimdata
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

fprintf('ipsilateral energy per sec (no stim): %3.2f\n', mean(dtc(:,7))); 
fprintf('contralateral energy per sec (no stim): %3.2f\n', mean(dtc(:,8))); 
fprintf('ipsilateral energy per sec (stim): %3.2f\n', mean(st(:,7))); 
fprintf('contralateral energy per sec (stim): %3.2f\n', mean(st(:,8))); 


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
bar((length(dtc(:,8))+1):(length(dtc(:,8))+length(st(:,8))), st(:,7), 'r');
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
subplot(2,2,1);
plot(st(:,6), st(:,5), '.r', 'markersize', 20);
xlabel('stim time (seconds into seizure)');
ylabel('seizure duration');
title('Duration vs Stim Time ');

subplot(2,2,2);
plot(st(:,6), st(:,5)-st(:,6), '.r', 'markersize', 20);
xlabel('stim time (seconds into seizure)');
ylabel('Post-stim seizure duration');
title('Post-Stim Duration vs Stim Time ');
