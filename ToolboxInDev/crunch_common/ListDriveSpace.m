function out = ListDriveSpace;
%function out = ListDriveSpace;
% lists the drives available on the system, and the number of free bytes on
% each

j= 0;
for i = 'a':'z';
    sp = FreeBytes([i ':\']);
    if ~isempty(sp)
        fprintf( 'drive %s: %12.0f bytes free (%s)\n', char(i), sp, VolumeLabel([i ':\']));
        j = j+1;
        out(j).drive = i;
        out(j).freebytes = sp;
    end
end