function [data,ave,sigma] = standardize(data,ave,sigma);
% function [data,ave,sigma] = standardize(data,ave,sigma);
% standardize 'standardizes' the data.  If passed data it returns
% the standardized data, the ave of the data, and the standard devations
% if data is a matrix, ave and std are vectors
%
% if data,ave, and sigma are passed, the data is standardized using the
% passed ave and sigma.

if ~(nargin == 1 | nargin == 3)
    fprintf('Only 1 or 3 input arguments are accepted.\n');
    return
end
if nargin == 1
   ave = mean(data);
   sigma = std(data);
end
data = (data - repmat(ave,size(data,1),1))./repmat(sigma,size(data,1),1);

