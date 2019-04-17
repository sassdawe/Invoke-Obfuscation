

Function Out-ObfuscatedVariableTokenLevel1 {
    <#
.SYNOPSIS

Obfuscates variable token by randomizing its case, randomly adding ticks and wrapping it in curly braces.

Invoke-Obfuscation Function: Out-ObfuscatedVariableTokenLevel1
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedVariableTokenLevel1 obfuscates a given token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.EXAMPLE

C:\PS> $ScriptString = "`$Message1 = 'Hello World!'; Write-Host `$Message1 -ForegroundColor Green; `$Message2 = 'Obfuscation Rocks!'; Write-Host `$Message2 -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Variable'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedVariableTokenLevel1 $ScriptString $Token}
C:\PS> $ScriptString

${m`e`ssAge1} = 'Hello World!'; Write-Host ${MEss`Ag`e1} -ForegroundColor Green; ${meSsAg`e`2} = 'Obfuscation Rocks!'; Write-Host ${M`es`SagE2} -ForegroundColor Green

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {$Message1 = 'Hello World!'; Write-Host $Message1 -ForegroundColor Green; $Message2 = 'Obfuscation Rocks!'; Write-Host $Message2 -ForegroundColor Green} 'Variable' 1
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

    # Return as-is if the variable is already encapsulated with ${}. Otherwise you will get errors if you have something like ${var} turned into ${${var}}
    If ($ScriptString.SubString($Token.Start, 2) -eq '${' -OR $ScriptString.SubString($Token.Start, 1) -eq '@') {
        Return $ScriptString
    }

    # Length of pre-obfuscated ScriptString will be important in extracting out the obfuscated token before we add curly braces.
    $PrevLength = $ScriptString.Length

    $ScriptString = Out-ObfuscatedWithTicks $ScriptString $Token   

    # Pull out ObfuscatedToken from ScriptString and add curly braces around obfuscated variable token.
    $ObfuscatedToken = $ScriptString.SubString($Token.Start, $Token.Length + ($ScriptString.Length - $PrevLength))
    $ObfuscatedToken = '${' + $ObfuscatedToken.Trim('"') + '}'

    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length + ($ScriptString.Length - $PrevLength))

    Return $ScriptString
}
