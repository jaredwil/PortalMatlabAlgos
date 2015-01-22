function f_uploadAnnotations(dataset,layerName,eventTimesUSec,eventChannels,label)
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


try 
    fprintf('\nRemoving existing layer\n');
    dataset.removeAnnLayer(layerName);
catch 
    fprintf('No existing layer\n');
end
annLayer = dataset.addAnnLayer(layerName);
uniqueAnnotChannels = unique(eventChannels);
ann = [];
fprintf('Creating annotations...');
for i = 1:numel(uniqueAnnotChannels)
    tmpChan = uniqueAnnotChannels(i);
    ann = [ann IEEGAnnotation.createAnnotations(eventTimesUSec(eventChannels==tmpChan,1),eventTimesUSec(eventChannels==tmpChan,2),'Event',label,dataset.channels(tmpChan))];
end
fprintf('done!\n');
numAnnot = numel(ann);
startIdx = 1;
%add annotations 5000 at a time (freezes if adding too many)
fprintf('Adding annotations...\n');
for i = 1:ceil(numAnnot/5000)
    fprintf('Adding %d to %d\n',startIdx,min(startIdx+5000,numAnnot));
    annLayer.add(ann(startIdx:min(startIdx+5000,numAnnot)));
    startIdx = startIdx+5000;
end
fprintf('done!\n');
