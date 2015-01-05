function []=eeg2mef(serverPath, subjectPath, subject)
%   This is a generic function that converts data from the raw binary *.eeg 
%   format to MEF. Header information for this data is contained in the
%   *.bni files and the data is contained in the *.eeg files.
%
%   INPUT:
%       serverPath  = path to public folder on mapped fourier
%       subjectPath = path to folder containing *.eeg files to be converted
%
%   OUTPUT:
%       MEF files are written to separate folder in subjectPath 
%
%   USAGE:
%       eeg2mef('/mnt/local/gdrive/public','/mnt/local/gdrive/public/DATA/Animal_Data/Dichter/r092/Hz250')

    dbstop in eeg2mef at 50;
    
%     javaaddpath(fullfile(serverPath,'USERS','anani','PORTAL','Tools','MEFwrite','MEF_writer.jar'))
%     import edu.upenn.cis.db.mefview.services.*
    EEGList=dir(fullfile(subjectPath,[subject,'*.eeg']));
    
    for j=1:length(EEGList)
        disp(['Processing EEGFile ', num2str(j), ' of ', num2str(length(EEGList))])
        disp('Reading metadata...')
        fid=fopen(fullfile(subjectPath,[EEGList(j).name(1:end-4),'.bni']));                    % METADATA IN BNI FILE
        metadata=textscan(fid,'%s = %s %*[^\n]');
        fclose(fid);
        
        fs=str2double(metadata{1,2}(strcmp(metadata{:,1},'Rate')));
        numChan=str2double(metadata{1,2}(strcmp(metadata{:,1},'NchanFile')));
        chanLabels=strsplit((metadata{1,2}{strcmp(metadata{:,1},'MontageRaw')}),',');
        
        disp('Reading EEG file...')
        fid2=fopen(fullfile(subjectPath,EEGList(j).name));                  % DATA IN .EEG FILE
        fseek(fid2,0, 1);
        numSamples=(ftell(fid2)/numChan)/2;         % /number of channels / 2 (==> int16)
        fclose(fid2);
        m=memmapfile(fullfile(subjectPath,EEGList(j).name),'Format',{'int16',[numChan numSamples],'x'});
        
        appendList=dir(fullfile(subjectPath,[EEGList(j).name(1:end-4),'.*']));
        numIX=1;
        fileNums=[];
        for t=0:length(appendList)-1
            if exist(fullfile(subjectPath,[EEGList(j).name(1:end-3),sprintf('%03d',t)]),'file')
                fileNums(numIX)=t;
                numIX=numIX+1;
            end
        end
        
        disp('Writing MEF file')
        mkdir (fullfile(subjectPath,[EEGList(j).name(1:end-4),'_mef']))
        cd (fullfile(subjectPath,[EEGList(j).name(1:end-4),'_mef']))
        blockSize = round(4000/fs);
        th = 100000;
        timestep = 1000000/fs;
        baseTime=timestep;
        
        for i=1:numChan
            disp(['Converting channel ' num2str(i),' of ', num2str(numChan)])
            data=m.Data.x(i,:);
            mw = edu.mayo.msel.mefwriter.MefWriter([chanLabels{i},'.mef'], blockSize, fs, th);
            time = baseTime: timestep: (length(data)*timestep);
            mw.writeData(data, time, length(data));
            
            baseTime2=time(end)+timestep;
            for p=fileNums
                disp(['appendFile ' sprintf('%03d',p),' of ', num2str(length(fileNums))])
                fid3=fopen(fullfile(subjectPath,[EEGList(j).name(1:end-3),sprintf('%03d',p)]));                  % DATA IN .EEG FILE
                fseek(fid3,0, 1);
                numSamples2=(ftell(fid3)/numChan)/2;         % /number of channels / 2 (==> int16)
                fclose(fid3);
                d=memmapfile(fullfile(subjectPath,[EEGList(j).name(1:end-3),sprintf('%03d',p)])...
                    ,'Format',{'int16',[numChan numSamples2],'x'});

                data2=d.Data.x(i,:);
                time2=baseTime2: timestep: baseTime2+(length(data2)*timestep);
                mw.writeData(data2, time2, length(data2));

                baseTime2=time2(end)+timestep;                
                clear data2 numSamples2 d    
             end
            mw.close;
        end
        clear data metadata
    end
    disp('Finished processing')
end