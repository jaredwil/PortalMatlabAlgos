clear all; close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

 
%% Define constants for the analysis
study = 'dichter';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = 2;  % jensen 3,4,15,17; dichter 2-3; pitkanen 1-3


%% Load investigator data key
switch study
  case 'dichter'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data'));
  case 'jensen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data')); 
  case 'pitkanen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P01-Pitkanen-data')); 
end
fh = str2func(['f_' study '_data_key']);
dataKey = fh();


%% Establish IEEG Sessions
% Establish IEEG Portal sessions.
for r = 1:length(runThese)
  if ~exist('session','var')
    session = IEEGSession(dataKey.portalId{runThese(r)},'jtmoyer','jtm_ieeglogin.bin');
  else
    session.openDataSet(dataKey.portalId{runThese(r)});
  end
  fprintf('Opened %s\n', session.data(r).snapName);
end


%% plot data
params.label = 'feature';
params.technique = 'energy';
startTime = '48:09:09:00'; % plot start in days:hours:minutes:seconds; set day to 0 to start at beginning
plotWidth = 2;            % width of plot, in minutes
channels = 1;   % channels, make sure channel exists in params.channels


fname = sprintf('../Output/%s-%s-%s',session.data(r).snapName,params.label,params.technique);
load([fname '.mat']);
fs = session.data(1).sampleRate;  % sampling rate for original data
fsFt = 1/params.windowDisplacement;

fig_h = 1;

% translate the start plot time to a sample number; portal starts at day 1,
% not day 0
timeValue = sscanf(startTime,'%d:');
if (timeValue(1) > 0)
  start = int64((timeValue(1)-1)*24*60*60*fs + timeValue(2)*60*60*fs + ...
    timeValue(3)*60*fs + timeValue(4)*fs + 1); % days:minutes:hours:seconds
else
  start = params.startSample;
end


% scan through text file and find index of first sample after start
m = memmapfile([fname '.txt'],'Format','single');
ftStart = 1;
while ftStart < length(m.data) && m.data(ftStart) < start
  ftStart = ftStart + length(params.channels) + 1;
end
% ftStart = ftStart - (length(params.channels)+1);
% NumWins = @(xLen, fs, winLen, winDisp) (xLen/fs)/winDisp-(winLen/winDisp-1); 
% fsFt = plotWidth*60 /(NumWins((plotWidth*60*fs),fs,params.windowLength,params.windowDisplacement)+1);


% plot 
b = 1;
numBlocks = ceil(((params.endSample - start) / fs / 60) / plotWidth);
while (b < numBlocks)
  curPt = start + (b-1)*(plotWidth*60*fs);
  endPt = min([b*(plotWidth*60*fs)+start-1 params.endSample]);
  data = session.data(1).getvalues(curPt:endPt,params.channels);

  % I'm using this as a sanity check on the timestamps
%   day = floor(curPt/24/60/60/fs + 1);  % portal starts at day 1, not 0
  day = floor(curPt/24/60/60/fs) + 1;  % portal starts at day 1, not 0
  leftSamps = curPt - (day-1)*24*60*60*fs;
  hour = floor(leftSamps/60/60/fs);
  time = ((double(curPt:endPt) - double((day-1)*24*60*60*fs) ...
    - double(hour*60*60*fs))) / fs / 60;

  curFt = ftStart + (b-1)*(plotWidth*60*fsFt)*(length(params.channels)+1) + (length(params.channels)+1);
  endFt = min([b*(plotWidth*60*fsFt-1)*(length(params.channels)+1)+ftStart + (length(params.channels)+1) length(m.data)-length(params.channels)]);
  featureData = reshape(m.data(curFt:endFt+length(params.channels)),length(params.channels)+1,[])';  % first column is time
  dayFt = floor(featureData(1,1)/24/60/60/fs + 1);  % portal starts at day 1, not 0
  leftSamps = featureData(1,1) - (dayFt-1)*24*60*60*fs;
  hourFt = floor(leftSamps/60/60/fs);
  featureData(:,1) = ((double(featureData(:,1)) - ...
    double((dayFt-1)*24*60*60*fs) - double(hourFt*60*60*fs))) / fs / 60;
%   featureData = [NaN(params.windowDisplacement*fs,3);length(params.channels)+1];
%   timeFt = m.data(curFt:(length(params.channels)+1):endFt-1);
  
  Y(:,1) = featureData(:,1);
  convDur = 30; % seconds
  smoother = 1/30*ones(1,30);
  Y(:,2) = conv(featureData(:,2),smoother,'same');

  fprintf('Day %d, hour %d, minute %d:%d, RMS = %f\n', day, hour, floor(featureData(1,1)), round(featureData(end,1)), rms(featureData(channels(1),2:end)));
  for c = 1:length(channels)
    figure(channels(c));
    subplot(212);    
    plot(time,data(:,c),'k');
    xlabel(sprintf('Day %s, Hour %s',num2str(day),num2str(hour)));
    title(session.data(1).snapName);
    subplot(211);
    
    plot(featureData(:,1),featureData(:,c+1)/max(featureData(:,c+1)),'k');
    hold on;
    plot(Y(:,1),Y(:,2)/max(Y(:,2)),'r');
    
%     xlabel(sprintf('Day %s, Hour %s',num2str(dayFt),num2str(hourFt)));
    xlabel(sprintf('Day %d, Hour %d',dayFt,hourFt));
    title(sprintf('%s-%s',params.label,params.technique));
    ylim([0 1]);  % 1e10
    xlim([time(1),time(end)]);
  end
  b = b + 1;
  pause;
end







