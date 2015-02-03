function result = JPSVars(action, data);
global jps;						% common vars for jeff's program suite
% jps.FileName;				% name of the currently loaded file, sans path
% jps.DataPath;				% path to the data (ie, gdf) file
% jps.WorkPath;				% where to put the intermediate files
% jps.SpikeIDRange;		% range of the neuron IDs in the gdf file
% jps.AlignIDRange;		% range of the align IDs in the gdf file
% jps.TicksPersec;			% ticks of the gdf file per millisecond
% jps.StartStopRange;	% maximum startsec and stop sec of PSTH analysis 
% jps.StartStop;			% current start sec and stop sec of the PSTH analysis 
% jps.AlignIDList;		% current valid alignID(s) in jps.gdf
% jps.SpikeIDList;    % current valid spikeID(s) in jps.gdf
% jps.AlignID;				% current align ID(s)
% jps.SpikeID;			  % current spike ID(s)
% jps.gdf;						% original loaded gdf file 
% jps.secBinWidth;			% bin width in milliseconds;

% Written by jeff keating														%
% jgk jeff@mulab.physiol.upenn.edu 12-feb-2002			%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% procedures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%case('getNewGDFFile');
% validates vars, gui GetFileName, loads gdf, fills Lists and validates AlignID and SpikeID
% returns 0 if failed: nothing changed except vars validated
%
%case('validate');
% returns a 0 if the vars aren't loaded and it can't find the JPSVars.mat file
%
%case('loadJPSVars');  
%
%case('getGDFFileName');
% jps.FileName unchanged if fails  
% returns a 0 if the user aborts without selecting a file
%
%case('loadGDF')
% jps.gdf unchanged if fails
%
%case('getAlignIDList')
% if fails jps.AlignIDList is set to [];
% jps.AlignID is left unchanged; call 'validateAlignID' to check
%
%case('validateAlignID')
% values of jps.AlignID not present in jps.AlignIDList are set to []  
% returns 0 if jps.AlignID returns empty  
%
%case('getSpikeIDList')
% if fails jps.SpikeIDList is set to [];
% jps.SpikeID is left unchanged; call 'validateSpikeID' to check
%
%case('validateSpikeID')
% values of jps.SpikeID not present in jps.SpikeIDList are set to []  
% returns 0 if jps.SpikeID returns empty  
%
%case('validateStartStop')
% pass data = 1 if start is to try to maintain the passed value  
% pass data = 2 if stop is to try to maintain the passed value  
% ensures jps.StartStop values are within the range of jps.StartStopRange
% makes sure start < stop by at least one binwidth
% if start < StartRange val start = StartRange val, similarly for stop
% this will fail if jps.secBinWidth > jps.StartStopRange(2) -jps.StartStopRange(1)

%case('JPSVarEntryDialog');
% pass data values to select which vars are to appear in the dialog
% 'spkIDrng' 		= 1
% 'algnIDrng'		= 2
% 'spkID'				= 3
% 'algnID'			= 4
% 'ticks'				= 5
% 'strtstprng'	= 6
% 'strstp'			= 7
% 'bw'					= 8
% 'datapth'			= 9
% 'wrkpth'			= 10

if ~exist('action')
	if isempty(jps)  
		JPSVars('loadJPSVars');  
	end  
	JPSVars('JPSVarEntryDialog',1:10);
	return
end  

result = 1;	% assume success;
switch(action)
	
case('getNewGDFFile');
	% validates vars, gui GetFileName, loads gdf, fills Lists and validates AlignID and SpikeID
	% returns 0 if failed: nothing changed except vars validated
	if isempty(jps)
		JPSVars('loadJPSVars');
	end  
	if size(dir('jpsAltLoad.m'),1)
		if jpsAltLoad('getData')
			result = jpsAltLoad('loadData');
		else
			result = 0;
		end  
		return
	end
	if ~JPSVars('getGDFFileName');
		result = 0;
		return
	end
	result = JPSVars('loadGDF');
	
	
