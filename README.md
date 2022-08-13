# Debug-Dmps
Using WinDbgX parse .dmp files in a specified directory and put their output into JSON arrays that can be used in other processes.

Outputs: .log and .json files next to their respective .dmp files.

Example:

```Powershell
.\Debug-Dmps.ps1 -Directory .\Dumps 
```
