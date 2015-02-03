function out = PrintSzTimes(action, data)
%function QSA
%  open a rat and analyze for seizure like activity using function decay on
%  the channel passed
global hhh;
global decay;
global x;

chan= 1;
if ~exist('action', 'var') || isempty(action)
    action = 'init';
end

switch action

    case 'init'
        decay = [];

        a = GetEEGData;                         % open a eeg file
        if isempty(a)                           % if cancled
            return                              % then return
        end


        decay = zeros(2000000,1);               % 1 million 10 second bins = almost 4 months
        x = zeros(2000000,1);
        decay_inx = 1;                          % where to put the next value

        rate = GetEEGData('getrate');           % get the rate
        GetEEGData('limitchannels', chan);      % limit to the channel of interest
        GetEEGData('sethunksize', 10);          % set to 10 second hunks
        starttime = GetEEGData('getstartdatevec');

        data = GetEEGData('getnext');           % get the first hunk
        startlength = length(data);
        h = figure('position', [0.005, 0.45, 0.90, 0.45], 'units', 'normalized');

        while length(data) == startlength       % while data left
            decay(decay_inx) = feat_decay(data,rate);
            decay_inx = decay_inx+1;
            if decay_inx > size(decay,1)
                break;
            end
            data = GetEEGData('getnext');
            if ~rem(decay_inx, 6*60*24)        % every day
                x = 1:(decay_inx-1);
                x = x/(6*60*24);
                plot(x,decay(1:decay_inx-1))   % plot all 10 second bins
                drawnow
            end
        end
        toc
        decay(decay_inx:end) = [];              % get rid of extra zeros
        %    subplot(numchans,1,chan);
        x = 1:length(decay);
        x = x/(6*60*24);
        plot(x,decay)                           % plot all 10 second bins
        drawnow

        ax = axis;
        hhh=hline(ax(4)/2);
        m_hl;
        uicontrol('Parent',sd.main, ...
            'Units','normalized', ...
            'Callback', 'PrintSzTimes run;' , ...
            'ListboxTop',0, ...
            'Position',[0.020 0.73 0.5 0.07], ...
            'BusyAction', 'cancel', ...
            'Interruptible', 'on', ...
            'String', 'find times', ...
            'Tag','run', ...
            'Enable','on');

        drawnow

    case 'run'
        y = get(hhh, 'ydata');
        above = find(decay > y(1));
        d = diff(above); inx = find(d > 1);
        res = x(inx+1);
        plot(res, y(1), '.k', 'MarkerSize', 20);
        
%        for i = 1:length(res);
%            fprint
%        end
        

end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function m_hl(DoneFcn)
%MOVE_hline implements horizontal movement of line
%
% This seems to lock the axes position

handle = gco;
set(gcf,'Nextplot','Replace')
set(gcf,'DoubleBuffer','on')

h_ax=get(handle,'parent');
h_fig=get(h_ax,'parent');
setappdata(h_fig,'h_hline',handle)
if nargin<2, DoneFcn=[]; end
setappdata(h_fig,'DoneFcn',DoneFcn)
set(handle,'ButtonDownFcn',@DownFcn)

end

function DownFcn(hObject,eventdata,varargin) %Nested--%
set(gcf,'WindowButtonMotionFcn',@MoveFcn)           %
set(gcf,'WindowButtonUpFcn',@UpFcn)                 %
end %DownFcn------------------------------------------%

function UpFcn(hObject,eventdata,varargin) %Nested----%
set(gcf,'WindowButtonMotionFcn',[])                 %
DoneFcn=getappdata(hObject,'DoneFcn');              %
if ischar(DoneFcn)                                  %
    eval(DoneFcn)                                     %
elseif isa(DoneFcn,'function_handle')               %
    feval(DoneFcn)                                    %
end                                                 %
%h_hline=getappdata(hObject,'h_hline');             %
%ydata = get(h_hline, 'YData');                     %
%fprintf('y value: %3.2f\n', ydata(1));             %
end %UpFcn--------------------------------------------%

function MoveFcn(hObject,eventdata,varargin) %Nested------%
h_hline=getappdata(hObject,'h_hline');                  %
if gco ~= h_hline;
    move_hline(gco);
    return;
end                          %
h_ax=get(h_hline,'parent');                             %
cp = get(h_ax,'CurrentPoint');                          %
ypos = cp(3);                                           %
y_range=get(h_ax,'ylim');                               %
if ypos<y_range(1), ypos=y_range(1); end                %
if ypos>y_range(2), ypos=y_range(2); end                %
YData = get(h_hline,'YData');                           %
YData(:)=ypos;                                          %
set(h_hline,'ydata',YData)                              %
end %MoveFcn----------------------------------------------%




function hhh=hline(y,in1,in2)
% function h=hline(y, linetype, label)
%
% Draws a horizontal line on the current axes at the location specified by 'y'.  Optional arguments are
% 'linetype' (default is 'r:') and 'label', which applies a text label to the graph near the line.  The
% label appears in the same color as the line.
%
% The line is held on the current axes, and after plotting the line, the function returns the axes to
% its prior hold state.
%
% The HandleVisibility property of the line object is set to "off", so not only does it not appear on
% legends, but it is not findable by using findobj.  Specifying an output argument causes the function to
% return a handle to the line, so it can be manipulated or deleted.  Also, the HandleVisibility can be
% overridden by setting the root's ShowHiddenHandles property to on.
%
% h = hline(42,'g','The Answer')
%
% returns a handle to a green horizontal line on the current axes at y=42, and creates a text object on
% the current axes, close to the line, which reads "The Answer".
%
% hline also supports vector inputs to draw multiple lines at once.  For example,
%
% hline([4 8 12],{'g','r','b'},{'l1','lab2','LABELC'})
%
% draws three lines with the appropriate labels and colors.
%
% By Brandon Kuczenski for Kensington Labs.
% brandon_kuczenski@kensingtonlabs.com
% 8 November 2001

if length(y)>1  % vector input
    for I=1:length(y)
        switch nargin
            case 1
                linetype='r:';
                label='';
            case 2
                if ~iscell(in1)
                    in1={in1};
                end
                if I>length(in1)
                    linetype=in1{end};
                else
                    linetype=in1{I};
                end
                label='';
            case 3
                if ~iscell(in1)
                    in1={in1};
                end
                if ~iscell(in2)
                    in2={in2};
                end
                if I>length(in1)
                    linetype=in1{end};
                else
                    linetype=in1{I};
                end
                if I>length(in2)
                    label=in2{end};
                else
                    label=in2{I};
                end
        end
        h(I)=hline(y(I),linetype,label);
    end
else
    switch nargin
        case 1
            linetype='r:';
            label='';
        case 2
            linetype=in1;
            label='';
        case 3
            linetype=in1;
            label=in2;
    end




    g=ishold(gca);
    hold on

    x=get(gca,'xlim');
    h=plot(x,[y y],linetype);
    if ~isempty(label)
        yy=get(gca,'ylim');
        yrange=yy(2)-yy(1);
        yunit=(y-yy(1))/yrange;
        if yunit<0.2
            text(x(1)+0.02*(x(2)-x(1)),y+0.02*yrange,label,'color',get(h,'color'))
        else
            text(x(1)+0.02*(x(2)-x(1)),y-0.02*yrange,label,'color',get(h,'color'))
        end
    end

    if g==0
        hold off
    end
    %    set(h,'tag','hline','handlevisibility','off') % this last part is so that it doesn't show up on legends
end % else

if nargout
    hhh=h;
end
end