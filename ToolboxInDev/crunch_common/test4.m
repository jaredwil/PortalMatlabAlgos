function times = test4;
global keep;

offsetsec = -94;  % for session 6 of r21

startdv = GetEEGData('getstartdatevec');
enddv = GetEEGData('getenddatevec');
times = [];
home = 'c:\data\onlineJPGs\';
a = dir(home);
for i = 1:size(a,1)
    if a(i).isdir & length(a(i).name) > 2
        b = dir([home a(i).name]);
        for j = 1:size(b,1)
            if ~b(j).isdir & strcmp(b(j).name(end-3:end), '.jpg')
                dt(1) = str2num(b(j).name(11:14));
                dt(2) = str2num(b(j).name(15:16));
                dt(3) = str2num(b(j).name(17:18));
                dt(4) = str2num(b(j).name(20:21));
                dt(5) = str2num(b(j).name(22:23));
                dt(6) = str2num(b(j).name(24:25)) + offsetsec;
                if etime(dt, startdv) > 0 & etime(dt,enddv) < 0
                    times(end+1) = datenum(dt);
                end
            end
        end
    end
end

b = GetEEGData('getfilename');
InitMDFile('init', [GetEEGData('getpathname') b(1:end-4)]);
for i = 1:length(times)
    InitMDFile('writeline', fix(GetEEGData('datetime2tick', times(i))), 'detection');
end
InitMDFile('close');

return

keep = [];
GetEEGData('setdisplayspacer', 3000);
for i = 1:length(times)
    GetEEGData(times(i), [20 20]);
    res = input('1 for skip, 2 for keep 3 for quit:');
    if res == 2
        keep(end+1) = times(i);
    end
    if res == 3
        break
    end
end
save keep keep