function out = CutSeizure(sf, OutPath, DataPath, AVIpath);
global eeghdr;

load
closefiledelaysec = 1;   % number of seconds after the last frame is writen before the file is closed (time stamped)
startfiledelaysec = 3;   % number of seconds after the file is started before the first frame is written.
PreSzTime = 60; % seconds
CutTime =  180; % total time to cut
hunk = 100;    % number of frames to cut at one time: more is faster but takes more memory
out = 1;
if 0

    if ~exist('sf', 'var') || isempty(sf)
        try
            dp = GetResultsDataPath;
        catch
            dp = [];
        end
        source = '*_Seizures_examined.mat';
        FileName = [];
        [FileName, DPath] = uigetfile(source, 'Open the file containing the seizures you want to cut');
        if ~(FileName)
            out = [];
            fprintf('No seizure list file selected, aborting\n');
            return
        end
        load([DPath FileName]);
    end
    times = sf.gdf(find(sf.gdf(:,1) == 990),2);
    starttime = datevec(sf.sessionstart);
    datenum_times = repmat(starttime, length(times), 1);
    datenum_times(:,6) = datenum_times(:,6) + (times/sf.rate) - PreSzTime;  % add offset seconds
    datenum_times = datenum(datenum_times);  % turn datevec into a date number

    if 0
        if ~exist('DataPath', 'var') || isempty(DataPath)
            try
                % check if already open
                if ~strcmp([eeghdr.DataPath GetName('name', eeghdr.FileName)], [sf.DataPath GetName('name', sf.DataFile)])
                    okay = GetEEGData('init',[sf.DataPath GetName('name', sf.DataFile) '.bni']);
                else
                    okay = 1;
                end
            catch
                % check if in same location as when it was analyzed
                okay = GetEEGData('init',[sf.DataPath GetName('name', sf.DataFile) '.bni']);
            end
            if isempty(okay)
                % ask user to find them
                fprintf('Cannot find data.  Please open the data file associated with %s.\n', GetName('name', sf.DataFile));
                okay = GetEEGData;
            end
            if isempty(okay)
                fprintf('Exiting because cannot find data files for %s\n', GetName('name', sf.DataFile));
                return
            end
            DataPath = eeghdr.DataPath;
        end
    end

    if ~exist('AVIPath', 'var') || isempty(AVIPath)
        source = ['*.avi'];
        FileName = [];
        [FileName, AVIPath] = uigetfile(source, 'Open any one of the associated avi files');
        if ~(FileName)
            out = [];
            fprintf('No AVI file selected, aborting\n');
            return
        end
    end

    % sort files by creation time
    stop = 0;
    b = dir([AVIPath '*.avi']);
    s = zeros(1, length(b));
    fprintf('Sorting avi files. Please wait ...');
    for i = 1:size(b,1)  % sort by creation date
        av = aviinfo([AVIPath b(i).name]);
        s(i) = datenum(av.FileModDate);  %this is ~1second after video recording stoped (time stamp of file close)
    end
    [ss, is] =sort(s);
    for i = 1:length(ss)
        a(i).name = b(is(i)).name;
        a(i).time = s(is(i));
    end
    fprintf('  Done!\n');

    save
end

resetclocklist = 1;
if ~exist('resetclocklist') % a series of increasing datenum, times when the clock was reset
    resetclockList = [];
    drift = 0;
else
    resetclocklist(1) = datenum('18-Apr-2005 09:21:00');
    resetclocklist(2) = datenum('29-Apr-2005 13:32:50');
    resetclocklist(3) = datenum('16-May-2005 07:10:50');
    resetclocklist(4) = datenum('24-May-2005 09:36:00');
    resetclocklist(5) = datenum('13-Jun-2005 13:20:00');
    drift = 48240;  % my vid clock gains 1 sec every 48240 seconds
end


% got all the info we need, now go through the seiures one by one and cut
% them out

