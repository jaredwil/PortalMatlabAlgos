function [] = f_dichter_test_eeg2mef(animalDir, dataBlockLen)
%   This is a generic function that converts data from the raw binary *.eeg 
%   format to MEF. Header information for this data is contained in the
%   *.bni files and the data is contained in the *.eeg files.  Files are
%   concatenated based on the time data in the .bni file, resulting in one
%   file per channel which includes all data sessions.
%
%   INPUT:
%       animalDir  = directory with one or more .eeg files for conversion
%       dataBlockLen = amount of data to pull from .eeg at one time, in hrs
%       gapThresh = duration of data gap for mef to call it a gap, in msec
%       mefBlockSize = size of block for mefwriter to wrte, in sec
%
%   OUTPUT:
%       MEF files are written to 'mef\' subdirectory in animalDir, ie:
%       Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000\mef\
%
%   USAGE:
%       eeg2mef('Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000',0.1,10000,10);
%
% datestr(timeVec(1)/1e6/3600/24)
%     dbstop in f_dichter_eeg2mef at 52;
%     

% use portal data -> checks that i'm using the right data and it checks
% that the mef conversion went ok
% reassign portal ids, get rid of existing data - need to check with joost
% test start time of data
% test the data points
% test end time?
% test metadata?

    dateFormat = 'mm/dd/yyyy HH:MM:SS';
    dateOffset = datenum('1/1/1970 0:00:00',dateFormat);  % portal time
    
    EEGList=dir(fullfile(animalDir,'*.eeg'));

    assert(length(EEGList) >= 1, 'No data found in directory.');
    fid=fopen(fullfile(animalDir,[EEGList(1).name(1:8) '.bni']));   % METADATA IN BNI FILE
    metadata=textscan(fid,'%s = %s %*[^\n]');
    fclose(fid);

    % get number of channels, sampling frequency, and channel labels
    animalName = sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4);
    animalVideo = metadata{1,2}(strcmp(metadata{:,1},'Comment'));
    animalSF = str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate')));
    animalNChan = str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile')));
    animalVFactor = str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')});
    chanLabels = strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),',');

    outputDir = fullfile(animalDir, 'mef');
    if ~exist(outputDir, 'dir');
      mkdir(outputDir);
    end

    % convert one channel at a time
    for c = 1: animalNChan
%       mefFile = fullfile(outputDir, ['Dichter_' animalName '_ch' num2str(c, '%0.2d') '_' chanLabels{c} '.mef']);
%       h = edu.mayo.msel.mefwriter.MefWriter(mefFile, mefBlockSize, animalSF, gapThresh); 
%       h.setSubjectID(animalName);
%       h.setUnencryptedTextField(animalVideo);
%       h.setSamplingFrequency(animalSF);
%       h.setPhysicalChannelNumber(c);
%       h.setVoltageConversionFactor(animalVFactor);
%       h.setChannelName(chanLabels{c});
      reverseStr = '';

      for f = 1:length(EEGList)
        try
          % confirm file name matches expected name format - to weed out unrelated files
          assert(~isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')), 'File name mismatch: %s', EEGList(f).name); 

          fid = fopen(fullfile(animalDir,[EEGList(f).name(1:8) '.bni']));    % METADATA IN BNI FILE
          metadata = textscan(fid,'%s = %s %*[^\n]');
          fclose(fid);

          % confirm metadata matches for each file
          assert(strcmp(sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4),animalName),'Animal name mismatch: %s', EEGList(f).name);
          assert(strcmp(metadata{1,2}(strcmp(metadata{:,1},'Comment')),animalVideo),'Animal video mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate'))) == animalSF, 'Sampling rate mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile'))) == animalNChan, 'Number of channels mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')}) == animalVFactor, 'Voltage calibration mismatch: %s', EEGList(f).name);
          assert(sum(cellfun(@strcmp,chanLabels,strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),','))) == length(chanLabels), 'Channel label mismatch: %s',EEGList(f).name);
          
          recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
          recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
          dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
          startTime = (dateNumber - dateOffset + 1) * 24 * 3600 * 1e6;

          fid2=fopen(fullfile(animalDir,EEGList(f).name));                  % DATA IN .EEG FILE
          fseek(fid2,0, 1);
          numSamples=(ftell(fid2)/animalNChan)/2;         % /number of channels / 2 (==> int16)
          fclose(fid2);
          m=memmapfile(fullfile(animalDir,EEGList(f).name),'Format',{'int16',[animalNChan numSamples],'x'});

          blockSize = dataBlockLen * 3600 * animalSF;  % amount of data to pull from EEG file at one time, in samples
          numBlocks = ceil(numSamples/blockSize);
          for b = 1: numBlocks
            curPt = 1 + (b-1)*blockSize;
            endPt = min([b*blockSize numSamples]);
            blockOffset = 1e6 * (b-1) * blockSize / animalSF;

            data = m.data.x(c,curPt:endPt);
            timeVec = 0:length(data)-1;
            timeVec = timeVec ./ animalSF * 1e6;
            timeVec = timeVec + startTime + blockOffset;
            msg = sprintf(...
              'Writing %s channel %d. Percent finished: %3.1f. %s \\n',...
              EEGList(f).name, c, 100*b/numBlocks, ...
              datestr(timeVec(1)/1e6/3600/24));
            fprintf([reverseStr, msg]);
            reverseStr = repmat(sprintf('\b'), 1, length(msg)-1);
  %           datestr(timeVec(1)/1e6/3600/24)
  %           datestr(timeVec(end)/1e6/3600/24)

            try
              h.writeData(data, timeVec, length(data));
            catch err2
              h.close();
              rethrow(err2);
            end
          end
        catch err
          if (isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')))
            fprintf('Disregarding %s\n', EEGList(f).name);
            reverseStr = '';
          else
            h.close();
            rethrow(err);
          end
        end
      end
      h.close();
      toc
    end
end