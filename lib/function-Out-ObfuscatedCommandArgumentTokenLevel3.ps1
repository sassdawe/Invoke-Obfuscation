

Function Out-ObfuscatedCommandArgumentTokenLevel3 {
    <#
.SYNOPSIS

Obfuscates command argument token by randomly concatenating the command argument as a string and encapsulating it with parentheses.

Invoke-Obfuscation Function: Out-ObfuscatedCommandArgumentTokenLevel3
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated, Out-StringDelimitedConcatenatedAndReordered (both located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedCommandArgumentTokenLevel3 obfuscates a given token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.PARAMETER ObfuscationLevel

Specifies whether to 1) Concatenate or 2) Reorder the Argument token value.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'CommandArgument'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedCommandArgumentTokenLevel3 $ScriptString $Token 1}
C:\PS> $ScriptString

Write-Host 'Hello World!' -ForegroundColor ('Gr'+'een'); Write-Host 'Obfuscation Rocks!' -ForegroundColor ("Gree"+"n")

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'CommandArgument'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedCommandArgumentTokenLevel3 $ScriptString $Token 2}
C:\PS> $ScriptString

Write-Host 'Hello World!' -ForegroundColor ("{1}{0}"-f 'een','Gr'); Write-Host 'Obfuscation Rocks!' -ForegroundColor ("{0}{1}" -f 'Gre','en')

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 'CommandArgument' 3
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
        $Token,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateSet(1, 2)]
        [Int]
        $ObfuscationLevel
    )

    # Function name declarations are CommandArgument tokens that cannot be obfuscated with concatenations.
    # For these we will obfuscated them with ticks because this changes the string from AMSI's perspective but not the final functionality.
    If ($ScriptString.SubString(0, $Token.Start - 1).Trim().ToLower().EndsWith('function') -or $ScriptString.SubString(0, $Token.Start - 1).Trim().ToLower().EndsWith('filter')) {
        $ScriptString = Out-ObfuscatedWithTicks $ScriptString $Token
        Return $ScriptString
    }

    # Set $Token.Content in a separate variable so it can be modified since Content is a ReadOnly property of $Token.
    $TokenContent = $Token.Content
    
    # If ticks are already present in current Token then remove so they will not interfere with string concatenation.
    If ($TokenContent.Contains('`')) { $TokenContent = $TokenContent.Replace('`', '') }

    # User input $ObfuscationLevel (1-2) will choose between concatenating CommandArgument token value string or reordering it with the -F format operator.
    # I am leaving out Out-ObfuscatedStringCommand's option 3 since that may introduce a Type token unnecessarily ([Regex]).
    Switch ($ObfuscationLevel) {
        1 { $ObfuscatedToken = Out-StringDelimitedAndConcatenated $TokenContent -PassThru }
        2 { $ObfuscatedToken = Out-StringDelimitedConcatenatedAndReordered $TokenContent -PassThru }
        default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for Argument Token Obfuscation."; Exit }
    }
    
    # Evenly trim leading/trailing parentheses -- .Trim does this unevenly.
    While ($ObfuscatedToken.StartsWith('(') -AND $ObfuscatedToken.EndsWith(')')) {
        $ObfuscatedToken = ($ObfuscatedToken.SubString(1, $ObfuscatedToken.Length - 2)).Trim()
    }

    # Encapsulate $ObfuscatedToken with parentheses.
    $ObfuscatedToken = '(' + $ObfuscatedToken + ')'
    
    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}
