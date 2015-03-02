function out = mytest(lst,n)

for i = n;%:length(lst)
   a = GetEEGData('dticks', [lst(i)-13999, 16000]);
   for k = 1:size(a,2)-1; 
     a(:,k) = detrend(a(:,k), 'linear');
     a(:,k) = eegfilt(a(:,k), 50, 'lp');
   end
   for j = 0:7
       fprintf('%03d ', NumZeroCrossings(a(j*2000+1:(j+1)*2000,:)));
       fprintf('\n');
   end
   fprintf('\n\n');

end
out = a;