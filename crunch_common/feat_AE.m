function out = feat_AE(data, rate);

%   NAME    feat_AE.m
%
%   This feature, to be used with rfeature (the run feature program), 
%   returns the average energy of data given to it.
%
%   USAGE   out = feat_AE(data, rate);
%
%   INPUT   data    MxN data vector (M = time, N = channels); the shorter
%                   dimension is assumed to be the channels, the longer
%                   dimension is assumed to be the channel's time series
%           rate    data sampling rate; does nothing in this case
%
%   OUTPUT  out     average energy of the data, in column format
%
%   Stephen Wong, MD
%   November 21, 2005


if size(data,2) > size(data,1)
    data = data';
end

out = diag((data'*data)/(length(data)))';
