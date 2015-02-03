function out = PlotSponPOPSpikes2(ID)

GetEEGData(ID);
pn = GetEEGData('getpathname');
stimon = GetEEGData('getAllMDevents', 'StimON');
sz = GetEEGData('getAllMDevents', 'SS');
npn = [pn(1:end-6) 'Hz16k\'];
a = dir([npn '*_ch1_edSponPOPSpikes.mat']);
struc = GetEEGData('getSessionStruct');
firstday = datestr(struc(1).sesstart, 'dd-mmm-yyyy');
fd = floor(datenum(struc(1).sesstart));
ed = datenum(struc(end).sesend) - datenum(struc(1).sesstart);

time = [];
allres = [];
marked = [];
for i = 1:length(a)
    fprintf('loading %s\n', [npn a(i).name]);
    load([npn a(i).name]);
    GetEEGData('init', [npn esp.fileName]);
    enddv = GetEEGData('getenddatevec');
    marked = [marked; [datenum(esp.startdv), datenum(enddv)]];
    if length(esp.res)
    for j = 1:length(esp.results)
        time(end+1) =  esp.results(j).datenum;
    end
    allres = [allres esp.results];
    end
end
marked = marked - fd;

if ~isempty(time)
[x, inx] = sort(time);
allres = allres([inx]);
x = x-fd;

x =x*24;  % turn into hours
x = ceil(x);
popspikehisto = zeros(1,ceil(max(x)+1));
for i = 1:length(popspikehisto);
    popspikehisto(i) = length(find(x == i)); 
end

figure;
subplot(2,1,1)
xp = 1:length(popspikehisto);
xp = xp-0.5;
xp = xp/(24);  % turn into days
bar(xp, popspikehisto,1);
set(gca, 'ylim', [0 200]);
yl = get(gca, 'ylim');
hold on
for i = 1:length(sz)
    sdn = datenum(sz(i).datevec)-fd;
    plot([sdn sdn], yl, 'r');
end
if ~isempty(stimon)
    sdn = datenum(stimon(1).datevec)-fd;
    plot([sdn sdn], yl, 'k', 'linewidth', 5);
end
for i = 1:size(marked,1)
    plot([marked(i,1), marked(i,2)], [yl(2)-1 yl(2)-1], 'color', [0 0.5 0], 'linewidth', 10);
end

set(gca, 'xlim', [0 ed+1]);
title([ID ' L-DG Spontaneous POP spikes'])
y = get(gca, 'ylim');
%text(0.5,y(2)-1, ['first day: ' firstday], 'verticalalign', 'top')
else
figure;
subplot(2,1,1)
plot([0:10]);
title([ID ' L-DG Spontaneous POP spikes'])
text(3,5,'No pop spikes found');    
end


fprintf('\n');
a = dir([npn '*_ch3_edSponPOPSpikes.mat']);

time = [];
allres = [];
marked = [];
for i = 1:length(a)
    fprintf('loading %s\n', [npn a(i).name]);
    load([npn a(i).name]);
    GetEEGData('init', [npn esp.fileName]);
    enddv = GetEEGData('getenddatevec');
    marked = [marked; [datenum(esp.startdv), datenum(enddv)]];
    if length(esp.res)
    for j = 1:length(esp.results)
        time(end+1) =  esp.results(j).datenum;
    end
    allres = [allres esp.results];
    end
end
marked = marked - fd;

if ~isempty(time)
[x, inx] = sort(time);
allres = allres([inx]);

x = x-fd;

x =x*24;  % turn into hours
x = ceil(x);
popspikehisto = zeros(1,ceil(max(x)+1));
for i = 1:length(popspikehisto);
    popspikehisto(i) = length(find(x == i)); 
end


subplot(2,1,2)
xp = 1:length(popspikehisto);
xp = xp-0.5;
xp = xp/(24);  % turn into days
bar(xp, popspikehisto, 1);
set(gca, 'ylim', [0 200]);%Changed from 50
yl = get(gca, 'ylim');
hold on
for i = 1:length(sz)
    sdn = datenum(sz(i).datevec)-fd;
    plot([sdn sdn], yl, 'r');
end
if ~isempty(stimon)
    sdn = datenum(stimon(1).datevec)-fd;
    plot([sdn sdn], yl, 'k', 'linewidth', 5);
end
for i = 1:size(marked,1)
    plot([marked(i,1), marked(i,2)], [yl(2)-1 yl(2)-1], 'color', [0 0.5 0], 'linewidth', 10);
end

set(gca, 'xlim', [0 ed+1]);
title([ID ' R-G Spontaneous POP spikes'])
y = get(gca, 'ylim');
%text(0.5,y(2)-1, ['first day: ' firstday], 'verticalalign', 'top')
xlabel('days')
ylabel('POP spikes per day');
else
subplot(2,1,2)
plot(0:10);
text(3,5,'No pop spikes found');    
title([ID ' R-DG Spontaneous POP spikes'])
xlabel('days')
ylabel('POP spikes per hour');
end    
    