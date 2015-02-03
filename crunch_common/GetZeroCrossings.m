function out = GetZeroCrossings(data)
%function out = GetZeroCrossings(data)
% returns the indicies of the zero crossings
% the indicies are the point before the crossing
% or in the case of a zero in the data, at the zero
% touching zero is considered crossing
% assumes data is a single vector
out = find(diff(sign(data)));

% out is now all the zero crossings, EXCEPT
% sign gives 0 the value of 0, so if there is an exact 0 in the data
% you end up with two crossings at the point, one before the zero and one at the zero.  We want to find and remove the excess crossing
zs = find(~data);           % find the zeros
out = setxor(out, zs-1);    % remove the values before the zero, leaving the zero crossing at the index of the zero
