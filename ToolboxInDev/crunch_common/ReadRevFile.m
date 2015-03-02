function out = ReadRevFile(FN);

out = [];
source = ['*.rev'];

if isempty(FN)
    [FName, DPath] = uigetfile(source, 'Open an rev file')
    if ~(FName)
        out = [];
        fprintf('No file selected, aborting\n');
        return
    end

    fid = fopen([DPath FName], 'rt');
else
    fid = fopen([FN], 'rt');
end

if fid < 1
    out = [];
    return
end


event = 1;
textline = fgetl(fid);
while 1
    if strcmp(textline, '<event separator>')
        event = event+1;
        textline = fgetl(fid);
    end
    if ~ischar(textline)  % textline == -1 for eof
        break
    end
    % edit between these comments to get what you want


    [s,r] = strtok(textline);  % read first whitespace delimited str into s, r is the remainder
    %s is seconds into the file
    [s,r] = strtok(r);  %read the second: tick number

    out(event) = str2num(s);  % save second of this event


    % edit between these comments to get what you want

    textline = fgetl(fid);
end