function out = MakeMDFile(action, data1, data2, data3)
% data1 = starttick
% data2 = label to give event
% data3 = channel to put label on, default is chan 1
global rf;
global eeghdr;

out = 1;

if ~exist('data3', 'var') || isempty(data3)
    data3 = 1;
end

switch action
    
    case 'init'
        
        [p,n,e] = fileparts(data1); 
        try
            [pd,nd,ed] = fileparts(GetEEGData('getfilename'));
        catch
            fprintf('The corresponding eeg file %s is not currently open (using GetEEGData)!  Aborting.\n', [n '.eeg']);
            out = 0;
            return
        end       
        if ~strcmp(n,nd)
            fprintf('The corresponding eeg file %s is not currently open (using GetEEGData)!  Aborting.\n', [n '.eeg']);
            out = 0;
            return
        end
       
        
        if strcmp(data1(end-2:end), '.md')
            data1 = data1(1:end-3); % expect just the filename to be passed
        end
        
        
        newfile = [GetEEGData('getpathname') n '.md'];
        if exist(newfile, 'file')
            % file already exists, ask if want to append to it
            answer = questdlg('Append to existing file?', 'MD file already exists', 'No');
            if ~strcmp(answer, 'Yes')
                fprintf('User aborted writing to file %s\n', newfile);
                out = 0;
                return
            end    
            
            % making a new file
            rf.fid = fopen(newfile, 'at');
        end
        
        
    case 'writeline'
        fprintf(rf.fid, '%d,1,%s,%s\n', data1, eeghdr.labels(data3,:), data2); 
        
    case 'close'
        fclose(rf.fid);
        
end