for i = 1:length(times)
    % get the eeg data
    % edata = GetEEGData('getdata', [GetEEGData('datetime2tick', times(i))-eeghdr.rate*PreSzTime, eeghdr.rate*CutTime]);

    TimeName = sprintf('%04d%02d%02d%02d%02d%02d', round(datevec(datenum_times(i))));  % This is the time of the seiure as a string
    n = strfind(sf.DataFile, '_');
    % make a name for the video output file
    vOutFileName = [OutPath sf.DataFile(1:n(1)) TimeName '.avi'];  % path\ID_time.avi

    % get the video
    % first find the file that starts the frames we want to clip: ss is a
    % list of the avi file close times.
    TimeToFind = datenum_times(i);
    if drift
        resettimes = resetclocklist - datenum_times(i);
        basis = find(resettimes < 0);
        subtractsec = floor(etime(datevec(datenum_times(i)), datevec(resetclocklist(basis(end))))/drift);
        TimeToFind = datevec(datenum_times(i)); 
        TimeToFind(6) = TimeToFind(6) - subtractsec;
        TimeToFind = datenum(TimeToFind);
    end
    vfileInx = find(ss > TimeToFind);    % it is sorted from first to last, so first on list has the (beginning) of the seizure
    vfileName = [AVIPath a(vfileInx(1)).name];           % start is somewhere in here
    info = aviinfo(vfileName);

    % now cut the frames we want: start at
    secbackintofile = etime(datevec(ss(vfileInx(1))), datevec(TimeToFind))-closefiledelaysec;   %the number of seconds back into the vid file to start at
    StartFrame = round(info.NumFrames - secbackintofile*info.FramesPerSecond);
    AddBlanks = 0;

    if secbackintofile > 60*60  % greater than one hour
        fprintf('All the video files are after the eeg data time (%s)!\n', TimeName);
    else

        if StartFrame < 1   % then some of the data is between files
            AddBlanks = 1 - StartFrame;   % we will put in blank frames as holders to show there is no data here
            StartFrame = 1;
        end
        FramesToCut = floor(CutTime*info.FramesPerSecond) - AddBlanks;  %Number of frames we want to take
        ExtraFrames = 0;
        if FramesToCut+StartFrame > info.NumFrames  % then we will need to get more frames than this file holds: next avi file
            ExtraFrames = FramesToCut+StartFrame - info.NumFrames;
            FramesToCut = info.NumFrames-StartFrame;
        end

        fprintf('Creating file %s\n', vOutFileName);
        m = avifile(vOutFileName);
        m.FPS = info.FramesPerSecond;
        m.Quality = 100;
        m.Keyframe = 1;
        m.Compression = 'Indeo5';

        % cut the frames out of this fill adding blanks, once we figure out the
        % size they should be
        if AddBlanks
            fprintf('adding blanks ...\n');
            AddBlanks
            frame = aviread(vfileName,1);   % read the first frame
            frame.cdata(:) = 0;
            for k = 1:AddBlanks
                m = addframe(m,frame);
            end
        end
        fprintf('Opening video file %s\n', vfileName);
        fprintf('adding frames ...');
        for k= StartFrame:hunk:StartFrame+FramesToCut  % this can add just a few more frames than needed: we don't care
            try
                frame = aviread(vfileName,k:k+hunk-1);
                m = addframe(m,frame);   % insert a hunk as a time for speed purposes
            catch
                frame = aviread(vfileName,k:info.NumFrames);  %if reading past end of file
                m = addframe(m,frame);   % insert a hunk as a time for speed purposes
            end
        end

        if ExtraFrames
            fprintf('adding blanks between files ...');
            % fill in blank between files
            frame = aviread(vfileName,1);   % read the first frame
            frame.cdata(:) = 0;
            for k = 1:round(info.FramesPerSecond*(closefiledelaysec+startfiledelaysec))   % if this is the end of the file don't worry about the exact number of frames
                m = addframe(m,frame);
                if k > ExtraFrames
                    break;
                end
            end
            ExtraFrames = ExtraFrames-k;  % whats left
        end

        if ExtraFrames > 0
            % check if at last avi file
            if vfileInx(2) > length(a)
                fprintf('Requested video cut extends past the recording time of the last avi file found!\n\n');
                m = close(m);
                return
            end
            % first go back to seconds to see where we want to go in the next
            % file
            vfileName = [AVIPath a(vfileInx(2)).name];           % start is somewhere in here
            fprintf('\nOpening video file %s\n', vfileName);
            fprintf('adding frames from 2ond file ...');
            info = aviinfo(vfileName);
            for k = 1:hunk:ExtraFrames  % this can add just a few more frames than needed: we don't care
                try
                    frame = aviread(vfileName,k:k+hunk-1);
                    m = addframe(m,frame);   % insert a hunk as a time for speed purposes
                catch
                    frame = aviread(vfileName,k:info.NumFrames);  %if reading past end of file
                    m = addframe(m,frame);   % insert a hunk as a time for speed purposes
                end
            end

        end
        fprintf(' Done!\n\n');
        m =close(m);
    end

end

function d = PaintFrame(frame, edata, Info);
for i = 1:length(out)
    d(i).cdata = frame(i).cdata(:,:,2);
    % here we paint the frame with the activity trace
    % we want to get the pixels to color, we need a [x,y] list
    % which we can offset by a y value to move up and down the
    % image
    d(i).cdata(find(d(i).cdata) == 256) == 255;
    d(i).cdata(YOff-5:YOff+2*YPixSize+5,:) = ceil(d(i).cdata(YOff-5:YOff+2*YPixSize+5,:)*0.65);  % darken the draw ara a bit
    

    startD = floor(frametic*(frameDataSize/Info.FramesPerSecond)) +1;

        if length(recdata) >= startD + 2*frameDataSize
            plotDataY = -recdata(startD:startD+2*frameDataSize,1);
            plotDataY = plotDataY - min(min(recdata));
            plotDataY = ceil(YPixSize*plotDataY/scalesz)+ YOff;
            plotDataX = ceil(XPixSize*(1:length(plotDataY))/length(plotDataY));
            for j = 1:length(plotDataX)
                d(i).cdata(plotDataY(j), plotDataX(j)) = 256;
            end

            plotDataY = -recdata(startD:startD+2*frameDataSize,2);
            plotDataY = plotDataY - min(min(recdata));
            plotDataY = ceil(YPixSize*plotDataY/scalesz)+ YOff + YPixSize;
            plotDataX = ceil(XPixSize*(1:length(plotDataY))/length(plotDataY));
            for j = 1:length(plotDataX)
                d(i).cdata(plotDataY(j), plotDataX(j)) = 256;
            end

        else
            moreData = 0;
        end
        fprintf('Frame %d of %d completed. \n', frametic+1, 1+StopFrame-StartFrame);
        %done
    end

    d(i).colormap = map;
    frametic = frametic +1;
end
end
