# Debug-Dmps
Using WinDbgX parse .dmp files in a specified directory and put their output into JSON arrays that can be used in other processes.

Outputs: .log and .json files next to their respective .dmp files, as well as the complete non-JSON object output to the terminal for capture in a variable.

Example:

```Powershell
$json = .\Debug-Dmps.ps1 -Directory .\Dumps 
```

To load existing JSON back into a variable use:

```powershell
$json = Get-Content -Raw .\Dumps\*.json | ConvertFrom-Json
```
