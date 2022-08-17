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
  .log and .json files next to their respective .dmp files. The contents of the JSON files is also output to the terminal, for caputure in a single variable.
.EXAMPLE
  .\Debug-Dmps.ps1 -Directory .\Dumps 
#>

#----------[Initialisations]----------#

param (
    [Parameter(Mandatory=$True)]
    [Object]$Directory
)

#----------[Declarations]----------#


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
        $jsonFile = $log.Fullname -replace '.log','.json'
        $logContent = Get-Content -Raw $log.FullName
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
        $symbols = $symbols -replace ':[ \t]+','='
        $jsonSymbols = $symbols

        $splitStack = $stack.split([Environment]::NewLine)
        $i = 0
        $stackObject = @()
        ForEach ($line in $splitStack) {
            $validLine = $line | ? { $_ -Match '[a-z][A-Z][0-9]' } 
            If ($validLine -NotLike $null) {
                $stackObject += $validLine -replace '^',"$i= "
                $i++
            }
        }

        # this makes a dirty array
        $arrayObject = $jsonSymbols + $stackObject
        $array = $arrayObject | ConvertFrom-StringData 

        # convert our array to an object
        $output = New-Object PSObject
        ForEach ($a in $array) {
            Add-Member -InputObject $output -MemberType NoteProperty -Name $a.Keys -Value $a.$($a.Keys)
        }

        $json = $output | ConvertTo-Json
        Set-Content -Value $json -Path $jsonFile
        $output
    }
}

#----------[Execution]----------#
logCreation
jsonConversion
