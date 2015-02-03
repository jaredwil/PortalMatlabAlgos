function onscreen

p = get(gcf, 'position');
p([1,2]) = 1;
set(gcf, 'position', p);
