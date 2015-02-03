function decay = QSA(chan)
%function QSA
%  open a rat and analyze for seizure like activity using function decay on
%  the channel passed

decay = [];

a = GetEEGData;                         % open a eeg file
if isempty(a)                           % if cancled
    return                              % then return
end

%for chan = 1:numchans
%    GetEEGData('resetindex',0);
    decay = zeros(2000000,1);               % 1 million 10 second bins = almost 4 months
    x = zeros(2000000,1);
    decay_inx = 1;                          % where to put the next value

    rate = GetEEGData('getrate');           % get the rate
    GetEEGData('limitchannels', chan);      % limit to the channel of interest
    GetEEGData('sethunksize', 10);          % set to 10 second hunks

    tic
    data = GetEEGData('getnext');           % get the first hunk
    startlength = length(data);
    h = figure('position', [0.005, 0.45, 0.90, 0.45], 'units', 'normalized');
    
    while length(data) == startlength       % while data left
        decay(decay_inx) = feat_decay(data,rate);
        decay_inx = decay_inx+1;
        if decay_inx > size(decay,1)
            break;
        end
        data = GetEEGData('getnext');
        if ~rem(decay_inx, 6*60*24)        % every day
            x = 1:(decay_inx-1);
            x = x/(6*60*24);
            plot(x,decay(1:decay_inx-1))   % plot all 10 second bins
            drawnow
        end
    end
    toc
    decay(decay_inx:end) = [];              % get rid of extra zeros
%    subplot(numchans,1,chan);
    x = 1:length(decay);
    x = x/(6*60*24);
    plot(x,decay)                           % plot all 10 second bins
    drawnow
%end
%subplot(2,1,2);
%decay = decay - 0.1;
%decay(find(decay < 0)) = 0;
%bar(BoxCarResample(decay, 6*60*24))         % plot as days