case('FindLists');
	% returns = if no spike IDs present
	JPSVars('getAlignIDList');
	JPSVars('validateAlignID');
	result = JPSVars('getSpikeIDList');
	JPSVars('validateSpikeID');
	
	
case('createJPSVars');
	JPSVars('InitJPSVars');
	JPSVars('SaveJPSVars');  
	
	
case('InitJPSVars');  
	jps.Version = 1.00; 
	jps.FileName = [];
	jps.DataPath = [];
	jps.WorkPath = [];
	jps.SpikeIDRange = [1 99];
	jps.AlignIDRange = [100 9999];
	jps.TicksPersec	= 250;
	jps.StartStopRange = [-36000 36000];
	jps.StartStop = [-3600 3600];
	jps.AlignIDList = [];
	jps.SpikeIDList = [];
	jps.AlignID = [];
	jps.SpikeID = [];
	jps.gdf = [];
	jps.secBinWidth = 600;
	
	
case('SaveJPSVars');
  JPSDir = which('JPSVars.m');
	save ([JPSDir(1:end-9) 'JPSVars.mat'], 'jps');
	
	
case('validate');
	% returns a 0 if the vars aren't loaded and it can't find the JPSVars.mat file
	if isempty(jps)
		result = JPSVars('loadJPSVars');
	end
	
	
case('loadJPSVars');
	JPSDir = which('JPSVars.m');
	fid = fopen([JPSDir(1:end-9) 'JPSVars.mat'],'r');
	if fid > 0
		fclose(fid);
		load JPSVars.mat
	else
		c{1} = 'Default values file JPSVars.mat not found!';
		dlg =helpdlg(c,'Missing file: JPSVars.m');
		uiwait(dlg)
		JPSVars('InitJPSVars');
		d = JPSVars('JPSVarEntryDialog',1:10);
		uiwait(d)
		result = ~(isempty(jps));
	end  
	
case('getGDFFileName');
	% jps.FileName unchanged if fails  
	% returns a 0 if the user aborts without selecting a file
	source = [jps.DataPath '*gdf.mat'];
	FileName = [];
	[FileName, DPath] = uigetfile(source, 'Open a gdf file');
	if ~(FileName)
		result = 0;		
	else
		jps.FileName = FileName;
		jps.DataPath = DPath;
	end
	
	
	
	
case('loadGDF')
	% jps.gdf unchanged if fails
	if exist('data','var')
		jps.FileName = data;
	end    
	if ~isempty('jps.FileName')
		load([jps.DataPath jps.FileName]);
        jps.gdf = gdf;
        jps.rate = rate;
    	jps.TicksPersec	= rate;
		JPSVars('allIDsWind','update');
		result = JPSVars('FindLists');
	else
		result =0;	%no file name, user aborted instead of selecting
	end
	
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%  the following assume JPSVars have been validated - will crash if var ~exist  %%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
case('getAlignIDList')
	% if fails jps.AlignIDList is set to [];
	% jps.AlignID is left unchanged; call 'validateAlignID' to check
	jps.AlignIDList = [];
	if isempty(jps.gdf)
		result = 0;
		return
	end
	al = jps.gdf(find(jps.gdf(:,1) >= jps.AlignIDRange(1) & jps.gdf(:,1) <= jps.AlignIDRange(2)),1);
	if ~isempty(al)
		% only one of each type
		al = sort(al);
		jps.AlignIDList = [al(find(diff(al))); al(end)];
	else
		result = 0;
	end
	
	
	
case('validateAlignID')
	% values of jps.AlignID not present in jps.AlignIDList are set to []  
	% returns 0 if jps.AlignID returns empty  
	if ~isempty(jps.AlignID) & ~isempty(jps.AlignIDList);
		for i = length(jps.AlignID):-1:1  
			if ~find(jps.AlignIDList(:) == jps.AlignID(i))
				jps.AlignID(i) = [];
			end
		end  
	end
	if isempty(jps.AlignID) | isempty(jps.AlignIDList)
		result = 0;
	end  
	
	
	
