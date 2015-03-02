function chanhfo = FindHFOsnearSpikes(gdf)
% pass a spike and hfo gdf file
% returns a list of spikes with HFO's 'on' them by channel
out = [];

% assume rate is 250
beforeticks = 5;
afterticks = 15;

for channel =  1:6  % max possible channels for now
    chanhfo(channel).hfo = [];
    spikes = gdf(find(gdf(:,1) == channel), 2);  % tick time of spikes on this channel
    hfo = gdf(find(gdf(:,1) == channel+10), 2);  % tick time of hfos on this channel
    
    for i = 1:length(hfo)
        h = spikes(find(hfo(i) > spikes- beforeticks & hfo(i) < spikes + afterticks));
        if ~isempty(h)
        chanhfo(channel).hfo(end+1:end+length(h)) = h; 
        end
    end
end
        