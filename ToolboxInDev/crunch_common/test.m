function out = test;
global eeghdr;

% assume h016_000.eeg is loaded
a = [32591999
  93935999
  98903999
 101902109
 105165468
 107665968
 134793843
 166583999
 327791999
 335356218
 336709594
 341636906
 345042093
 477849092
 524090717
 654140343
 656522531
 660355218
 662863031
 665453906
 667064156
 669244781
 670562531
 672803906
 674852343
 676616156
 804145030
 806289094
 837959718];  % tick times of the start of seizures

high = 70;
low= 40;
s = zeros(length(a),200);
for i = 1:length(a)
    for j = 0:199
        d = GetEEGData('getdata', [a(i)+(j-180)*eeghdr.rate, eeghdr.rate]);  % get one second pieces
        
        if 1
            %d(find(d > 10*std(d(:)))) = 0;   % noise rejection
            e = CleanData(d);
            g = e(:,end);
            if sum(e(:,end-1)) < sum(e(:,end))
                g = e(:,end-1);  % principle components have been flipped
            end
            [f, x] = pwelch(g, [], [], round(eeghdr.rate),round(eeghdr.rate));
            s(i,j+1) = (100*sum(f(high:end))/sum(f(1:low)));% / mean(std(d));
       end

        if 0
            g = d(:,1);
            [f, x] = pwelch(g, [], [], round(eeghdr.rate),round(eeghdr.rate));
            s(i,j+1) = (100*sum(f(high:end))/sum(f(1:low))) / mean(mean(abs(d)));
        end
    
        if 0
            s(i,j+1) = mean(mean(abs(d)));
        end
    end
end

figure
errorbar(-180:19, mean(s),zeros(200,1), std(s), '.b');
hold on
bar(-180:19, mean(s));
for i = -180:19
    plot(i,s(:,i+181), '.k');
end
%plot(mean(s));
%hold on
%plot(std(s));
    out = s;
    test2(s);
    
    
