# Debug-Dmps
Script to mass process .dmp files into JSON output

<#
.SYNOPSIS
  Use WinDbgX to analyze .dmp files in bulk.
.DESCRIPTION
  using WinDbgX parse .dmp files in a specified directory and put their output into JSON arrays that can be used in other processes.
.PARAMETER Directory
  Specify the directory containing your dump files. Preferably next to the PS1 to keep things simple...
.INPUTS
  .dmp files
.OUTPUTS
  .log and .json files next to their respective .dmp files.
.EXAMPLE
  .\Debug-Dmps.ps1 -Directory .\Dumps 
#>

