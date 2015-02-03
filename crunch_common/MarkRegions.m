function out = MarkRegions(action, data)
% call by MarkRegions(haxes) where haxes is a handle to 
% the axes to be used, if nothing is passed the current axes are used
% the ranges selected are placed in the global variable: ranges
% column 1 is start and column 2 is stop
global mr;
global ranges;



out = [];

if ~exist('action', 'var')
    action = gca;
end

if isnumeric(action)
    data = action;
    action = 'init';
end

switch (action)

    case 'init'
        mr.sourceaxes = data;
        mr.regions = [];
        axes(mr.sourceaxes);
        set(gcf, 'units', 'pixels');
        p = get(gcf, 'position');
        p(1) = p(1) -130;
        p(2) = p(2) -31;
        if p(1) < 1; p(1) = 1; end
        if p(2) < 1; p(2) = 1; end
        h0 = figure;
        set(h0, 'UserData', [], ...
            'MenuBar','none', ...
            'tag','mrMain',...
            'Name','Mark Regions  version 0.0', ...
            'Numbertitle','off',...
            'units', 'pixels',...
            'Position',[p(1) p(2) 300 120]);
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'Callback','MarkRegions NewRegion start;', ...
            'ListboxTop',0, ...
            'Position',[15 60 70 15.75], ...
            'String','New region', ...
            'UserData', data, ...
            'Tag','mrNewRegion');
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'Callback','MarkRegions Accept;', ...
            'ListboxTop',0, ...
            'Position',[15 40 70 15.75], ...
            'enable', 'off', ...
            'String','Accept start', ...
            'UserData', data, ...
            'Tag','mrAccept');
        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'Callback','MarkRegions Done;', ...
            'ListboxTop',0, ...
            'Position',[15 20 70 15.75], ...
            'String','Done', ...
            'UserData', data, ...
            'Tag','mrDone');

        h1 = uicontrol('Parent',h0, ...
            'Units','points', ...
            'BackgroundColor',[0.8 0.8 0.8], ...
            'HorizontalAlignment','left', ...
            'ListboxTop',0, ...
            'Position',[2 2 290 10], ...
            'String','Click ''New region'' to start', ...
            'Style','text', ...
            'Tag','mrAnalyze');



    case 'NewRegion'
        cf = findobj('tag', 'mrNewRegion');
        set(cf, 'enable', 'off');
        cf = findobj('tag', 'mrAccept');
        set(cf, 'enable', 'on');
        set(cf, 'string', ['Accept ' data]);
        cf = findobj('tag', 'mrAnalyze');
        set(cf, 'string', 'drag line, click Accept when done');

        axes(mr.sourceaxes);
        ax = axis;
        mid = mean(ax(1:2));
        off = (ax(2)-ax(1))/10;
        mr.ln = vline(mid-off,':r', []);
        set(mr.ln, 'userdata', data);
        move_vline(mr.ln);



    case 'Accept'
        switch get(mr.ln, 'userdata')

            case 'start'
                x = get(mr.ln, 'xdata');
                y = get(mr.ln, 'ydata');
                mr.regions(end+1,1) = x(1);
                set(mr.ln, 'LineStyle', '-');
                MarkRegions('NewRegion', 'stop');


            case 'stop'
                x = get(mr.ln, 'xdata');
                y = get(mr.ln, 'ydata');
                mr.regions(end,2) = x(1);
                set(mr.ln, 'LineStyle', '-');
                cf = findobj('tag', 'mrNewRegion');
                set(cf, 'enable', 'on');
                cf = findobj('tag', 'mrAccept');
                set(cf, 'enable', 'off');
                cf = findobj('tag', 'mrAnalyze');
                set(cf, 'string', 'Click ''New region'' for another, Done if finished');
                fprintf('Range #%d: %1.2f - %1.2f\n', size(mr.regions,1), mr.regions(end,1), mr.regions(end,2));
        end



    case 'Done'

        if ~isempty(mr.ln)
            if ~strcmp(get(mr.ln, 'LineStyle'), '-')
                delete(mr.ln);
            end
        end
        cf = findobj('tag', 'mrMain');
        delete(cf);
        ranges = mr.regions;

end