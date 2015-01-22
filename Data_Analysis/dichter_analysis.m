%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

% make filtering an object
% compare time for filtering/downsample in matlab to using the portal
% add output to file component to track results, later, compare to doug's annotations?
%

clear all; close; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

%% Define which parts of the script to run
runBurstDetection = 0;  % refer to dataKey (f_xxxx_data_key.m)
runSpikeDetection = 1;
runClustering = 0;
runPhysiology = 0;
uploadAnnotations = 1;
saveToFile = 1;


%% Define constants for the analysis
study = 'dichter';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = 1;

params.experiment = 'SD-popspikes';
params.channels = 1;
params.blockDur = 1;  % hours; amount of data to pull at once
params.minThresh = 2;    % X * stdev(signal); minimum threshold to detect burst; 
params.maxThresh = 6;  % X * stdev(signal); maximum threshold;
params.minDur = 2;    % sec; min duration of the burst
params.maxDur = 100;       % sec; max duration of the burst
params.winSecs = params.minDur; % sec; size of the window for feature detection
params.padSecs = 1;   %  sec; amount to pad around the edges of the returned features
params.filter = 'butter';  % 'butterworth'; if filled, will filter data
params.highPass = 5;    % Hz; high pass cutoff freq for filter
params.lowPass = 30;    % Hz; low pass cutoff freq for filter
params.filtOrder = 5;   % order of the filter to use
params.downSample = 250; % if >0, will downsample data before analysis
params.plotData = 0;  % plot data, yes or no

% params.experiment = 'BD-linelength';
% params.channels = 1;
% params.blockDur = 1;  % hours; amount of data to pull at once
% params.minThresh = 2;    % X * stdev(signal); minimum threshold to detect burst; 
% params.maxThresh = 6;  % X * stdev(signal); maximum threshold;
% params.minDur = 2;    % sec; min duration of the burst
% params.maxDur = 100;       % sec; max duration of the burst
% params.winSecs = params.minDur; % sec; size of the window for feature detection
% params.padSecs = 1;   %  sec; amount to pad around the edges of the returned features
% params.filter = 'butter';  % 'butterworth'; if filled, will filter data
% params.highPass = 5;    % Hz; high pass cutoff freq for filter
% params.lowPass = 30;    % Hz; low pass cutoff freq for filter
% params.filtOrder = 5;   % order of the filter to use
% params.downSample = 250; % if >0, will downsample data before analysis
% params.plotData = 0;  % plot data, yes or no
% <html><br></html>


%% Load investigator specific information
switch study
  case 'dichter'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data'));
  case 'jensen'
    addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P04-Jensen-data'));    
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
% <html><br></html>


%% Run analysis
for r = 1:length(runThese)
  for c = 1:length(session.data(r).channels)
    if runBurstDetection
      fprintf('Burst detection in : %s\n',session.data(r).snapName);
      fh = str2func(['f_burstDetection_' params.experiment]);
      [burstTimes, burstChannels] = fh(session.data(r),params);
    end
    if uploadAnnotations
      f_uploadAnnotations(session.data(r),burstDetections.experiment,burstTimes,burstChannels,burstDetections.experiment);
    end
    if saveToFile
      f_saveToFile(params.experiment,burstTimes,burstChannels);
    end
  end
  if runClustering
  end
  if runPhysiology
    fig_h = 1;  % handle to current figure; this gets incremented in each function
    [fig_h] = fn_bph_per_rat(session,data_key,fig_h);
    [fig_h] = fn_bph_per_group(session,data_key,fig_h);
    [fig_h] = fn_histogram_per_rat(session,data_key,fig_h);
  end
end
% <html><br></html>


%% Output annotations to file

% <html><br></html>


% %% CLUSTER BURSTS ONCE DETECTED ABOVE INITIAL CLUSTER
% elseif runClustering
%   idxByDataset = initialBurstClusterAsla(session.data,'burst_detections');
%   for i = 1:numel(session.data)
%     idx = idxByDataset{i}; %GET IDXS FOR DATASET
%     annots = getAllAnnots(session.data(i),'burst_detections'); %GET ALL ANNOTS
%     for j=1:max(idx) %FOR EACH CLUSTER
%       fprintf('Adding cluster %d...',j)
%       newLayerName = sprintf('burst_detections_%d',j);
%       try
%         session.data(i).removeAnnLayer(newLayerName); %TRY TO REMOVE IN CASE ALREADY PRESENT
%       catch
%       end
%       annLayer = session.data(i).addAnnLayer(newLayerName);
%       ann=annots(idx==j);
%       numAnnot = numel(ann);
%       startIdx = 1;
%       %add annotations 5000 at a time (freezes if adding too many)
%       for k = 1:ceil(numAnnot/5000)
%         fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
%         annLayer.add(ann(startIdx:min(startIdx+5000,numAnnot)));
%         startIdx = startIdx+5000;
%       end
%       fprintf('...done!\n')
%     end
%   end
%   %TRAIN BURST VS ARTIFACT CLASSIFIER
%   models = train_burst_artifact_model('B-Amodel.mat');
%   %CLASSIFY AND UPLOAD
%   [bursts, artifacts] = classify_bursts(session.data,{'burst_detections_2','burst_detections_3'},'B-Amodel.mat',{'burst_real','burst_artifact'});
% %%
% % <html><br><html>
% 
% %% CALCULATIONS VS PHYSIOLOGY BASED ON RESULTS FROM ABOVE
% elseif runPhysiology
%   load('.\data_key.mat'); 
%   try
%     fig_h = 1;  % handle to current figure; this gets incremented in each function
%     [fig_h] = fn_bph_per_rat(session,data_key,fig_h);
%     [fig_h] = fn_bph_per_group(session,data_key,fig_h);
%     [fig_h] = fn_histogram_per_rat(session,data_key,fig_h);
% %             [fig_h] = fn_duration_per_rat(session,fig_h);
% %             [fig_h] = fn_duration_per_group(session,fig_h);
% %             toc
%   catch ME
%     disp(ME)
%     fprintf('Failed calculating in: %s\n',session.data(i).snapName);
%   end
% end
% %%
% % <html><br><html>
% 
