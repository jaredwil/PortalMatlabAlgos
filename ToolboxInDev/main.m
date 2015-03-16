% Main wrapper script
% User should only need to edit the initialize.m file

% Run initialization
params = initialize;

% Load data
session = loadData(params);

for i = 1:numel(session.data)

%% Preprocess


%% Action
% Extract Features

% Run Detections


% Cluster detections


end