case('getSpikeIDList')
	% if fails jps.SpikeIDList is set to [];
	% jps.SpikeID is left unchanged; call 'validateSpikeID' to check
	jps.SpikeIDList = [];
	if isempty(jps.gdf)
		result = 0;
		return
	end
	sl = jps.gdf(find(jps.gdf(:,1) >= jps.SpikeIDRange(1) & jps.gdf(:,1) <= jps.SpikeIDRange(2)),1);
	if ~isempty(sl)
		% only one of each type
		sl = sort(sl);
		jps.SpikeIDList = [sl(find(diff(sl))); sl(end)];
	else
		result = 0;
	end
	
	
	
case('validateSpikeID')
	% values of jps.SpikeID not present in jps.SpikeIDList are set to []  
	% returns 0 if jps.SpikeID returns empty  
	if ~isempty(jps.SpikeID) & ~isempty(jps.SpikeIDList)
		for i = length(jps.SpikeID):-1:1  
			if ~find(jps.SpikeIDList(:) == jps.SpikeID(i))
				jps.SpikeID(i) = [];
			end
		end  
	end
	if isempty(jps.SpikeID) | isempty(jps.SpikeIDList)
		result = 0;
	end  
	
	
	
case('validateStartStop')
	% data = 1 if start is to try to maintain the passed value  
	% data = 2 if stop is to try to maintain the passed value  
	% ensures jps.StartStop values are within the range of jps.StartStopRange
	% makes sure start < stop by at least one binwidth
	% if start < StartRange val start = StartRange val, similarly for stop
	% this will fail if jps.secBinWidth > jps.StartStopRange(2) -jps.StartStopRange(1)
	
	switch(data)
	case(1)  
		if jps.StartStop(1) + jps.secBinWidth > jps.StartStop(2);
			jps.StartStop(2) = jps.StartStop(1) + jps.secBinWidth;
		end
	case(2)  
		if jps.StartStop(1) + jps.secBinWidth > jps.StartStop(2);
			jps.StartStop(1) = jps.StartStop(2) - jps.secBinWidth;
		end
	end
	if jps.StartStop(1) < jps.StartStopRange(1)
		jps.StartStop(1) = jps.StartStopRange(1)
		if jps.StartStop(1) + jps.secBinWidth > jps.StartStop(2);
			jps.StartStop(2) = jps.StartStop(1) + jps.secBinWidth;
		end
	end
	if jps.StartStop(2) > jps.StartStopRange(2)
		jps.StartStop(2) = jps.StartStopRange(2)
		if jps.StartStop(1) + jps.secBinWidth > jps.StartStop(2);
			jps.StartStop(1) = jps.StartStop(2) - jps.secBinWidth;
		end
	end
	
case('getAllIDs');
	al = sort(jps.gdf(:,1));
	result = [al(find(diff(al))); al(end)];
	b = find(diff(al));
	result(1,2) = b(1);
	result(end,2) = length(al) - b(end);
	b =diff(b);
	if size(result,1) > 2   
		result(2:end-1,2) = b(:,1);
	end  
	
case('allIDsWind');
	cf = findobj('tag','jpsIDsBox');
	if isempty(cf) & strcmp(data,'update')
		return
	end
	
	
	r = JPSVars('getAllIDs'); 
	s{1} = 'ID      counts';
	s{2} = ' ';
	for i = 1:length(r)
		s{i+2} = [int2str(r(i,1)) '          ' int2str(r(i,2)) ];
	end  
	
	cf = findobj('tag','jpsIDsBox');
	if isempty(cf)
		if strcmp(data,'open')					% else if data = update do nothing
			countsBox = listwin('ListString',s,...
				'SelectionMode','single',...
				'Name',[jps.FileName ' IDs'],...
				'ListSize',[150 400]);
			set(countsBox,'tag','IDsBox');
		end
	else
		set('Name',[jps.FileName ' IDs']);
		cf = findobj(cf,'tag','jpslistbox');
		set(cf,'string',s);
	end  
	
	
