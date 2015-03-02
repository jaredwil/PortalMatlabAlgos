function move_hline(handle,DoneFcn)
%MOVE_hline implements horizontal movement of line
%
% This seems to lock the axes position

%set(gcf,'Nextplot','Replace')
set(gcf,'DoubleBuffer','on')

h_ax=get(handle,'parent');
h_fig=get(h_ax,'parent');
setappdata(h_fig,'h_hline',handle)
if nargin<2, DoneFcn=[]; end
setappdata(h_fig,'DoneFcn',DoneFcn)
set(handle,'ButtonDownFcn',@DownFcn)

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





end %move_hline

