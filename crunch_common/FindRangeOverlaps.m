function out = FindRangeOverlaps(a,b)
%function out = FineRangeOverlaps(a,b);
% given two lists of ranges a and b (each of which has two columns, a start
% column and a stop column) the function returns the row indicies of ranges in
% a which overlap at least one point with at least one range in b

%ought to be able to vectorize this
out = [];
for i = 1:size(a,1)
    al = a(i,1):a(i,2);
    for j = 1:size(b,1)
        if ~isempty(find(al >= b(j,1) & al <= b(j,2), 1))
            out = [out, i];
            break
        end
    end
end


