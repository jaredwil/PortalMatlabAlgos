% Main wrapper script
% User should only need to edit the initialize.m file

% Run initialization
params = initialize;

%% Add Paths
addpath(genpath(params.ieeg.path))

% Load sessions
session = loadData(params);

datasets = {'I010_A0001_D001','I010_A0002_D001','I010_A0002_D001'};
session = cell(3,1);
session{1} = IEEGSession('I010_A0001_D001','hoameng','hoa_ieeglogin.bin');
session{2} = IEEGSession('I010_A0002_D001','hoameng','hoa_ieeglogin.bin');
session{3} = IEEGSession('I010_A0003_D001','hoameng','hoa_ieeglogin.bin');
sampleRates = zeros(3,1);
means = zeros(3,1);
parfor i = 1:3
    session = IEEGSession(datasets{i},'hoameng','hoa_ieeglogin.bin');
    sampleRates(i) = session.data.sampleRate;
    means(i) = mean(session.data.getvalues(1:100,1));
end
%% Preprocess


%% Action
% Extract Features

% Run Detections


% Cluster detections


end
