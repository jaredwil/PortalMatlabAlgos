function out = InitRevFile(action, data1, data2);
global rf;
global eeghdr;


switch action
    
    case 'init'
        rf.fid = fopen([data1 '.rev'], 'wt');

    case 'writeline'
        fprintf(rf.fid, '%1.6f  %6d CHANNEL_COMMENT Channel:%s;Bottom:1;Text:', data1/GetEEGData('getrate'), data1, eeghdr.labels(1,:)); 
        fprintf(rf.fid, '%s\n<event separator>\n', data2);
        
    case 'close'

        fclose(rf.fid);
        
end
