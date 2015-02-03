GetRatData;
ID = GetRatData('getID');
sessionlist = GetRatData('getsessions');

sessionID = sprintf('%3d',sessionlist(1));
for i = 2:length(sessionlist)
    sessionID = [sessionID '_' sprintf('%3d',sessionlist(1))];
end

GetRatData('setblocksize', 0.5);
d = GetRatData('getnext');
d = [d; GetRatData('getnext')];
d = [d; GetRatData('getnext')];
d = [d; GetRatData('getnext')];
st = size(d,1)/4;
sp = 3*st;
    
features = loadfeatures('C:\mfiles\dev\Swong\Features\EEG\');
analyzedatawindow('init', size(d));
analyzedatawindow('features', features);
analyzedatawindow('setrate', GetEEGData('getrate'));


timematrix = [0, 0];
bins = GetRatData('gettotaldatablocks');
maxfsize = 100000;
if bins < maxfsize
    f = zeros(bins, length(features), GetEEGData('getnumberofchannels'));
else
    f = zeros(maxfsize, length(features), GetEEGData('getnumberofchannels'));    
end

filenumber = 0;
idx = 3;
totalidx = 3;
tic
while 1
   f(idx, :, :) = analyzedatawindow('calc', d);
   data = GetRatData('getnext');
   if isempty(data)
       [data,secs] = GetRatData('getnext');
       if isempty(data)  % if is empty twice out of data
           break
       else             % if just is empty once, then we spanned a gap
           timematrix(end+1,:) = [secs, idx]; 
       end
   end
   d = [d(st+1:end,:); data];
   idx = idx +1;
   totalidx = totalidx+1;
   if idx > maxfsize
       save([ID '_' sessionID '_features_' num2str(filenumber) '.mat'])
       f(:,:,:) = 0;
       filenumber = filenumber +1;
       timematrix = []
       timematrix(end+1,:) = [secs, totalidx];
       
   end
end
toc
save