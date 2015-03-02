function [starttime stoptime] = ParseBehaviorFileName(name);
 
  start = name(end-47:end-28);
  stop = name(end-23:end-4);
  tm = findstr(start, '_');
  start(tm(end-1:end)) = ':';
  start(tm(1:end-2)) = ' ';
  starttime = datenum(start);
  tm = findstr(stop, '_');
  stop(tm(end-1:end)) = ':';
  stop(tm(1:end-2)) = ' ';
  stop = datevec(stop);
  stop(end) = stop(end) + 30;  % vids are 30 seconds long, want end time
  stoptime = datenum(stop);
  


