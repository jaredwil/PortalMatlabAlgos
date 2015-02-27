%% Jensen_wrapper.m
% This script load data and annotations from the portal, analyzes the data,
% performs clustering, then uploads the results back to the portal.

% make filtering an object
% compare time for filtering/downsample in matlab to using the portal
% how to handle comparison with doug's annotations
% animal 2: days 48 - 56
% how to handle the time offset between experiment/portal


clear all; close all; clc; tic;
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\ieeg-matlab-1.8.3'));

 
%% Define constants for the analysis
study = 'dichter';  % 'dichter'; 'jensen'; 'pitkanen'
runThese = 2;  % jensen 3,4,15,17; dichter 2-3; pitkanen 1-3
params.channels = 1:4;
params.label = 'burst';
params.technique = 'linelength';
params.startTime = '46:08:00:00';  % day:hour:minute:second
params.stopTime = '46:10:00:00'; % day:hour:minute:second

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


%% Run analysis and upload results
fig_h = 1;
for r = 1:length(runThese)
  params = f_load_params(params)
  fprintf('Running %s_%s on: %s\n',params.label, params.technique, session.data(r).snapName);
  fh = str2func(sprintf('f_%s_%s', params.label, params.technique));
  fh(session.data(r),params);
  f_addAnnotations(session.data(r),params);
  toc
end


%% Analyze results
% if runPhysiology
% %     fig_h = 1;  % handle to current figure; this gets incremented in each function
% %     [fig_h] = fn_bph_per_rat(session,data_key,fig_h);
% %     [fig_h] = fn_bph_per_group(session,data_key,fig_h);
% %     params.label = 'spike';
% %     params.technique = 'threshold';
% %     [fig_h] = f_histogram_per_rat(session.data(r),dataKey,params,fig_h);
%   [fig_h dur{r}] = f_choppedHistogram_per_rat(session.data(r),dataKey,fig_h);
% end


