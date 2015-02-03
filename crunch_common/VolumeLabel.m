function out = VolumeLabel(disk);
%function out = VolumeLabel(disk);
% pass a disk identifier (ie, c:\) and the volume label  will be
% returned, the return will be empty if the device is not available (for
% writing)

[s, w] = dos(['dir ' disk ' /W/OS']);
inx = find(w == 's'); % find the s
iny = find(w == 10);  % find the carriage returns
out = w(inx(1)+2:iny(1)-1);
