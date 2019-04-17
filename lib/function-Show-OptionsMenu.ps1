Function Show-OptionsMenu {
    <#
.SYNOPSIS

HELPER FUNCTION :: Displays options menu for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-OptionsMenu
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-OptionsMenu displays options menu for Invoke-Obfuscation.

.EXAMPLE

C:\PS> Show-OptionsMenu

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    # Set potentially-updated script-level values in $Script:OptionsMenu before displaying.
    $Counter = 0
    ForEach ($Line in $Script:OptionsMenu) {
        If ($Line[0].ToLower().Trim() -eq 'scriptpath') { $Script:OptionsMenu[$Counter][1] = $Script:ScriptPath }
        If ($Line[0].ToLower().Trim() -eq 'scriptblock') { $Script:OptionsMenu[$Counter][1] = $Script:ScriptBlock }
        If ($Line[0].ToLower().Trim() -eq 'commandlinesyntax') { $Script:OptionsMenu[$Counter][1] = $Script:CliSyntax }
        If ($Line[0].ToLower().Trim() -eq 'executioncommands') { $Script:OptionsMenu[$Counter][1] = $Script:ExecutionCommands }
        If ($Line[0].ToLower().Trim() -eq 'obfuscatedcommand') {
            # Only add obfuscatedcommand if it is different than scriptblock (to avoid showing obfuscatedcommand before it has been obfuscated).
            If ($Script:ObfuscatedCommand -cne $Script:ScriptBlock) { $Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand }
            Else { $Script:OptionsMenu[$Counter][1] = '' }
        }
        If ($Line[0].ToLower().Trim() -eq 'obfuscationlength') {
            # Only set/display ObfuscationLength if there is an obfuscated command.
            If (($Script:ObfuscatedCommand.Length -gt 0) -AND ($Script:ObfuscatedCommand -cne $Script:ScriptBlock)) { $Script:OptionsMenu[$Counter][1] = $Script:ObfuscatedCommand.Length }
            Else { $Script:OptionsMenu[$Counter][1] = '' }
        }

        $Counter++
    }
    
    # Output menu.
    Write-Host "`n`nSHOW OPTIONS" -NoNewLine -ForegroundColor Cyan
    Write-Host " ::" -NoNewLine
    Write-Host " Yellow" -NoNewLine -ForegroundColor Yellow
    Write-Host " options can be set by entering" -NoNewLine
    Write-Host " SET OPTIONNAME VALUE" -NoNewLine -ForegroundColor Green
    Write-Host ".`n"
    ForEach ($Option in $Script:OptionsMenu) {
        $OptionTitle = $Option[0]
        $OptionValue = $Option[1]
        $CanSetValue = $Option[2]
      
        Write-Host $LineSpacing -NoNewLine
        
        # For options that can be set by user, output as Yellow.
        If ($CanSetValue) { Write-Host $OptionTitle -NoNewLine -ForegroundColor Yellow }
        Else { Write-Host $OptionTitle -NoNewLine }
        Write-Host ": " -NoNewLine
        
        # Handle coloring and multi-value output for ExecutionCommands and ObfuscationLength.
        If ($OptionTitle -eq 'ObfuscationLength') {
            Write-Host $OptionValue -ForegroundColor Cyan
        }
        ElseIf ($OptionTitle -eq 'ScriptBlock') {
            Out-ScriptContents $OptionValue
        }
        ElseIf ($OptionTitle -eq 'CommandLineSyntax') {
            # CLISyntax output.
            $SetSyntax = ''
            If (($Script:ScriptPath.Length -gt 0) -AND ($Script:ScriptPath -ne 'N/A')) {
                $SetSyntax = " -ScriptPath '$Script:ScriptPath'"
            }
            ElseIf (($Script:ScriptBlock.Length -gt 0) -AND ($Script:ScriptPath -eq 'N/A')) {
                $SetSyntax = " -ScriptBlock {$Script:ScriptBlock}"
            }

            $CommandSyntax = ''
            If ($OptionValue.Count -gt 0) {
                $CommandSyntax = " -Command '" + ($OptionValue -Join ',') + "' -Quiet"
            }

            If (($SetSyntax -ne '') -OR ($CommandSyntax -ne '')) {
                $CliSyntaxToOutput = "Invoke-Obfuscation" + $SetSyntax + $CommandSyntax
                Write-Host $CliSyntaxToOutput -ForegroundColor Cyan
            }
            Else {
                Write-Host ''
            }
        }
        ElseIf ($OptionTitle -eq 'ExecutionCommands') {
            # ExecutionCommands output.
            If ($OptionValue.Count -gt 0) { Write-Host '' }
            $Counter = 0
            ForEach ($ExecutionCommand in $OptionValue) {
                $Counter++
                If ($ExecutionCommand.Length -eq 0) { Write-Host ''; Continue }
            
                $ExecutionCommand = $ExecutionCommand.Replace('$ScriptBlock', '~').Split('~')
                Write-Host "    $($ExecutionCommand[0])" -NoNewLine -ForegroundColor Cyan
                Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                
                # Handle output formatting when SHOW OPTIONS is run.
                If (($OptionValue.Count -gt 0) -AND ($Counter -lt $OptionValue.Count)) {
                    Write-Host $ExecutionCommand[1] -ForegroundColor Cyan
                }
                Else {
                    Write-Host $ExecutionCommand[1] -NoNewLine -ForegroundColor Cyan
                }

            }
            Write-Host ''
        }
        ElseIf ($OptionTitle -eq 'ObfuscatedCommand') {
            Out-ScriptContents $OptionValue
        }
        Else {
            Write-Host $OptionValue -ForegroundColor Magenta
        }
    }
    
}