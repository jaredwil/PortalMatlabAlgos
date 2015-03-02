function out = ChangeLabels(action, data)
global cl

out = 1;
if ~exist('action','var') || isempty(action)
    action = 'init';
end


switch action

    case 'init'
        cl = [];
        cl.labels = [];
        cl.fname = [];
        cl.current_channel = 1;
        cl.new_label = 1;
        cl.start_labels = [];
        cl.new_labels = [];
        cl.possible_labels{1} = 'L_DG';
        cl.possible_labels{2} = 'R_DG';
        cl.possible_labels{3} = 'L_CA1';
        cl.possible_labels{4} = 'R_CA1';
        cl.possible_labels{5} = 'L_CTX';
        cl.possible_labels{6} = 'R_CTX';
        cl.possible_labels{7} = 'L_SCREW';
        cl.possible_labels{8} = 'R_SCREW';
        cl.possible_labels{9} = 'NOT_USED';
        cl.possible_labels{10} = 'L_HIPP';
        cl.possible_labels{11} = 'R_HIPP';
        cl.possible_labels{12} = 'L_UNKNOWN';
        cl.possible_labels{13} = 'R_UNKNOWN';

        ChangeLabels('open_control_figure');
        ChangeLabels('open_eeg_file');


    case 'open_eeg_file'
        set(cl.hcln, 'enable', 'off');
        cl.ID = inputdlg('Enter ID of animal', 'Change Labels', 1);
        if isempty(cl.ID); return; end
        update_statusbar(cl.cfig, ['searching for eeg files for ' cl.ID{1} ' ...']);
        if isempty(GetEEGData(cl.ID{1}))
            out = 0;
            update_statusbar(cl.cfig, ['Failed to find EEG files for animal ' cl.ID{1}]);
            return;
        end
        cl.fname = GetEEGData('getfilename');

        update_statusbar(cl.cfig, ['searching through all sessions of ' cl.ID{1} ' ...']);
        cl.labels = GetEEGData('getlabels');
        while ~isempty(GetEEGData('getNextSession'))
            lab = GetEEGData('getlabels');
            if length(lab) > length(cl.labels);
                cl.lcables = lab;
            end
            last = GetEEGData('getsession');
        end
        GetEEGData('setsession', 0);
        for i = 1:size(cl.labels,1);
            cl.cell_labels{i} = cl.labels(i,:);
            cl.start_labels{i} = sprintf('%d    %s',i, cl.labels(i,:));
        end
        ChangeLabels('generate_new_labels');
        set(cl.hl(1), 'string', cl.start_labels);
        set(cl.hl(2), 'string', cl.new_labels);
        set(cl.h(2), 'string', ['file:    ' GetEEGData('getpathname')  GetEEGData('getfilename')]);
        set(cl.hcln, 'enable', 'on');
        update_statusbar(cl.cfig, ['opened file  ' GetEEGData('getpathname')  GetEEGData('getfilename') ',  sessions 000 to ' sprintf('%03d',last)]);


    case 'generate_new_labels'
        for i = 1:size(cl.labels,1);
            cl.new_labels{i} = sprintf('%d    %s',i, cl.labels(i,:));
        end
        if length(cl.labels) >= 4
            cl.new_labels{1} = sprintf('%d    %s',1, cl.possible_labels{1});
            cl.new_labels{2} = sprintf('%d    %s',2, cl.possible_labels{3});
            cl.new_labels{3} = sprintf('%d    %s',3, cl.possible_labels{2});
            cl.new_labels{4} = sprintf('%d    %s',4, cl.possible_labels{4});
        end
        if length(cl.labels) == 8
            cl.new_labels{5} = sprintf('%d    %s',5, cl.possible_labels{5});
            cl.new_labels{6} = sprintf('%d    %s',6, cl.possible_labels{7});
            cl.new_labels{7} = sprintf('%d    %s',7, cl.possible_labels{9});
            cl.new_labels{8} = sprintf('%d    %s',8, cl.possible_labels{9});
        end

    case 'select_channel'
        cl.current_channel = get(cl.hl(str2double(data)), 'value') ;
        set(cl.hl, 'value', cl.current_channel);

    case 'set_new_label'
        cl.new_labels{cl.current_channel} = sprintf('%d    %s',cl.current_channel, cl.possible_labels{get(cl.hnewl, 'value')});
        set(cl.hl(2), 'string', cl.new_labels);
        update_statusbar(cl.cfig, sprintf('Set label for channel %d to %s', cl.current_channel, cl.possible_labels{get(cl.hnewl, 'value')}));


    case 'open_control_figure'

        position = [30 74 560 426];
        top = position(3) - position(1) -170;
        col1s = 30;
        col1w = 110;
        col2s = col1s+col1w + 40;
        col2w = col1w;
        col3s = col2s+col2w + 120;
        col3w = col1w;
        list_height = 17*10;

        cl.cfig = figure;
        set(cl.cfig, 'UserData', [], ...
            'MenuBar','none', ...
            'tag','control_figure',...
            'Name','Change EEG Channel Labels', ...
            'Numbertitle','off',...
            'Units', 'points',...
            'Position', position)
        cl.h = uimenu('Parent',cl.cfig, ...
            'Label','&File', ...
            'Tag','rhFile');
        h2 = uimenu('Parent',cl.h, ...
            'Callback','ChangeLabels open_eeg_file;', ...
            'Label','&Open eeg...', ...
            'Tag','open_eeg_file');
        h2 = uimenu('Parent',cl.h, ...
            'Callback','ChangeLabels exit;', ...
            'separator','on',...
            'Label','E&xit', ...
            'Tag','exit');

        cl.h(2) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','left', ...
            'FontSize', 14,...
            'FontWeight', 'bold', ...
            'Position',[col1s, top+20, col1w+col2w+col3w, 17], ...
            'String',['file:   ' cl.fname], ...
            'Style','text', ...
            'Enable', 'on',...
            'Tag','tfname');

        cl.h(end+1) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','center', ...
            'FontSize', 12,...
            'FontWeight', 'normal', ...
            'Position',[col1s, top-10, col1w, 15], ...
            'String','starting labels', ...
            'Style','text', ...
            'Enable', 'on',...
            'Tag','tstart_labels');

        cl.hl(1) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'Callback','ChangeLabels select_channel 1;', ...
            'ListboxTop',1, ...
            'Max', 1, 'Min', 1, ...
            'Position',[col1s, top-15-list_height, col1w, list_height], ...
            'String',cl.start_labels, ...
            'fontsize', 12, ...
            'Style','listbox', ...
            'Enable', 'on',...
            'Tag','select_channels', ...
            'Value',cl.current_channel);

        cl.h(end+1) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','center', ...
            'FontSize', 12,...
            'FontWeight', 'normal', ...
            'Position',[col2s, top-10, col2w, 15], ...
            'String','choose a new label', ...
            'Style','text', ...
            'Enable', 'on',...
            'Tag','tstart_labels');

        cl.hnewl = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'ListboxTop',1, ...
            'Max', 1, 'Min', 1, ...
            'Position',[col2s, top-15-list_height, col2w, list_height], ...
            'String',cl.possible_labels, ...
            'fontsize', 12, ...
            'Style','listbox', ...
            'Enable', 'on',...
            'Tag','possible_labels', ...
            'Value',cl.new_label);

        cl.h(end+1) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'Callback','ChangeLabels set_new_label;', ...
            'Position',[col2s+col2w+40, top-15-list_height/2, 40, 25], ...
            'String','>>', ...
            'fontsize', 14, ...
            'FontWeight', 'bold', ...
            'Enable', 'on',...
            'Tag','set_new_label');

        cl.h(end+1) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','center', ...
            'FontSize', 12,...
            'FontWeight', 'normal', ...
            'Position',[col3s, top-10, col3w, 15], ...
            'String','new labels', ...
            'Style','text', ...
            'Enable', 'on',...
            'Tag','tnew_labels');

        cl.hl(2) = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'Callback','ChangeLabels select_channel 2;', ...
            'ListboxTop',1, ...
            'Max', 1, 'Min', 1, ...
            'Position',[col3s, top-15-list_height, col3w, list_height], ...
            'String',cl.new_labels, ...
            'fontsize', 12, ...
            'Style','listbox', ...
            'Enable', 'on',...
            'Tag','select_channels', ...
            'Value',cl.current_channel);

        cl.hcln = uicontrol('Parent',cl.cfig, ...
            'Units','points', ...
            'Callback','ChangeLabels run;', ...
            'Position',[col3s, top-60-list_height, col3w, 20], ...
            'String','change labels now', ...
            'fontsize', 10, ...
            'FontWeight', 'bold', ...
            'Enable', 'off',...
            'Tag','change_now');

        cl.statusbar =render_statusbar(cl.cfig, 'ChangeLabels - written by JGK 07-May-2009 (jkeating@mail.med.upenn.edu)');  % put the status bar on the figure

    case 'putline'
        update_statusbar(cl.cfig, data);
        fprintf([data '\n']);



    case 'run'
        set(cl.hcln, 'enable', 'off');
        next = 1;
        newlabels = [];
        c_data = zeros(1:length(cl.new_labels));
        for i = 1:length(cl.new_labels)
            nlabels{i} = strtrim(cl.new_labels{i}(3:end));
            newlabels = [newlabels nlabels{i} ','];
            if i < 5; c_data(i) = 0; end
            if strcmp('NOT', nlabels{i}(1:3)); c_data(i) = 4; end;
        end
        ChangeLabels('putline', 'Opening 250Hz data');

        a = dir([GetEEGData('getpathname') cl.ID{1} '*.bni']);  % get all the bni files
        for j = 1:length(a)
            BNIfile = a(j).name;
            OrigBNIfile = [BNIfile '_orig'];
            ChangeLabels('putline', sprintf('Backing up %s to %s', BNIfile, OrigBNIfile));
            dos(['rename ' GetEEGData('getpathname') BNIfile ' ' OrigBNIfile]);

            fo = fopen([GetEEGData('getpathname') OrigBNIfile], 'r');
            fn = fopen([GetEEGData('getpathname') BNIfile],'w');
            line = fgetl(fo);
            while 1,
                if ~ischar(line), break; end  % done
                if length(line) > 12 & strcmp('MontageRaw',line(1:10)); %#ok<AND2>
                    fprintf(fn, ['MontageRaw = ' newlabels '\n']);
                elseif length(line) > 7 & strcmp('0.0000',line(1:6)); %#ok<AND2>
                    fprintf(fn,'%s\n', line);
                    for i = 1:length(nlabels);
                        line = fgetl(fo);
                        fprintf(fn,'%s,,200,,,,%d,EEG\n', nlabels{i},c_data(i));
