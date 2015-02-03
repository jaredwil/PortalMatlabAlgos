function df = FreeBytes(disk);
%function df = FreeBytes(disk);
% pass a disk identifier (ie, c:\) and the number of free bytes will be
% returned, the return will be empty if the device is not available (for
% writing)

[s, w] = dos(['dir ' disk ' /W/OS']);
inx = findstr(w, 'Dir(s)');
sdf = w(inx+6:end-11);
sdf(findstr(sdf,',')) = [];
df = str2num(sdf);