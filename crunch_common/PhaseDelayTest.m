function out = PhaseDelayTest(ID)

out = [];
days = 150;
GetEEGData(ID);
GetEEGData('limitchannels', [1 2 3 4]);
hunk = 10*60;
ss = GetEEGData('getAllMDevents', 'SS');
start = datenum(GetEEGData('getstartdatevec'));
ssmarks = [];
for i = 1:length(ss)
    ssmarks(i) = datenum(ss(i).datevec) - start;
end
ssmarks = ssmarks-0.5;
GetEEGData('resetindex', 0);
GetEEGData('sethunksize', hunk);
d= GetEEGData('getnext');
hunks= 6*24;
f= jphasedelay(d, 250);
iplt = zeros(length(f)-1,hunks);
hundays = zeros(length(f)-1, days);
% iplt2 = zeros(length(f)-1,hunks);
% hundays2 = zeros(length(f)-1, days);
%figure('Name', [GetEEGData('getidentifier') '  DG-DG CA1 CA1']);
fname = [GetEEGData('getidentifier') '-PhaseDelay_lDG-lCA1'];
figure('Name', fname, 'position', [1927 700 1271 420]);
centerfig;
subplot('position', [.75 .3 .2 .6 ]); jpie([1 1 1 1 1 1 1 1]);
for j = 1:days
    for ii = 1:hunks
        d = GetEEGData('getnext');
        if isempty(d)
            break
        end
        try
        f = jphasedelay(d(:,[1,2]), 250);
        iplt(:,ii)= f(2:end);
%         [f,c]= jphasetemp(d(:,[3,4]), 250);
%         f(1) = [];
%         iplt2(:,ii)= real(f);
        catch
            keyboard
        end
    end
    hundays(:,j) = mode(iplt');
%     hundays2(:,j) = mode(iplt2');
%    subplot(2,1,1);
    subplot('position', [.05 .1 .65 .8 ]);
    image(hundays*9)

    hold on
    axis([0.5000  days+0.5000  -10.0000  125.5000]);
    fill([.5 .5 days+0.5 days+0.5],[-10 0 0 -10], 'k')
    for i = 1:length(ssmarks)
        plot([ssmarks(i) ssmarks(i)], [0 -10], 'r');
    end
    hold off
%     subplot(2,1,2);
%     image(hundays2*9-8)
%     hold on
%     axis([0.5000  days+0.5000  -10.0000  125.5000]);
%     fill([.5 .5 days+0.5 days+0.5],[-10 0 0 -10], 'k')
%     for i = 1:length(ssmarks)
%         plot([ssmarks(i) ssmarks(i)], [0 -10], 'r');
%     end
%     hold off
    drawnow
    if isempty(d)
        break
    end
end
saveas(gcf, [fname '.fig'], 'fig');
return

iplt = zeros(length(f),hunks);
hundays = zeros(length(f), days);
iplt2 = zeros(length(f),hunks);
hundays2 = zeros(length(f), days);
GetEEGData('resetindex', 0);
fname = [GetEEGData('getidentifier') '-PhaseDelay_DG-DG_CA1-CA1'];
figure('Name', fname);
%figure('Name', [GetEEGData('getidentifier') '  DG-CA1 DG-CA1']);
for j = 1:days
    for ii = 1:hunks
        d = GetEEGData('getnext');
        if isempty(d)
            break
        end
        [f,c]= jphasetemp(d(:,[1,3]), 250);
        f(1) = [];
        iplt(:,ii)= real(f);
        [f,c]= jphasetemp(d(:,[2,4]), 250);
        f(1) = [];
        iplt2(:,ii)= real(f);
    end
    hundays(:,j) = mode(iplt');
    hundays2(:,j) = mode(iplt2');
    subplot(2,1,1);
    image(hundays*64/8)

    hold on
    axis([0.5000  days+0.5000  -10.0000  125.5000]);
    fill([.5 .5 days+0.5 days+0.5],[-10 0 0 -10], 'k')
    for i = 1:length(ssmarks)
        plot([ssmarks(i) ssmarks(i)], [0 -10], 'r');
    end
    hold off
    subplot(2,1,2);
    image(hundays2*64/8)
    hold on
    axis([0.5000  days+0.5000  -10.0000  125.5000]);
    fill([.5 .5 days+0.5 days+0.5],[-10 0 0 -10], 'k')
    for i = 1:length(ssmarks)
        plot([ssmarks(i) ssmarks(i)], [0 -10], 'r');
    end
    hold off
    drawnow
    if isempty(d)
        break
    end
end
saveas(gcf, [fname '.fig'], 'fig');
close all
