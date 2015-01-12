function f_find_bni_data(animalDir)

%   dbstop in f_find_bni_data at 10;

  EEGList = dir(fullfile(animalDir,'*.eeg'));
  AllBNIs = dir(fullfile(animalDir,'*.bni'));
  BNIList = AllBNIs(find(cellfun(@length,{AllBNIs.name})<=12));
  
  fprintf('%s: Missing %d out of %d BNI files.\n',animalDir(39:42),length(EEGList)-length(BNIList),length(EEGList));
  keyboard;
end