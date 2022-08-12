<#
.SYNOPSIS
  Use WinDbgX to analyze .dmp files in bulk.
.DESCRIPTION
  using WinDbgX parse .dmp files in a specified directory and put their output into JSON arrays that can be used in other processes.
.PARAMETER <Parameter_Name>
  <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  .dmp files
.OUTPUTS
  ./dmps.json
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#----------[Initialisations]----------#

param (
    [Parameter(Mandatory=$True)]
    [Object]$Directory
)

#----------[Declarations]----------#

$jsonFile = './dmps.json'

#----------[Functions]----------#

Function logCreation {
    $dmps = Get-ChildItem $Directory | ? { $_.Name -Like '*.dmp' }
    ForEach ($dmp in $dmps) {
        $logFile = $dmp.Name + ".log"
        WinDbgX.exe -z "$Directory\$dmp" -c "!analyze -v ; .detach" -loga "$Directory\$logFile"
    }
}
Function jsonConversion {
    $logs = Get-ChildItem $Directory | ? { $_.Name -Like '*.log' }
    ForEach ($log in $logs) {
        $logContent = Get-Content $log
        $splits = $logContent -split '------------------'
        $splits = $splits -split 'STACK_TEXT:'
        
        # $splits[0] is trash
        # $splits[1] is before stack_text
        # $splits[2] is after stack_text
        
        $preStack = $splits[1] -replace ('^  ','SYMBOL_NAME: ')
        $stack = $($splits[2] -split 'SYMBOL_NAME:')[0]
        $postStack = $($splits[2] -split 'SYMBOL_NAME:')[1]
        
        
        $preSymbols = $preStack.split([Environment]::NewLine) | Select-String -Pattern '[A-Z]+_[A-Z]+:  *'
        $postSymbols = $postStack.split([Environment]::NewLine) | Select-String -Pattern '[A-Z]+_[A-Z]+:  *'
        $symbols = $preSymbols + $postSymbols
    }
}

#----------[Execution]----------#
logCreation
jsonConversion
