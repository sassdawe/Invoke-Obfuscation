

Function Out-RandomCaseToken {
    <#
.SYNOPSIS

HELPER FUNCTION :: Obfuscates any token by randomizing its case and reinserting it into the ScriptString input variable.

Invoke-Obfuscation Function: Out-RandomCaseToken
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-RandomCaseToken obfuscates given input as a helper function to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'CommandArgument'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-RandomCaseToken $ScriptString $Token}
C:\PS> $ScriptString

Write-Host 'Hello World!' -ForegroundColor GREeN; Write-Host 'Obfuscation Rocks!' -ForegroundColor gReeN

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 'CommandArgument' 1
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
                
    # Convert $Token to character array for easier manipulation.
    $TokenArray = [Char[]]$Token.Content
    
    # Randomly upper- and lower-case characters in current token.
    $TokenArray = Out-RandomCase $TokenArray
    
    # Convert character array back to string.
    $ObfuscatedToken = $TokenArray -Join ''
    
    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}
