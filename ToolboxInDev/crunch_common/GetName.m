function out = GetName(action, PN);

l = length(PN);

% backup from end until we find '\', the next char is the first of the file name
for i = 1:l-1
  s = l-i;
  if PN(l-i) == '\'
     break;
  end   
end

if s ~= 1
  s = s+1;
end  

% s now points to location of first character of file name
FN = [];
switch(action);
   
case('path');
  out = PN(1:s-1);

case('full')		% filename plus all extensions
  out = PN(s:end);
  
case('name')		% filename sans extensions
  for i = s:l		% add chars until you get to the first '.'
    if PN(i) == '.'
      break
    end
    FN = [FN PN(i)];
  end
  out = FN;
   
end