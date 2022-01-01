# Libraries
## Description

These are non-system DLLs that are required by the script to perform certain functions.

## Included Files

> Ionic.Zlib.dll

The .NET libary used for gzip compression and decompression. This is required for some server calls used by the script.

> GzipWrapper.dll

The functions used in Ionic.Zlib.dll are static functions and cannot be handled natively by AHK. This library allows usage of some Ionic.Zlib.dll functionality by using dynamic objects to call the static functions. 
See https://www.autohotkey.com/boards/viewtopic.php?f=6&t=4633 for more information on how this works.
