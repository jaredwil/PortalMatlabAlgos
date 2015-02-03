function out_gdf = drh_datenum(gdffilename, datenum_ranges)
% this function takes any gdf file name and a nx2 list of datenumbers
% is will look through all the gdf files with the same ID as the passed
% name (in the same directory), and return the rows of these files that are
% inside the data_num ranges - the data is re-indexed to the first file.
global jps
gdf = zeros(2,2);

if ~exist('gdffilename', 'var') || isempty(gdffilename)
    [f,p] = uigetfile('*gdf.mat', 'Open a gdf file');
    if ~f; return; end
    gdffilename = fullfile(p, f);
end

if ~exist('datenum_ranges', 'var') || isempty(datenum_ranges)
    datenum_ranges = [700000, 800000];  % take all times
end
% this program requires that all the data come in in temporal order
% so need to sort the datenum_ranges, and make sure the gdf files are in
% temporal order
a = GetGDFFiles(gdffilename);
datenum_ranges = sortrows(datenum_ranges);

latesttick = 0;
for i = 1:length(a);
    load(a{i});    % load the gdffile
    if i == 1
        startdv = startdatevec;
        out_gdf = [];
    end

    locallasttick = 0;
    tempgdf = [];
    for j = 1:size(datenum_ranges, 1)

        % convert datenum to ticks
        r_starttick = max(locallasttick, rate*etime(datevec(datenum_ranges(j,1)),startdatevec));
        r_stoptick = etime(datevec(datenum_ranges(j,2)),startdatevec);

        % find data in range
        tempgdf = [tempgdf; gdf(find(gdf(:,2) >= r_starttick & gdf(:,2) < r_stoptick),:)];
        locallasttick = tempgdf(end,2);
    end

    % correct tick times
    tempgdf(:,2) = tempgdf(:,2) + rate*etime(startdatevec, startdv);
%    tempgdf(find(tempgdf(:,2) <= latesttick),:) = [];  % get rid of repeats
    fprintf('file: %s\n', a{i});
    fprintf('first event: %d,     lastevent: %d\n\n', tempgdf(1,2), tempgdf(end,2));

    out_gdf = [out_gdf; tempgdf];
    latesttick = out_gdf(end,2);
end


if isempty(jps)
    JPSVars('loadJPSVars');
end

[p,n,e] = fileparts(gdffilename);
jps.DataPath = p;
a = findstr(n, '_');
jps.FileName = n(1:a(1)-1);  % the file id

jps.gdf = out_gdf;
jps.rate = rate;
JPSVars('allIDsWind','update');
result = JPSVars('FindLists');

drh('current');





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%

function filelist  = GetGDFFiles(gdfname)

[p,n,e] = fileparts(gdfname);
a = findstr(n, '_');
files = dir([fullfile(p, [n(1:a(1)) '*' n(a(1)+4:end)]) e]);
for i = 1:size(files,1)
    filelist{i} = fullfile(p, files(i).name);
end

