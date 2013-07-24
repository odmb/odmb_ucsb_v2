 ODMB.V2 firmware
================================================================
Official firmware for the V2 prototype of Optical DAQ 
MotherBoard (ODMB) for the ME1/1 station of the CMS muon endcap detector.
This repository contains the source code for the ISE synthesis (odmb_ucsb_v2.xise)
and ModelSim (odmb_ucsb_v2.mpf) simulation of the ODMB firmware.

#### AFTER CLONING:
In order to avoid committing changes to work/_info, run the command
> git update-index --assume-unchanged work/_info

after each clone of the repository. This will avoid the need for cleaning
_info, and ModelSim should be able to compile the project right away.
