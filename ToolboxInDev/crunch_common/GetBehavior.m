function out = GetBehavior(ratname, datetime);
global av

BehaviorPath = 'c:\mfiles\Crunch_AviMPG\avis\';
%need to define BehaviorPath!!!!!!!!

out = 'no data';
av = [];
findd =  datenum(datetime);
a = dir([BehaviorPath 'BehavResults_' ratname '*.mat']);
for i = 1:length(a)
    [starttime stoptime] = ParseBehaviorFileName(a(i).name);
    if findd >= starttime & findd <= stoptime
        load([BehaviorPath a(i).name]);
        break
    end
end

if ~isempty(av)  % found a file with the behavior in it
    for i = 1:length(av.Results)
        %fprintf('%5.7d %5.7d\n', findd, av.Results(i).starttime)
        if findd < av.Results(i).starttime
            out = av.Results(i-1).label;
            break
        end
    end
    if isempty(out)
        out = av.Results(end).label;
    end
end

