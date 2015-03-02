function out = ICA_RemoveEyeComponent(data);
%function out = ICA_RemoveEyeComponent(data);
% pass some data (time by chan), with the last two channels
% being EOG.  the contribution of the ICA EOG source will be removed and
% the result returned

verbose = 1;
showdata = 0;

[s1,s2]= size(data);
if s1>s2; data = data'; end
% get the projection and the mixing matricies
tic
[icasig, A, W] = fastica(data, 'verbose', 'off');
secs = toc;
if secs > 10
    fprint('There seems to be difficulties here...');
    [icasig, A, W] = fastica(data, 'verbose', 'off', 'initGuess', A, 'stabilization', 'on');
    fprintf('.done\n');
end
if showdata; figure; dplot(data');title('raw'); figure; dplot(icasig');title('IC projecitons'); end

% this logic is just to find the signal that is strongest on the
% last two channels (and of opposite sign on those channels)
b = abs(A);
c = (A(end-1,:).*A(end,:));
b(end-1,:) = abs(A(end-1,:) - A(end,:))/2;
b(end,:) = [];
b(end,(find(c > 0))) = 0;
[m,n] = max(b);

if verbose
    remove = find(n == size(b,1));
    if ~isempty(remove)
        fprintf('Removing contirbution of IC projction #%d\n', remove);
    else
        fprintf('No prominent eye signals\n');
    end
end

% here we reconstruct the data without the eye signals
keep = find(n ~= size(b,1));
out = A(:,keep)*icasig(keep,:);

if showdata; figure;dplot(out');title('cleaned'); end

meanvar = sum(A.^2).*sum((icasig').^2)/(size(A,1)-1)^2;  %Variance
meanvar = meanvar/sum(meanvar)