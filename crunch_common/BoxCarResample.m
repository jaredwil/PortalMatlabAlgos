function out = BoxCarResample(data,pts);


if pts >= length(data)
  out = mean(data);
  return;
end;

Done = 0;
i = 0;
j = 0;
while ~Done
  i = i+pts;
  j = j+1;
  if i <= length(data)
      out(j) = mean(data(i-pts+1:i));
  else
    Done = 1;    
  end 
end

% now do last bit if not exactly even
i = i-pts;

if i ~= length(data)
    out(j+1) = mean(data(i+1:end));
end


