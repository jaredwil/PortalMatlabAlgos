%% this script will read data from .eeg files (Nicolet format) and convert
% it to .mef format.  The script uses the _eeg2mef function, which assumes
% data is stored in eeg files in a directory with this kind of path:
% Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000\r097_000.eeg
% output files will be written to ...\DichterMAD\mef\Dichter_r097_01.mef
% for channel 1, ...02.mef for channel 2, etc.

clear; clc; close all;
tic
addpath(genpath('C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data'));
addpath('C:\Users\jtmoyer\Documents\MATLAB\');
javaaddpath('C:\Users\jtmoyer\Documents\MATLAB\java_MEF_writer\MEF_writer.jar');

% define constants for simulation
run_these = 1; % 1:16, see dataKey
rootDir = 'Z:\public\DATA\Animal_Data\DichterMAD'; % directory with all the data
dataBlockLenHr = 0.1; % hours; size of data block to pull from .eeg file
mefGapThresh = 10000; % msec; min size of gap in data to be called a gap
mefBlockSize = 10; % sec; size of block for mefwriter to write

convert = 0;  % convert data y/n?
test = 1;     % test data y/n?

%% call f_dichter_eeg2mef to convert animal's files to mef
dataKey = f_create_data_key; % list of animal names

if convert
  for r = 1: length(run_these)
    animalDir = fullfile(rootDir,char(dataKey.animal_id(run_these(r))),'Hz2000');
    f_dichter_eeg2mef(animalDir, dataBlockLenHr, mefGapThresh, mefBlockSize);
  end
end

if test
  for r = 1: length(run_these)
    animalDir = fullfile(rootDir,char(dataKey.animal_id(run_these(r))),'Hz2000');
    f_dichter_test_eeg2mef(animalDir, dataBlockLenHr);
  end
end