case('JPSVarEntryDialog');
	% JPSVars('JPSVarEntryDialog',1:10);
	% pass data values to select which vars are to appear in the dialog
	% 'spkIDrng' 		= 1
	% 'spkID'				= 2
	% 'algnIDrng'		= 3
	% 'algnID'			= 4
	% 'strtstprng'	= 5
	% 'strstp'			= 6
	% 'ticks'				= 7
	% 'bw'					= 8
	% 'datapth'			= 9
	% 'wrkpth'			= 10
	
	if isempty(jps.gdf) 
		gdfpresent = 'off';
	else  
		gdfpresent = 'on';
	end
	
	jps.Status = 'edit';
	
	offset = 31.5;
	hgt = offset*(length(data)+3)+length(data)*11;
	y = 2.5*offset;
	
	h0 = figure('Color',[0.8 0.8 0.8], ...
		'Units','points', ...
		'Name','Defaults ', ...
		'NumberTitle','off', ...
		'Interruptible','off',...
		'MenuBar','none',...
		'Resize','off', ...
		'Position',[101 11 158 hgt-120], ...
		'Tag','JPSVarEntryDlg');
	
	h1 = uicontrol('Parent',h0, ...
		'Units','points', ...
		'Callback','JPSVars save save;', ...
		'ListboxTop',0, ...
		'Position',[15 11 55.5 15.75], ...
		'String','use & save', ...
		'UserData', data, ...
		'Tag','SaveJPSDefaults');
	h1 = uicontrol('Parent',h0, ...
		'Units','points', ...
		'Callback','close;', ...
		'ListboxTop',0, ...
		'Position',[87 11 55.5 15.75], ...
		'String','cancel', ...
		'Tag','CancelJPSDefaults');
	h1 = uicontrol('Parent',h0, ...
		'Units','points', ...
		'Callback','JPSVars save use;', ...
		'ListboxTop',0, ...
		'Position',[15 35 55.5 15.75], ...
		'String','use', ...
		'UserData', data, ...
		'Tag','useJPSDefaults');
	h1 = uicontrol('Parent',h0, ...
		'Units','points', ...
		'Callback','JPSVars allIDsWind open;', ...
		'ListboxTop',0, ...
		'Position',[87 35 55.5 15.75], ...
		'Enable',gdfpresent,...
		'String','show IDs', ...
		'Tag','showIDsWind');
	
	
	if find(data == 10)
		% data path
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 45 12], ...
			'String','work path', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'Callback','JPSVars browseDir workpath;', ...
			'ListboxTop',0, ...
			'Position',[97.5 y 45 13.5], ...
			'Enable','off',...
			'String','browse', ...
			'Tag','browseworkpath');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 127.5 13.5], ...
			'String',jps.WorkPath, ...
			'Style','edit', ...
			'Tag','defworkpath');
		y = y+offset;
	end
	
	if find(data == 9)
		% data path
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 45 12], ...
			'String','data path', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'Callback','JPSVars browseDir datapath;', ...
			'ListboxTop',0, ...
			'Position',[97.5 y 45 13.5], ...
			'Enable','off',...
			'String','browse', ...
			'Tag','browsedatapath');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 127.5 13.5], ...
			'String',jps.DataPath, ...
			'Style','edit', ...
			'Tag','defdatapath');
		y = y+offset;
	end
	
	if find(data == 8)
		% bin width  
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','bin width (sec)', ...
			'Style','text', ...
			'Tag','s');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',int2str(jps.secBinWidth), ...
			'Style','edit', ...
			'Tag','defbinwidth');
		y = y+offset;
	end
	
	if find(data == 7)
		% ticks per sec
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','ticks per millisecond', ...
			'Style','text', ...
			'Tag','s');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',num2str(jps.TicksPersec), ...
			'Style','edit', ...
			'Tag','deftickspersec');
		y = y+offset;
	end
	
	if find(data == 6)
		% default start and stop sec  
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String',' default PSTH range (in sec)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',int2str(jps.StartStop(1)), ...
			'Style','edit', ...
			'Tag','defStartsec');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'ListboxTop',0, ...
			'Position',[68.25 y-13 20.25 13.5], ...
			'String','to', ...
			'Style','text', ...
			'Tag','StaticText2');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[97.5 y-13 45 13.5], ...
			'String',int2str(jps.StartStop(2)), ...
			'Style','edit', ...
			'Tag','defStopsec');
		y = y+offset;
	end
	
	if find(data == 5)
		% max start and stop  
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String',' maximum PSTH range (in sec)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',int2str(jps.StartStopRange(1)), ...
			'Style','edit', ...
			'Tag','defStartminsec');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'ListboxTop',0, ...
			'Position',[68.25 y-13 20.25 13.5], ...
			'String','to', ...
			'Style','text', ...
			'Tag','StaticText2');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[97.5 y-13 45 13.5], ...
			'String',int2str(jps.StartStopRange(2)), ...
			'Style','edit', ...
			'Tag','defStopmaxsec');
		y = y+offset;
	end
	
	if find(data == 4)
		% selected align IDs
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','default selected align ID(s)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 127.5 13.5], ...
			'String',int2str(jps.AlignID), ...
			'Style','edit', ...
			'Tag','defAlignID');
		y = y+offset;
	end
	
	if find(data == 3)
		% align ID range  
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','align ID range (inclusive)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',int2str(jps.AlignIDRange(1)), ...
			'Style','edit', ...
			'Tag','defAlignIDmin');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'ListboxTop',0, ...
			'Position',[68.25 y-13 20.25 13.5], ...
			'String','to', ...
			'Style','text', ...
			'Tag','StaticText2');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[97.5 y-13 45 13.5], ...
			'String',int2str(jps.AlignIDRange(2)), ...
			'Style','edit', ...
			'Tag','defAlignIDmax');
		y = y+offset;
	end
	
	[m,n] = size(jps.SpikeID);
	if m > n 
		jps.SpikeID = jps.SpikeID';
	end
	if find(data == 2)
		% selected spike ID  
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','default selected spike ID(s)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 127.5 13.5], ...
			'String',int2str(jps.SpikeID), ...
			'Style','edit', ...
			'Tag','defSpikeID');
		y = y+offset;
	end
	
	if find(data == 1)
		% spike ID Range
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'HorizontalAlignment','left', ...
			'ListboxTop',0, ...
			'Position',[13.5 y 130.5 12], ...
			'String','spike ID range (inclusive)', ...
			'Style','text', ...
			'Tag','StaticText1');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[15 y-13 45 13.5], ...
			'String',int2str(jps.SpikeIDRange(1)), ...
			'Style','edit', ...
			'Tag','defSpikeIDmin');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[0.8 0.8 0.8], ...
			'ListboxTop',0, ...
			'Position',[68.25 y-13 20.25 13.5], ...
			'String','to', ...
			'Style','text', ...
			'Tag','StaticText2');
		h1 = uicontrol('Parent',h0, ...
			'Units','points', ...
			'BackgroundColor',[1 1 1], ...
			'HorizontalAlignment','right', ...
			'ListboxTop',0, ...
			'Position',[97.5 y-13 45 13.5], ...
			'String',int2str(jps.SpikeIDRange(2)), ...
			'Style','edit', ...
			'Tag','defSpikeIDmax');
	end
	result = h0;
	
	
