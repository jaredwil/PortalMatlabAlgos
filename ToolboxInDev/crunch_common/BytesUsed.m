function out = BytesUsed(filetype);
%function out = BytesUsed(filetype);
% pass a file name and path, and the number of bytes used will be returned
% ie, out = BytesUsed('f:\fulleeg\*.eeg);  will return the nuber of bytes
% used for eeg files in the directory f:\fulleeg
a = dir(filetype);
out = 0;
for i = 1:size(a,1)
    out = out+a(i).bytes;
end