function out = InitMDFile(action, data1, data2, data3);
% data1 = starttick
% data2 = label to give event
% data3 = channel to put label on, default is chan 1
global rf;
global eeghdr;

if ~exist('data3') | isempty(data3)
    data3 = 1;
end

switch action
    
    case 'init'
        rf.fid = fopen([data1 '.md'], 'wt');

    case 'writeline'
        fprintf(rf.fid, '%6d, 1, %s, %s\n', data1, eeghdr.labels(data3,:), data2); 
        
    case 'close'
        fclose(rf.fid);
        
end
