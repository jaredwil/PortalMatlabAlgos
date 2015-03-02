function out = BreakEEG(outsize, filename, OutPath);
%function out = BreakEEG(outsize, filename);
% Call to breakup large eegfiles to small ones - or combine small ones into
% larger ones.  Output files are placed in the same directory as the input file(s).
% If there are associated video files, these will not work
% with the output of this program.
%
% USAGE:
%  BreakEEG;
%  will create outputfiles 20MB large
%  an inteactive window will open for selection of the input file
%
%  BreakEEG(outsize);
%  will create outputfiles of size outsize, outsize is in MB
%  an inteactive window will open for selection of the input file
%
%  BreakEEG(outsize, filename);
%  filename must be the entire path and name to the eegfile to be opened
%
% NOTE:
% the output files will have the same name as the input files with 'b_'
% prepended to the file name
%
% returns 0 if the input file cannot be opened, else 1

global eeghdr;   % header information of the eeg file
global OUTFILESIZE; % called in write2bni.m

if ~exist('filename')
  out = GetEEGData('init');
else
  out = GetEEGData('init', filename);
end
        
if isempty(out)
    out = 0;
    return
else
    out = 1;
end

%DEFAULTS you can change
prepend =  '';    % to distinguish output files from input files
hunk = 500000;       % number of points per channel to grab with each cycle - bigger is faster if your computer has enough memory
if ~exist('outsize')
    outsize = 50;   % 500 meg default output file size
end

if ~exist('OutPath')
OutPath = 'e:\b250Hz\';
end
% init output files
outname = [OutPath prepend eeghdr.fname(1:end-4)];

%write2bni([],outname,eeghdr.rate,eeghdr.starttime,eeghdr.startdate,eeghdr.labels,eeghdr.UvPerBit, []);
jwrite2bni([],outname,eeghdr.rate,[eeghdr.starttime 0],eeghdr.startdate,eeghdr.labels,eeghdr.UvPerBit, []);

OUTFILESIZE = outsize*1000000;  % this must be set after the first call to write2bni;

% write to output files
for i = 1:hunk:eeghdr.PtIndx(end).last
    data = GetEEGData('getdata',[i, hunk]);
    jwrite2bni(data');
end 

% close files
jwrite2bni([]);  % close last output data file
GetEEGData('closedatafile'); % close last input data file


