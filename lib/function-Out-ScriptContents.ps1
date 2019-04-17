Function Out-ScriptContents {
    <#
.SYNOPSIS

HELPER FUNCTION :: Displays current obfuscated command for Invoke-Obfuscation.

Invoke-Obfuscation Function: Out-ScriptContents
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ScriptContents displays current obfuscated command for Invoke-Obfuscation.

.PARAMETER ScriptContents

Specifies the string containing your payload.

.PARAMETER PrintWarning

Switch to output redacted form of ScriptContents if they exceed 8,190 characters.

.EXAMPLE

C:\PS> Out-ScriptContents

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    Param(
        [Parameter(ValueFromPipeline = $true)]
        [String]
        $ScriptContents,

        [Switch]
        $PrintWarning
    )

    If ($ScriptContents.Length -gt $CmdMaxLength) {
        # Output ScriptContents, handling if the size of ScriptContents exceeds $CmdMaxLength characters.
        $RedactedPrintLength = $CmdMaxLength / 5
        
        # Handle printing redaction message in middle of screen. #OCD
        $CmdLineWidth = (Get-Host).UI.RawUI.BufferSize.Width
        $RedactionMessage = "<REDACTED: ObfuscatedLength = $($ScriptContents.Length)>"
        $CenteredRedactionMessageStartIndex = (($CmdLineWidth - $RedactionMessage.Length) / 2) - "[*] ObfuscatedCommand: ".Length
        $CurrentRedactionMessageStartIndex = ($RedactedPrintLength % $CmdLineWidth)
        
        If ($CurrentRedactionMessageStartIndex -gt $CenteredRedactionMessageStartIndex) {
            $RedactedPrintLength = $RedactedPrintLength - ($CurrentRedactionMessageStartIndex - $CenteredRedactionMessageStartIndex)
        }
        Else {
            $RedactedPrintLength = $RedactedPrintLength + ($CenteredRedactionMessageStartIndex - $CurrentRedactionMessageStartIndex)
        }
    
        Write-Host $ScriptContents.SubString(0, $RedactedPrintLength) -NoNewLine -ForegroundColor Magenta
        Write-Host $RedactionMessage -NoNewLine -ForegroundColor Yellow
        Write-Host $ScriptContents.SubString($ScriptContents.Length - $RedactedPrintLength) -ForegroundColor Magenta
    }
    Else {
        Write-Host $ScriptContents -ForegroundColor Magenta
    }

    # Make sure final command doesn't exceed cmd.exe's character limit.
    If ($ScriptContents.Length -gt $CmdMaxLength) {
        If ($PSBoundParameters['PrintWarning']) {
            Write-Host "`nWARNING: This command exceeds the cmd.exe maximum length of $CmdMaxLength." -ForegroundColor Red
            Write-Host "         Its length is" -NoNewLine -ForegroundColor Red
            Write-Host " $($ScriptContents.Length)" -NoNewLine -ForegroundColor Yellow
            Write-Host " characters." -ForegroundColor Red
        }
    }
}