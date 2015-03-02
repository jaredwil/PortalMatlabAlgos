%%finds peaks and throughs
%%Nagi Hatoum
%%copyright 2005
function [p,t]=FindPeaks(s)
warning off
ds=diff(s);
p = [];
t = [];
if ~ds(1);
    a = find(ds); 
    try 
        ds(1) = ds(a(1));
    catch
        return
    end;
end;
ds=[ds(1);ds];%pad diff
filter=find(ds(2:end)==0)+1;%%find zeros
while ~isempty(filter)
ds(filter)=ds(filter-1);%%replace zeros
filter=find(ds(2:end)==0)+1;%%find zeros
end
ds=sign(ds);
ds=diff(ds);
t=find(ds>0);
p=find(ds<0);

