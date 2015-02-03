load('j0001_CalcEnergy.mat');

%errorbar(energy000(:,3), energy000(:,1),0, energy000(:,2), '.b', 'MarkerSize', 1);
hold on
%errorbar(energy001(:,3), energy001(:,1),0, energy001(:,2), '.b');
%errorbar(energy002(:,3), energy002(:,1),0, energy002(:,2), '.b');
%errorbar(energy003(:,3), energy003(:,1),0, energy003(:,2), '.b');
%errorbar(energy004(:,3), energy004(:,1),0, energy004(:,2), '.b');
%errorbar(energy005(:,3), energy005(:,1),0, energy005(:,2), '.b');
h =bar(energy000(:,3), energy000(:,1)/10);
set(h, 'BarWidth', 1);
h =bar(energy001(:,3), energy001(:,1)/10);
set(h, 'BarWidth', 1);
h =bar(energy002(:,3), energy002(:,1));
set(h, 'BarWidth', 1);
h =bar(energy003(:,3), energy003(:,1));
set(h, 'BarWidth', 1);
h =bar(energy004(:,3), energy004(:,1));
set(h, 'BarWidth', 1);
h = bar(energy005(:,3), energy005(:,1));
set(h, 'BarWidth', 1);
cf = findobj('EdgeColor', [0 0 0]);
set(cf, 'EdgeColor', 'b');
cf = findobj('BarWidth', 0.8);
set(cf, 'BarWidth', 1);
