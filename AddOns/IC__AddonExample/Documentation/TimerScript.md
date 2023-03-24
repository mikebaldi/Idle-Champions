There are two styles of timer scripts that can be used with the BrivGemFarm addon in Script Hub.
The first are functions that are run on a timer directly by Script Hub. This style is what is used for updated the GUI in tabs like Stats and MemoryRead.
Example ``MemoryFunctions`` addon
The second are independent scripts that have their own timers, but the execution and stopping of the scripts are controlled by Script Hub.
Example ``MonitorGameWindowClosed`` addon