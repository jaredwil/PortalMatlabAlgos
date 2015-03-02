function out = MakeSinWave(rate,fr,numcycles)

out = sin(0:2*pi*fr/(rate):2*pi*numcycles)';
