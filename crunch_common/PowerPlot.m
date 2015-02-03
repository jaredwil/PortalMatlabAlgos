function out = PowerPlot
out = [];

GetEEGData;
rate = GetEEGData('getrate');
GetEEGData('sethunksize',120);
bins = 1+GetEEGData('getlasttick')/(rate*120);
for i = 1:6
   subplot(3,2,i);
   GetEEGData('resetindex');
   GetEEGData('limitchannels', i);
   inx = 1;
   fall = zeros(100,bins);
   while 1
       inx = inx+1;
       data = GetEEGData('getnext');
       if size(data,1) ~= 120*rate
           break
       end
       [f ,x] = jpwelch(data, rate);
       fall(:,inx) = f(1:100);
       fall(61,inx) = 0;
   end
   fall(1:4,:) = 0;
%   image(fall)
   fall = 100*fall/sum(sum(fall));
   plot(x(1:100),mean(fall'))
   axis([0 100 0 0.1]);
   hold on
   ax = axis;
   text(60, ax(4)/2, sprintf('60-100Hz: %2.1f%%', sum(sum(fall(60:end,:)))));
   text(20, ax(4)*3/4, sprintf('14Hz: %2.1f%%', sum(sum(fall(15,:)))));
   text(ax(2),ax(4), sprintf('chan %d', i), 'horizontalalignment', 'right', 'verticalalignment', 'top');
   if i == 1
       f = GetEEGData('getfilename');
       loc = findstr(f,'_');
       f(loc(1)) = ' ';
       f(loc(2:end)) = ':';
       title(f, 'fontsize', 14);
   end
   if i == 5
       xlabel('Hz');
       ylabel('%total power');
   end
       
end



