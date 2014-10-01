Repository: IEEGPortalAlgos
=============================
This repository contains misc scripts to detect patterns in EEG Data. 
Many scripts require functions from IEEGPortalTools for viewing/upload annotations.
Many scripts in this repository are under active development and may contain bugs. 
Please do not hesitate to contact me at hoameng@upenn.edu with questions, concerns, bugs, etc.

Older standalone functions will detect and automatically upload annotations.
In general, detectors will return time of detection and channels, which 
can be uploaded to the portal with uploadAnnotations.m (IEEGPortalTools) for viewing.


Scripts include:

-spike_AR.m              -   sspike detector based on autoregressive modeling of noise (Acir 2004). Seen to work well on clean intracranial rat data

TO BE ADDED:
-spike_LL_filtered.m     -	spike detector based on line length
-spike_keating_auto.m	 -	spike detector based on Jeff Keating's algorithm
