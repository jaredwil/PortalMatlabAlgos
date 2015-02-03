function CL = feat_CL(data, rate);

%   NAME    feat_CL.m
%
%   This feature, to be used with rfeature (the run feature program), takes
%   the curve length of data given to it.  For example, if the data given
%   were the values [1,-5,8], the output would be the total length of the 
%   lines connecting the points: 6 + 13 = 19.
%
%   USAGE   CL = feat_CL(data);
%
%   INPUT   data    MxN series of values; the shorter dimension is assumed 
%                   to be the channels, the longer dimension is assumed to 
%                   be the data per channel
%           rate    acquisition rate passed to all features; does nothing
%                   in this case
%
%   OUTPUT  CL      the sum of the distance of the lines connecting the 
%                   points in each channel of data; data is outputted in
%                   column format (the results per channel of data is given 
%                   in each column output).
%
%   Stephen Wong, MD
%   November 21, 2005

if size(data,2) > size(data,1)
    data = data';
end

CL = sum(abs(diff(data)));
