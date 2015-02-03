function out = GetColorValue;
% Gets the value of the clicked on area of a pcolor graph

[x,y] = ginput(1);
what = get(gco, 'type');
try
    if strcmp(what, 'surface')
        cdata = get(gco, 'cdata');

        out = [floor(x),floor(y), cdata(floor(y), floor(x)];
        return
    end
    
    if strcmp(what, 'image')
        cdata = get(gco, 'cdata');

        out = [round(x),round(y), cdata(round(y), round(x)];
        return
    end
    
end
fprintf('The clicked on plot was not a pcolor or image plot\n');
out = [];