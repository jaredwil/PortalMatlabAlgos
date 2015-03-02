function out = test2(s);

out = zeros(size(s));
for i = 1:size(s,1)  % each trial
    base = mean(s(i,1:8));
    for j = 21:size(s,2)
        res = s(i,j)/base > 5;
        if res
            out(i,j) = out(i,j-1) + 1; 
        else
            out(i,j) = 0;
        end
        base = mean(s(i,j-20:j-10));
    end
end
figure
t = out;
t(find(t > 4)) = 100;
t(find(t < 50)) = 0;
image(t);
out = t;