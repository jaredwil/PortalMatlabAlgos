function out = CheckForVideo(action, data);


switch action
    case 'init'
        a = findstr(data, '_');
        try
            ID = data(1:a(1)-1);
        catch
            out = [];
            return
        end
        out = [];
        for i = 'c':'z'
            a = dir([i ':\' ID '_vid']);
            if size(a,1) > 2
                out = [i ':\' ID '_vid'];
                cfv.sourcedir = out;
                return
            end
        end
        cfv.sourcedir = [];


    case 'datestr2vidname'
        
        
        
    case 'play'
        nm = CheckForVideo('datestr2vidname', data); 
        if ~isempty(nm)
            s = sprintf('wmplayer.exe.lnk %s\n', [cfv.sourcedir nm]);
            dos(s);
        end
        
        
        
end