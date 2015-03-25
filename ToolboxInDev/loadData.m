function session = loadData(params)

%Function will open all datasets specified
datasets = params.datasets;
session = IEEGSession(params.datasets{1},params.ieeg.username,params.ieeg.pwdPath);
for i = 2:numel(datasets)
    session.openDataSet(datasets{i});
end