case('browseDir')
	% need to find a uigetdir routine
	% until then this stays disabled
	
	switch(data)
		
	case('workpath')
		
	case('datapath')
		
	end
	
	
case('save')
	d = get(gco,'UserData');
	
	if find(d ==1)
		cf = findobj('tag','defSpikeIDmin');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Spike and Align ID ranges must be valid numbers and may not overlap';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			SpikeIDRange(1) = str2num(s);
		end  
		cf = findobj('tag','defSpikeIDmax');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Spike and Align ID ranges must be valid numbers and may not overlap';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			SpikeIDRange(2) = str2num(s);
		end
	end
	
	if find(d==2)
		cf = findobj('tag','defSpikeID');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			SpikeID = [];
		else  
			SpikeID = str2num(s);
		end  
	end
	
	if find(d==3)
		cf = findobj('tag','defAlignIDmin');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Spike and Align ID ranges must be valid numbers and may not overlap';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			AlignIDRange(1) = str2num(s);
		end  
		cf = findobj('tag','defAlignIDmax');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Spike and Align ID ranges must be valid numbers and may not overlap';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			AlignIDRange(2) = str2num(s);
		end
	end
	
	if find(d==4)
		cf = findobj('tag','defAlignID');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			AlignID = [];
		else  
			AlignID = str2num(s);
		end  
	end
	
	if find(d==5)
		cf = findobj('tag','defStartminsec');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Max and Min PSTH Range values must valid numbers and Min <= Max-100';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			StartStopRange(1) = str2num(s);
		end  
		cf = findobj('tag','defStopmaxsec');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Max and Min PSTH Range values must valid numbers and Min <= Max-100';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			StartStopRange(2) = str2num(s);
		end
	end
	
	if find(d==6)
		cf = findobj('tag','defStartsec');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'default PSTH Range values must valid numbers and Min <= Max + bin width';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			StartStop(1) = str2num(s);
		end  
		cf = findobj('tag','defStopsec');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'default PSTH Range values must valid numbers and Min <= Max + bin width';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			StartStop(2) = str2num(s);
		end
	end
	
	if find(d==7)
		cf = findobj('tag','deftickspersec');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			c{1} = 'Time as coded in the data file';
			c{2} = 'in tersec of ticks per sec must';
			c{3} = 'be entered and a valid number';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			TicksPersec = str2num(s);
		end
	end
	
	if find(d==8)
		cf = findobj('tag','defbinwidth');
		s = get(cf,'String');
		if isempty(s) | isempty(str2num(s))
			secBinWidth = [];
		else  
			secBinWidth = str2num(s);
		end
	end
	
	if find(d==9)
		cf = findobj('tag','defdatapath');
		s = get(cf,'String');
		if size(dir(s),1) == 0
			c{1} = 'Data path is not a valid directory';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			DataPath = s;
		end
	end
	
	if find(d==10)
		cf = findobj('tag','defworkpath');
		s = get(cf,'String');
		if size(dir(s),1) == 0
			c{1} = 'Work path is not a valid directory';
			dlg =helpdlg(c,'Data Range Error');
			uiwait(dlg);
			return
		else  
			WorkPath = s;
		end
	end
	
	
	if ~(...
			(AlignIDRange(2) > SpikeIDRange(1) & SpikeIDRange(2) < AlignIDRange(1)) ...
			|																   ...
			(AlignIDRange(2) < SpikeIDRange(1) & SpikeIDRange(2) > AlignIDRange(1))...
			)
		c{1} = 'Spike and Align ID ranges may not overlap';
		dlg =helpdlg(c,'Data Range Error');
		uiwait(dlg);
		return
	end
	
	if find(d == 1)
		jps.SpikeIDRange = SpikeIDRange;
	end  
	if find(d == 2)
		jps.SpikeID = SpikeID;
	end  
	if find(d == 3)
		jps.AlignIDRange = AlignIDRange;
	end  
	if find(d == 4)
		jps.AlignID = AlignID;
	end  
	if find(d == 5)
		jps.StartStopRange = StartStopRange;
	end  
	if find(d == 6)
		jps.StartStop = StartStop;
	end  
	if find(d == 7)
		jps.TicksPersec = TicksPersec;
	end  
	if find(d == 8)
		jps.secBinWidth = secBinWidth;
	end  
	if find(d == 9)
		jps.DataPath = DataPath;
	end  
	if find(d == 10)
		jps.WorkPath = WorkPath;
	end  
	
	
	jps.Status = data;
	if strcmp(data,'save')
		sv = jps.gdf;
		sf = jps.FileName;
		sa = jps.AlignIDList;
		ss = jps.SpikeIDList;
		jps.gdf = [];
		jps.FileName = [];
		jps.AlignIDList = [];
		jps.SpikeIDList = [];
		
		% change this line when installing on a new computer
		JPSVars('SaveJPSVars');
		%    save JPSVars.mat jps
		jps.gdf = sv;
		jps.FileName = sf;
		jps.AlignIDList = sa;
		jps.SpikeIDList = ss;
	end
	
	close 
	
	
end % main switch