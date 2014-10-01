Repository: Spike-Detector
=============================
This repository contains scripts to detect spikes. 

Scripts include:

spike_AR.m              -   	spike detector based on autoregressive modeling of noise (Acir 2004). Seen to work well on clean intracranial rat data

uploadAnnotations.m     -   	takes the output of detectors (time and channel of detections) and uploads to the portal


TO BE ADDED:
spike_LL_fultered.m	-	spike detector based on line length
spike_keating_auto.m	-	spike detector based on Jeff Keating's algorithm
