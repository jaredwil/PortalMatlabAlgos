function [] = f_eeg2mef(animalDir, dataBlockLen, gapThresh, mefBlockSize)
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
%       f_eeg2mef('Z:\public\DATA\Animal_Data\DichterMAD\r097\Hz2000',0.1,10000,10);
%
% datestr(timeVec(1)/1e6/3600/24)
%    dbstop in f_eeg2mef at 53
%     

    % portal time starts at midnight on 1/1/1970
    dateFormat = 'mm/dd/yyyy HH:MM:SS';
    dateOffset = datenum('1/1/1970 0:00:00',dateFormat);  % portal time

    % get list of data files in the animal directory
    % remove files that do not match the r###_### naming convention
    % remove BNI files
    % and remove eeg files with less than 100 kb - the recording system
    % kicks to the next file at 0:00 and will sometimes leave a tiny file
    % with < 1 sec of data, the timestamps overlap, & this causes an error
    EEGList = dir(fullfile(animalDir,'*'));
    removeThese = false(length(EEGList),1);
    for f = 1:length(EEGList)
      if (isempty(regexpi(EEGList(f).name,'r\d{3}_\d{3}\.'))) || ...
        (~isempty(regexpi(EEGList(f).name,'bni'))) 
        removeThese(f) = true;
      elseif (EEGList(f).bytes < 100000)
        removeThese(f) = true;       
      end
    end
    EEGList(removeThese) = [];
    
    [~,IX] = sort([EEGList.datenum]); % sort EEGList by when files were saved
    EEGList = EEGList(IX);

    % confirm at least one eeg file exists, if so, then open the first
    % bni file to get the metadata for the animal
    assert(length(EEGList) >= 1, 'No data found in directory.');
    try % sometimes the bni files have different extensions
      if (regexp(EEGList(1).name,'eeg'))
        bni_name = fullfile(animalDir,[EEGList(1).name(1:8) '.bni']);
      else
        bni_name = fullfile(animalDir,[EEGList(1).name '.bni']);
      end
      fid=fopen(bni_name);   % METADATA IN BNI FILE
      metadata=textscan(fid,'%s = %s %*[^\n]');
      fclose(fid);
    catch
      try 
        if (regexp(EEGList(1).name,'eeg'))
          bni_name = fullfile(animalDir,[EEGList(1).name(1:8) '.bni_orig']);
        else
          bni_name = fullfile(animalDir,[EEGList(1).name '.bni_orig']);
        end
        fid=fopen(bni_name);   % METADATA IN BNI FILE
        metadata=textscan(fid,'%s = %s %*[^\n]');
        fclose(fid);
      catch
        fprintf('Check BNI file exists: %s\n',bni_name);
        keyboard;
      end
    end

    % get number of channels, sampling frequency, channel labels...
    animalName = sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4);
    animalVideo = metadata{1,2}(strcmp(metadata{:,1},'Comment'));
    animalSF = str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate')));
    animalNChan = str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile')));
    animalVFactor = str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')});
    chanLabels = strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),',');

    % create output directory (if needed) for mef files
    outputDir = fullfile(animalDir, 'mef');
    if ~exist(outputDir, 'dir');
      mkdir(outputDir);
    end

    % convert one channel at a time
    for c = 1: animalNChan
      % open mef file, write metadata to the mef file
      mefFile = fullfile(outputDir, ['Dichter_' animalName '_ch' num2str(c, '%0.2d') '_' chanLabels{c} '.mef']);
      h = edu.mayo.msel.mefwriter.MefWriter(mefFile, mefBlockSize, animalSF, gapThresh); 
      h.setSubjectID(animalName);
      h.setUnencryptedTextField(animalVideo);
      h.setSamplingFrequency(animalSF);
      h.setPhysicalChannelNumber(c);
      h.setVoltageConversionFactor(animalVFactor);
      h.setChannelName(chanLabels{c});

      % run through each file in the directory and append it to mef file
      for f = 1:length(EEGList)
        try
          % open BNI file to get metadata and recording start for this file
          try % sometimes the files have different extensions
            if (regexp(EEGList(f).name,'eeg'))
              bni_name = fullfile(animalDir,[EEGList(f).name(1:8) '.bni']);
            else
              bni_name = fullfile(animalDir,[EEGList(f).name '.bni']);
            end
            fid=fopen(bni_name);   % METADATA IN BNI FILE
            metadata=textscan(fid,'%s = %s %*[^\n]');
            fclose(fid);
          catch
            try
              if (regexp(EEGList(f).name,'eeg'))
                bni_name = fullfile(animalDir,[EEGList(f).name(1:8) '.bni_orig']);
              else
                bni_name = fullfile(animalDir,[EEGList(f).name '.bni_orig']);
              end
              fid=fopen(bni_name);   % METADATA IN BNI FILE
              metadata=textscan(fid,'%s = %s %*[^\n]');
              fclose(fid);
            catch
                fprintf('Check BNI file exists: %s\n',bni_name);
                keyboard;
            end
          end

          % confirm metadata matches for each file
          assert(strcmp(sscanf(char(metadata{1,2}(strcmp(metadata{:,1},'eeg_number'))),'%c',4),animalName),'Animal name mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate'))) == animalSF, 'Sampling rate mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile'))) == animalNChan, 'Number of channels mismatch: %s', EEGList(f).name);
          assert(str2double(metadata{1,2}{strcmp(metadata{:,1},'UvPerBit')}) == animalVFactor, 'Voltage calibration mismatch: %s', EEGList(f).name);
          assert(sum(cellfun(@strcmp,chanLabels,strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),','))) == length(chanLabels), 'Channel label mismatch: %s',EEGList(f).name);
          
          % convert start time of recording to microseconds from 1/1/1970
          recordDate = char(metadata{1,2}(strcmp(metadata{:,1}, 'Date')));
          recordTime = char(metadata{1,2}(strcmp(metadata{:,1}, 'Time')));
          dateNumber = datenum(sprintf('%s %s', recordDate, recordTime), dateFormat);
          startTime = (dateNumber - dateOffset + 1) * 24 * 3600 * 1e6;

          % map timeseries data to memmap structure for fast read/write
          fid2=fopen(fullfile(animalDir,EEGList(f).name));                  % DATA IN .EEG FILE
          fseek(fid2,0, 1);
          numSamples=(ftell(fid2)/animalNChan)/2;         % /number of channels / 2 (==> int16)
          fclose(fid2);
          m=memmapfile(fullfile(animalDir,EEGList(f).name),'Format',{'int16',[animalNChan numSamples],'x'});

          % calculate end time of recording for file, output to display
          fileEnd = startTime + numSamples/animalSF*1e6;
          recordEnd = datestr(datenum(fileEnd/1e6/3600/24)+dateOffset-1);
          fprintf('file: %s (%d/%d)   start: %s %s   end: %s   chan: %d/%d\n',...
            EEGList(f).name,f,length(EEGList),recordDate,recordTime,...
            recordEnd, c, animalNChan);

          % need to pull small blocks of data from memmap file
          blockSize = dataBlockLen * 3600 * animalSF;  % amount of data to pull from EEG file at one time, in samples
          numBlocks = ceil(numSamples/blockSize);
          reverseStr = '';
          % write data block by block to mef file
          for b = 1: numBlocks
            curPt = 1 + (b-1)*blockSize;
            endPt = min([b*blockSize numSamples]);
            blockOffset = 1e6 * (b-1) * blockSize / animalSF;

            % create time, data vectors
            data = m.data.x(c,curPt:endPt);
            timeVec = 0:length(data)-1;
            timeVec = timeVec ./ animalSF * 1e6;
            timeVec = timeVec + startTime + blockOffset;
%             msg = sprintf(...
%               'Writing %s channel %d. Percent finished: %3.1f. %s \\n',...
%               EEGList(f).name, c, 100*b/numBlocks, ...
%               datestr(timeVec(1)/1e6/3600/24));
%             fprintf([reverseStr, msg]);
%             reverseStr = repmat(sprintf('\b'), 1, length(msg)-1);

            % send time, data vectors to mef file
            try
              h.writeData(data, timeVec, length(data));
            catch err2
              h.close();
              disp(err2.message);
              rethrow(err2);
            end
          end
        % in case of trouble above, be sure to close file before exiting
        catch err
          if (isempty(regexp(EEGList(f).name,'r\d{3}_\d{3}.eeg')))
            fprintf('Disregarding %s\n', EEGList(f).name);
            reverseStr = '';
          else
            h.close();
            disp(err.message);
            rethrow(err);
          end
        end
      end
      h.close();
      toc
    end
end