function ticks = linelength(chan);

%
% NAME: linelength.m
%
% This program prompts the user for a Nicolet-format EEG file.  Once one is
% selected, consecutive 5-minute blocks of EEG data from the input channel
% is converted to feature space with the linelength feature, with a
% 1-second window / 0.5-second advance.  The 5 minute blocks are then
% sorted in descending order via their maximal value of line length, such
% that the first blocks would contain the largest values of line length.
% The tick times of the start of the blocks are then returned.  The
% rationale is to use this to find 5-minute blocks which likely contain
% seizure activity; they would show up in descending order of likelihood
% (assuming that the highest values of linelength would occur during
% seizure periods).  You can modify this to use any feature which features
% which attain high values during seizures.
%
% USAGE:    ticks = linelength(chan);
%
% INPUT:    chan    channel from the eegfile which you wish to use to find
%                   seizures
%
% OUTPUT:   ticks   1xN tick times of 5-minute blocks which are most likely
%                   to contain seizure, in descending order; N is the total
%                   number of 5-minute blocks in the data.
%
% Stephen Wong, MD
% swong@swong.org
% January 10, 2006


if length(chan) > 1
    fprintf(['Only channel ' num2str(chan(1)) ' will be analyzed.\n']);
end

GetEEGData;
rate = GetEEGData('getrate');
lastpt = GetEEGData('getlasttick');
GetEEGdata('limitchannels', chan(1));

% what feature / window / advance do you want to use?
f.name = 'feat_CL';
f.arg1 = rate;
win = 15*rate;
adv = 7.5*rate;

% how many data points do you want to analyze to see whether a seizure
% exists within it?
n = rate*60*5;



results = zeros(ceil(lastpt/n),2);
i = 0;
cnt = 1;

% analyze the entire session
while i < lastpt
    data = GetEEGdata('ticks', [i, n]);
    feat = runfeat(data, f, win, adv);
    [results(cnt,1), results(cnt,2)] = max(feat);
    results(cnt,2) = results(cnt,2)*adv - adv + i;  % set correct tick time
    i = i + n;
    cnt= cnt+1;
end
[junk, inx] = sort(results(:,1),1, 'descend');
ticks = results(inx,2);
%maxfeat = max(feat);
%[sortedmaxfeat, idx] = sort(maxfeat, 'descend');
%ticks = ((idx-1)*n)+ 1;
