function out = project2vec(testvec, vectors);
%function out = project2vec(action, data);
% projects a matrix of vectors onto a test vector.
% returns the a scalar for each vector: the projection onto it normalized by the
% length of the test vector
%
% this program rotates about the zero axis, you need to translate your
% matrix so that it is centered where you want it.
% testvec is a row vector (1xn), vectors are a series of m row vectors (mxn)

[U, S, R] = svd(testvec);           % find the matrix to rotate with
rotated = vectors*R;                % apply the rotation
out = rotated(:,1)/norm(testvec);   % get the normalized length of the projection onto the test vec.