%                        fprintf(fn,'%s,,,,,,,EEG\n', nlabels{i});
                    end
                else
                    fprintf(fn,'%s\n', line);
                end
                line = fgetl(fo);
            end
            fclose(fo);
            fclose(fn);
        end
        fclose all
        ChangeLabels('putline', '250Hz data done!');



        ChangeLabels('putline', 'Opening 2000Hz data');
        GetEEGData(cl.ID{1}, '2000');
        try
            a = dir([GetEEGData('getpathname') cl.ID{1} '*.bni']);  % get all the bni files
        catch
            msgbox('2Kz data not found!!', 'missing data', 'error');
            ChangeLabels('putline', '250Hz data done.  2KHz ses 000 data not found, so 2KHz not done!');
            cl.start_labels = cl.new_labels;
            set(cl.hl(1), 'string', cl.start_labels);

            set(cl.hcln, 'enable', 'on');
            return
        end
        for j = 1:length(a)
            BNIfile = a(j).name;
            OrigBNIfile = [BNIfile '_orig'];
            ChangeLabels('putline', sprintf('Backing up %s to %s', BNIfile, OrigBNIfile));
            dos(['rename ' GetEEGData('getpathname') BNIfile ' ' OrigBNIfile]);

            fo = fopen([GetEEGData('getpathname') OrigBNIfile], 'r');
            fn = fopen([GetEEGData('getpathname') BNIfile],'w');
            line = fgetl(fo);
            while 1,
                if ~ischar(line), break; end  % done
                if length(line) > 19 & strcmp('location',line(1:8)); %#ok<AND2>
                    if ~isempty(GetEEGData('getcagenumber'))
                        fprintf(fn,'location = %d\r\n', eegfile.cagenumber);
                    else
                        fprintf(fn,'%s\n', line);                        
                    end
                end
                if length(line) > 12 & strcmp('MontageRaw',line(1:10)); %#ok<AND2>
                    fprintf(fn, ['MontageRaw = ' newlabels '\n']);
                elseif length(line) > 7 & strcmp('0.0000',line(1:6)); %#ok<AND2>
                    fprintf(fn,'%s\n', line);
                    for i = 1:length(nlabels);
                        line = fgetl(fo);
                        fprintf(fn,'%s,,200,,,,%d,EEG\n', nlabels{i},c_data(i));
                    end
                else
                    fprintf(fn,'%s\n', line);
                end
                line = fgetl(fo);
            end
            fclose(fo);
            fclose(fn);
        end
        fclose all
        ChangeLabels('putline', '2000Hz data done!');

        ChangeLabels('putline', 'all done!');

        cl.start_labels = cl.new_labels;
        set(cl.hl(1), 'string', cl.start_labels);

        set(cl.hcln, 'enable', 'on');

end
