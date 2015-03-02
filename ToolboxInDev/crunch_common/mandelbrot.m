function [x, y, z] = mandelbrot()

%
% USAGE:    [x, y, z] = mandelbrot()
% 
% Generates an image of the mandelbrot set on the complex plane.  Zoom in
% and redraw at finer resolutions, until float precision is reached!
%
% Stephen Wong, MD
% October 30, 2008


xlim = [-2.2 0.8];
ylim = [-1.5 1.5];
[x, y, z] = calcmandelbrot(xlim, ylim);

% draw the mandelbrot set
im = subplot(1,10,3:10);
image(x, y, z);
axis image;
colormap bone;

% create the buttons
global b2
h = uibuttongroup('visible','off','Position',[0 0 .2 1]);
b1 = uicontrol('Style', 'Push', 'String', 'Redraw', 'pos', [10 350 100 30], 'parent', h, 'HandleVisibility', 'off', 'Callback', {@redraw, im});
b2 = uicontrol('Style', 'Popup', 'string', 'Jet|HSV|Hot|Cool|Spring|Summer|Autumn|Winter|Gray|Bone|Copper|Pink|Lines', 'pos', [10 250 100 30], 'parent', h, 'HandleVisibility', 'off', 'Callback', {@setcolor, b2});
set(h,'Visible','on');


%**************************************************************************
% calculate the mandelbrot set for the specified axes
function [x, y, z] = calcmandelbrot(xlim, ylim)
inc = (xlim(2) - xlim(1))/1000;
x = xlim(1):inc:xlim(2);
y = ylim(1):inc:ylim(2);
z = ones(length(x), length(y));
maxiter = 500;
pct = .1;
fprintf('\tPercent Complete:   %d%%', 0);
for xidx = 1:length(x)
    if xidx >= pct*length(x)
        fprintf('\b\b\b%d%%', round(100*pct));
        pct = pct + .1;
    end
    
    for yidx = 1:length(y)
        x0 = 0;
        y0 = 0;
        iter = 0;
        while (x0^2 + y0^2 <= 4) && (iter < maxiter)
            xtemp = x0^2 - y0^2 + x(xidx);
            y0 = 2*x0*y0 + y(yidx);
            x0 = xtemp;
            iter = iter + 1;
        end
        
        if iter < maxiter
            z(yidx,xidx) = iter/maxiter;
        end
    end
end
fprintf('\n');
z = z*255;

% button to redraw (use after zooming)
function redraw(hObject, eventdata, im)
xlim = get(im, 'xlim');
ylim = get(im, 'ylim');
range = min(xlim(2) - xlim(1), ylim(2) - ylim(1));
xlim = [xlim(1) xlim(1)+range];
ylim = [ylim(1) ylim(1)+range];
[x, y, z] = calcmandelbrot(xlim, ylim);
set(get(im, 'child'), 'xdata', x, 'ydata', y, 'cdata', z);

% button to set image color
function setcolor(hObject, eventdata, im)
global b2
val = get(b2, 'value');
switch val
    case 1
        colormap jet;
    case 2
        colormap hsv;
    case 3
        colormap hot;
    case 4
        colormap cool;
    case 5
        colormap spring;
    case 6
        colormap summer;
    case 7
        colormap autumn;
    case 8
        colormap winter;
    case 9
        colormap gray;
    case 10
        colormap bone;
    case 11
        colormap copper;
    case 12
        colormap pink;
    case 13
        colormap lines;
end

