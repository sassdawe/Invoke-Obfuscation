

Function Out-RemoveComments {
    <#
.SYNOPSIS

Obfuscates variable token by removing all comment tokens. This is primarily since A/V uses strings in comments as part of many of their signatures for well known PowerShell scripts like Invoke-Mimikatz.

Invoke-Obfuscation Function: Out-RemoveComments
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-RemoveComments obfuscates a given token by removing all comment tokens from the provided PowerShell script to evade detection by simple IOCs or A/V signatures based on strings in PowerShell script comments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.EXAMPLE

C:\PS> $ScriptString = "`$Message1 = 'Hello World!'; Write-Host `$Message1 -ForegroundColor Green; `$Message2 = 'Obfuscation Rocks!'; Write-Host `$Message2 -ForegroundColor Green #COMMENT"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Comment'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-RemoveComments $ScriptString $Token}
C:\PS> $ScriptString

$Message1 = 'Hello World!'; Write-Host $Message1 -ForegroundColor Green; $Message2 = 'Obfuscation Rocks!'; Write-Host $Message2 -ForegroundColor Green

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {$Message1 = 'Hello World!'; Write-Host $Message1 -ForegroundColor Green; $Message2 = 'Obfuscation Rocks!'; Write-Host $Message2 -ForegroundColor Green #COMMENT} 'Comment' 1
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSToken]
        $Token
    )
    
    # Remove current Comment token.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}