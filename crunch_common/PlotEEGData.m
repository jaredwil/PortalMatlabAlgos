function out = PlotEEGData(action, data);
%function out = PlotEEGData(action, data);
global eeghdr;
global ploteeg;

if ~exist('action')
  action = 'init'
end

switch action
    case 'init'
        PlotEEGData('initvars');
        GetEEGData;
        
    case 'initvars'
        ploteeg.start = -15;   % display 15 seconds before
        ploteeg.stop = 30;     % display 30 seconds after 
        ploteeg.scale = 3000;  % uV between traces
        
        
    case 'show'
        data = datevec(data);  % data must be in datevec format
        t = PlotEEGData('gettimes', data);
        d = GetEEGData('getdatevecdata', t);
        PlotEEGData('plot', d);
        
        
    case 'setscale'
        ploteeg.scale = data;
        
    case 'settimerange'
        % data is in seconds for display ie, [-30 30], displays times from
        % -30 to 30 seconds around the current display time
        ploteeg.start = data(1);
        ploteeg.stop = data(2);
        
        
    case 'gettimes'
        t(1) = datevec(datenum(data + [ 0 0 0 0 0 ploteeg.start]));
        t(2) = datevec(datenum(data + [ 0 0 0 0 0 ploteeg.stop]));
        
        
    case 'plot'
        yt = [];
        
        for i = 1:size(data, 2)
            data(:, i) = data(:,i) - ((i-1) * ploteeg.scale);
            yt = [yt  -(i-1) * ploteeg.scale];
        end
        figure(gcf)
        x = 1:length(data);
        x = x/eeghdr.rate;
        plot(x, data, 'b');
        xlabel('seconds');
        set(gca, 'ytick',fliplr(yt));
        axis tight
        
        
end