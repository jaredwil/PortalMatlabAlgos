function AE = ofeat_AE(data, rate);

%   NAME    feat_AE.m
%
%   This feature, to be used with rfeature (the run feature program), 
%   returns the average energy of data given to it.
%
%   USAGE   AE = feat_AE(data);
%
%   INPUT   data    multi-dimensional of values to be processed
%
%   OUTPUT  AE      average energy of the data, in column format
%
%   Stephen Wong, MD
%   November 21, 2005

if size(data,2) > size(data,1)
    data = data';
end

AE = log(diag((data'*data)/(length(data)))');
