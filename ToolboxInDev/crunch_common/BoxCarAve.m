function out = BoxCarAve(data,pts);


if pts >= length(data)
  return;
end;

out = data;

start = ceil(pts/2);
 
for i = start:length(data)-start
 out(i) = sum(data(i-start+1:i+start))/pts;
end
out(1:start-1) = mean(out(1:start-1));
out(end-start+2:end) = mean(out(end-start+2:end));
