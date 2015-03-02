function out = IsLight(datetime);

light = [7 19];

t = datenum(datetime);
s = datevec(t);
if s(4) >= light(1) & s(4) < light(2)
    out = 1;
else
    out = 0;
end