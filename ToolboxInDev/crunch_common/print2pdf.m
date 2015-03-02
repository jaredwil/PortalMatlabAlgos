function out = print2pdf(h, fname);
% creates a pdf of the name fname of the figure corresponding to the handle passed
% fname should have not extension, '.pdf' will be appended.
% returns a 1 is sucessfull, 0 if failed.

spath = pwd;
cd 'c:\mfiles\Crunch_common'
fprintf('Printing to PDF file %s...', [fname '.pdf']);
lasterr('');
savefig(fname ,'pdf');
l = lasterror;
if isempty(l.message);
    fprintf('.done\n');
    out = 1;
else
    fprintf('  Failed.\n');
    out = 0;
end
cd (spath)
