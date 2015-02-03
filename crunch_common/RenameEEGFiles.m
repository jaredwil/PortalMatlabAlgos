function RenameEEGFiles(oldID, newID)
% oldID needs to include the path to the oldID files
% example:  RenameEEGFiles('e:\r001\Hz250\j0001', 'r001')  

[location, oID] = fileparts(oldID);

a = dir([oldID '*']);

for i = 1:length(a)
    f = findstr(a(i).name, oID);
    newname = [newID a(i).name(f(1)+length(oID):end)];

    if strcmp(newname(end-2:end), 'bni')
        BNIfile = [location '\' newname];
        OrigBNIfile = [location '\' a(i).name];

        fo = fopen(OrigBNIfile, 'r');
        fn = fopen(BNIfile,'w');
        line = fgetl(fo);
        while 1,
            if ~ischar(line), break; end  % done
            s = strfind(line, oID);
            if ~isempty(s)
                try
                fprintf(fn, '%s\n', [line(1:s-1) newID line(s-1+length(oID)+1:end)]);
                catch
                    keyboard
                end
            else
                fprintf(fn,'%s\n', line);
            end            
            if ~isempty(strfind(line, 'NextFile')), break; end  % done
            line = fgetl(fo);
        end
        fclose(fo);
        fclose(fn);
        fprintf('Created %s\n', BNIfile);
    else
        cmd = sprintf('rename %s\\%s %s\n', location, a(i).name, newname);
        fprintf('%s   ..', cmd);
        [s, w] = dos(cmd);
        if ~s
            fprintf('success!\n');
        else
            fprintf('ERROR!\n');
            return
        end
    end
end

