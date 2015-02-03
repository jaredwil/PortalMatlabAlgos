function out = ChangeSessionNumber

out = [];

source = '*.eeg';
FN = [];
[FN, DPath] = uigetfile(source, 'Open an eeg file');

if isempty(FN)
    return
end

dots = findstr('.', FN);
ses = str2double(FN(dots(end)-3:dots(end)-1));
newses = str2double(inputdlg({'Enter new session number'}));

st = sprintf('%s: change session from %03d to %03d?', FN, ses, newses);
if strcmp('yes', questdlg(st, 'Confirm rename', 'yes', 'no', 'cancel', 'no'))
    % do the rename here
    while 1  % rename files in order until files no longer exist
        %rename eeg
        s = sprintf('rename %s %s%03d%s\n', [DPath FN], FN(1:dots(end)-4), newses, FN(end-3:end));
        %fprintf('%s\n',s)
        dos(s);

%        %rename bni
%         if strcmp(FN(end-2:end), 'eeg')
%             s = sprintf('rename %s to %s%03d.bni\n', [DPath FN], FN(1:dots(end)-4), newses);
%         else
%             s = sprintf('rename %s.bni to %s%03d%s.bni\n', [DPath FN], FN(1:dots(end)-4), newses, FN(end-3:end));
%         end
%         %fprintf('%s\n',s)
%         dos(s)

        % get new and old bni file names
        if strcmp(FN(end-2:end), 'eeg')
            infile = [DPath FN(1:end-3) 'bni'];
            outfile = sprintf('%s%s%03d.bni', DPath, FN(1:dots(end)-4), newses);
        else
            infile = [DPath FN '.bni'];
            outfile = sprintf('%s%s%03d%s.bni', DPath, FN(1:dots(end)-4), newses, FN(end-3:end));
        end

        % open to read old and write new
        fin = fopen(infile, 'r');
        fout = fopen(outfile, 'w');

        % copy, putting new session in whereever old session is found
        textline = fgetl(fin);
        while 1
            if ~ischar(textline)  % textline == -1 for eof
                break
            end
            a = strfind(textline, FN(1:end-4));
            if isempty(a)
                %then just copy this line 'cause the filename is not in it
                fprintf(fout, '%s\n', textline);
            else
                %copy putting new session number in
                fprintf(fout, '%s%03d%s\n', textline(1:a(1)-1 + dots(end)-4), newses, textline(a(1)-1 + dots(end):end));
            end
            textline = fgetl(fin);
        end

        fclose(fin);
        fclose(fout);
        
        FN = GetNextFile(FN);
        if ~exist([DPath FN], 'file')
            break
        end
        
    end
   
end



function out = GetNextFile(FN)
next = str2double(FN(end-2:end));
if ~isnan(next)
    next = next+1;
    out = [FN(1:end-3) sprintf('%03d', next)];
else % it is 'eeg' so next file is 000
    out = [FN(1:end-3) '000'];
end



