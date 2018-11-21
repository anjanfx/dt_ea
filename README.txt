DT-EA-nic

This is an open source version of the 3 level multicross EA based 
on the DT Oscillator. There are some different schools of thought 
out there, but it is mine personally to never use any code that won't 
compile under the new MQL standards. That being said the current 
indicators being used (at the time of developement) would not compile
using the strict directive. Additionally, the indicators in use are 
bloated with additional chart objects and multi-timeframe stuffs that 
should not be in a production grade indicator. The indicator in use 
should only do one timeframe with minimal bloat. The EA will call 
multiple different timeframes into existense. As such I rewrote the 
indicator to comply with modern standards. I don't know who to attribute 
with the "DT" algorithm, so thanks whoever you are... 

Features:
   - Too lazy to document stuff ATM.

Instructions:
   - Copy entire directory into the experts folder and open click the *.mproj
      in metaeditor. Click on the Project tab in the Navigator window. Compile.
   - Alternatively, copy/pasta the ex4 to experts.
   - Bonus - if you want to see the actual indicator in use then you need
      to copy it from the EA directory to the indicators directory. It's 
      name is "ModernDtOscillator" 

Changlog:

2018.11.21 v0.0.1 - Initial release. 