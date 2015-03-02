function move_vline(handle,DoneFcn) %subfunction
%MOVE_VLINE implements horizontal movement of line.
%
%  Example:
%    plot(sin(0:0.1:pi))
%    h=vline(1);
%    move_vline(h)
%
%    requres VLINE by Brandon Kuczenski, available at MATLAB Central.
%<http://www.mathworks.com/matlabcentral/fileexchange/loadFile.do?objectId=1039&objectType=file>

% This seems to lock the axes position

%set(gcf,'Nextplot','Replace')
set(gcf,'DoubleBuffer','on')
h_ax=get(handle,'parent');
h_fig=get(h_ax,'parent');
setappdata(h_fig,'h_vline',handle)
if nargin<2, DoneFcn=[]; end
%setappdata(h_fig,'DoneFcn',DoneFcn)
set(handle,'ButtonDownFcn',@DownFcn)

  function DownFcn(hObject,eventdata,varargin) %Nested--%
    set(gcf,'WindowButtonMotionFcn',@MoveFcn)           %
    set(gcf,'WindowButtonUpFcn',@UpFcn)                 %
  end %DownFcn------------------------------------------%

  function UpFcn(hObject,eventdata,varargin) %Nested----%
    set(gcf,'WindowButtonMotionFcn',[])                 %
%    DoneFcn=getappdata(hObject,'DoneFcn');              %
%    if ischar(DoneFcn)                                  %
%      eval(DoneFcn)                                     %
%    elseif isa(DoneFcn,'function_handle')               %
%      feval(DoneFcn)                                    %
%    end
%
%    h_hline=getappdata(hObject,'h_hline');              %
%    ydata = get(h_hline, 'YData');                      %
%    fprintf('y value: %3.2f\n', ydata(1));              %  
  end %UpFcn--------------------------------------------%

  function MoveFcn(hObject,eventdata,varargin) %Nested------%
    h_vline=getappdata(hObject,'h_vline');                  %
    if gco ~= h_vline; return; end                          %
    h_ax=get(h_vline,'parent');                             %
    cp = get(h_ax,'CurrentPoint');                          %
    xpos = cp(1);                                           %
    x_range=get(h_ax,'xlim');                               %
    if xpos<x_range(1), xpos=x_range(1); end                %
    if xpos>x_range(2), xpos=x_range(2); end                %
    XData = get(h_vline,'XData');                           %
    XData(:)=xpos;                                          %
    set(h_vline,'xdata',XData)                              %
    ud = get(h_vline, 'userdata');
    if ~isempty(ud)
        set(ud, 'xdata', XData);
    end
  end %MoveFcn----------------------------------------------%

end %move_vline(subfunction)

