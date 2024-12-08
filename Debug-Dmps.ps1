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

#----------[Initialisations]----------#

param (
    [Parameter(Mandatory=$True)]
    [Object]$Target
)

#----------[Declarations]----------#

#----------[Functions]----------#

Function Process-Dmps {
    $dmpArray = @()
    If (!($(Get-Item -Path $Target).PSIsContainer)) {
            $dmp = $(Get-Item -Path $Target).FullName
            $dmpArray += Process-DmpObject
        } Else {
            $dmps = Get-ChildItem $Target | ? { $_.Name -Like '*.dmp' }
            ForEach ($dmp in $dmps) {
                $dmp = $dmp.FullName
                $dmpArray += Process-DmpObject
        }
    }
	Return $dmpArray | ConvertTo-Json -AsArray
}

Function Process-DmpObject {
    ###################
    # Debug Execution #
    ###################
    $parser = "cdb.exe"
    $command = "-z $dmp -c `"k; !analyze -v ; q`""

    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $parser
    $startInfo.Arguments = $command
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true

    # You have to start reading before processing or you get a deadlock
    # https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.process.standardoutput?view=net-5.0#remarks
    # Start the process
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    
    $rawContent = $process.StandardOutput.ReadToEnd()
    $errorOutput = $process.StandardError.ReadToEnd()

    $process.WaitForExit()
  
    ###############
    # Splitsville #
    ###############

    $splits = $rawContent -split '------------------'
    $splits = $splits -split 'STACK_TEXT:'

    # $splits[0] is info
    # $splits[1] is before stack_text
    # $splits[2] is after stack_text. Not all dumps have [2]

    ###################
    # Post-Processing #
    ###################

    If ($splits.length -ne "2" -AND $splits.length -ne "3") {
        Throw "Abnormal file cannot be post-processed"
    }

    $infos = $splits[0] -split 'Bugcheck Analysis'

    # Pulling dmp info
    $dirtyDmpInfo0 = $infos[0] -split "Copyright \(c\) Microsoft Corporation\. All rights reserved\."
    $dirtyDmpInfo1 = $dirtyDmpInfo0[1] -split "Loading Kernel Symbols"
    $dmpInfo = $dirtyDmpInfo1[0].Trim()

    # Pulling Bugheck Analysis	
    $analysis = $infos[1] -split "\n" | Where-Object { $_ -notmatch '\*' -AND $_ -notmatch "Debugging Details:" }
    $analysis = $analysis.Trim()
    $analysis = $analysis -join "`n"

    ##########################
    # Output object creation #
    ##########################
    $output = @{}
    $output["dmpInfo"] = $dmpInfo
    $output["analysis"] = $analysis
    $output["rawContent"] = $rawContent

    Try {
        If ($splits.length -eq 2) {
                
            $symbols = $splits[1].split([Environment]::NewLine) | Select-String -Pattern '[A-Z]+(_[A-Z0-9]+)?:  *' -CaseSensitive
            $cleanSymbols = $symbols -replace ':[ \t]+','='

            $fields = @(
                "BUGCHECK_CODE",
                "BUGCHECK_P1",
                "BUGCHECK_P2",
                "BUGCHECK_P3",
                "BUGCHECK_P4",
                "FILE_IN_CAB"
            )
            
            $cleanSymbols -split "`n" | ForEach-Object {
                ForEach ($field in $fields) {
                    If ($_ -match "^$field=(.*)$") {
                        $output[$field] = $matches[1].Trim()
                    }
                }
            }

            } Else {

            $preStack = $splits[1] -replace ('^  ','SYMBOL_NAME: ')
            $stack = $($splits[2] -split 'SYMBOL_NAME:')[0]
            $postStack = $($splits[2] -split 'SYMBOL_NAME:')[1]

            $preSymbols = $preStack.split([Environment]::NewLine) | Select-String -Pattern '[A-Z]+(_[A-Z0-9]+)?:  *' -CaseSensitive 
            $cleanPreSymbols = $preSymbols -replace ':[ \t]+','=' 

            $postSymbols = $postStack.split([Environment]::NewLine) | Select-String -Pattern '[A-Z]+(_[A-Z0-9]+)?:  *'
            $cleanPostSymbols = $postSymbols -replace ':[ \t]+','=' 

            # Pick out the preSymbol values we care about
            $preFields = @(
                "BUGCHECK_CODE",
                "BUGCHECK_P1",
                "BUGCHECK_P2",
                "BUGCHECK_P3",
                "BUGCHECK_P4",
                "FILE_IN_CAB",
                "SECURITY_COOKIE",
                "BLACKBOXBSD",
                "BLACKBOXNTFS",
                "BLACKBOXPNP",
                "BLACKBOXWINLOGON",
                "PROCESS_NAME"
            )
            
            $cleanPreSymbols -split "`n" | ForEach-Object {
                ForEach ($field in $preFields) {
                    If ($_ -match "^$field=(.*)$") {
                        $output[$field] = $matches[1].Trim()
                    }
                }
            }
            
            # Pick out the postSymbol values we care about
            $postFields = @(
                "MODULE_NAME",
                "IMAGE_NAME",
                "IMAGE_VERSION",
                "STACK_COMMAND",
                "BUCKET_ID_FUNC_OFFSET",
                "FAILURE_BUCKET_ID",
                "OS_VERSION",
                "BUILDLAB_STR",
                "OSPLATFORM_TYPE",
                "OSNAME",
                "FAILURE_ID_HASH"
            )
            
            $cleanPostSymbols -split "`n" | ForEach-Object {
                ForEach ($field in $postFields) {
                    If ($_ -match "^$field=(.*)$") {
                        $output[$field] = $matches[1].Trim()
                    }
                }
            }
        }
    } catch {
        # Post processing failed but we write nothing to the host because it would break downstream inputs
    }
    ###########
    # Outputs #
    ########### 
    $output 
}

#----------[Execution]----------#
Process-Dmps
