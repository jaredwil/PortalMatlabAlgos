function [signals, pc] = PCA_reduce_dimensionality(data, pct)
% data should enter as data streams (rows) by samples (cols)
% returns the rotated data removing all axes possible while retaining
% pct percentage of the variance of the original data
% also returns the matrix used to rotate the data, pc
% use like this rotated = pc'*original

% perform rotation using pca
try
    [signals, pc, v] = pca1(data);
catch
    [signals, pc, v] = pca2(data);  % use svd to catch singularities
end
% v are the variances, normalize and print to screen
v = v/sum(v);
v;


if exist('pct', 'var')   % user specified amount of variance
    while sum(v) >= pct
        v(end) = [];
        signals(end,:) = [];
    end

else    % assume using for clustering, find the amount of variance to remove which 
        % is greater than the extra distance involved in keeping the extra
        % dimension
        % need this equztion so can solve for any number
        %this is the diff of the multidimensional mean distance function
        
        % remove the ones where you loose less information by reducing
        % dimensions than you do using the extra dimension in
        % multidimensional clustering
        for i = 1:length(v)
            mgain(i) = 1/(2^(1/i));
        end
        out = -(diff(v)' + diff(mgain))';
        inx = find(out < 0);
        if ~isempty(inx)
            signals = signals(1:inx(1),:);
        end
        % else if isempty(inx) then all dimensions are usefull
end

%return
fprintf('Amount of variance accounted for by dimensions after PCA reduction:\n');
for i = 1:size(signals,1)
    fprintf('%d: %2.5f\n',i, v(i));
end