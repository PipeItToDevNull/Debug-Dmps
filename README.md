# Debug-Dmps
```Powershell
<#
.SYNOPSIS
  Analyze .dmp files in bulk.
.DESCRIPTION
  Using Windows SDK Debugging tools parse .dmp files in a singles or batch and put their output into JSON arrays that can be used in other processes.
.PARAMETER Target
  Specify the specific dmp file or a directory containing multiple dmp files
.INPUTS
  .dmp files
.OUTPUTS
  JSON array is sent to STDOUT
.EXAMPLE
  .\Debug-Dmps.ps1 -Target .\Dumps
#>
```
