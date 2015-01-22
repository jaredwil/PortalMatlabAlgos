function f_saveToFile(analysis,times,channels)
%	Usage: uploadAnnotations(dataset, layerName, eventTimesUSec,eventChannels,label);
%	
%	dataset		-	IEEGDataset object
%	layerName	-	string of name of annotation layer
%	eventTimesUSec	-	array of event times in microsec
%	eventChannels	-	cell array of channel indices corresponding to each event
%	label		-	string label for events
%
%	Function will upload to the IEEG portal the given events obtained from running various detection
%	algorithms (e.g. spike_AR.m). Annotations will be associated with eventChannels and given a label.

  curTime = clock;
  outputDir = 'C:\Users\jtmoyer\Documents\MATLAB\P05-Dichter-data\Output';
  fileName = sprintf('%s_%g-%g-%g_%g%g%g.txt',analysis,curTime(1),curTime(2),curTime(3),curTime(4),curTime(5),round(curTime(6)))

  for i = 1: length(times)
    fprintf
  end
end