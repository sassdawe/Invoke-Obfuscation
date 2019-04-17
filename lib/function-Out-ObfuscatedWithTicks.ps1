

Function Out-ObfuscatedWithTicks {
    <#
.SYNOPSIS

HELPER FUNCTION :: Obfuscates any token by randomizing its case and randomly adding ticks. It takes PowerShell special characters into account so you will get `N instead of `n, `T instead of `t, etc.

Invoke-Obfuscation Function: Out-ObfuscatedWithTicks
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedWithTicks obfuscates given input as a helper function to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Command'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedWithTicks $ScriptString $Token}
C:\PS> $ScriptString

WrI`Te-Ho`sT 'Hello World!' -ForegroundColor Green; WrIte-`hO`S`T 'Obfuscation Rocks!' -ForegroundColor Green

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 'Command' 2
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

    # If ticks are already present in current Token then Return $ScriptString as is.
    If ($Token.Content.Contains('`')) {
        Return $ScriptString
    }
    
    # The Parameter Attributes in $MemberTokensToOnlyRandomCase (defined at beginning of script) cannot be obfuscated like other Member Tokens
    # For these tokens we will only randomize the case and then return as is.
    # Source: https://social.technet.microsoft.com/wiki/contents/articles/15994.powershell-advanced-function-parameter-attributes.aspx
    If ($MemberTokensToOnlyRandomCase -Contains $Token.Content.ToLower()) {
        $ObfuscatedToken = Out-RandomCase $Token.Content
        $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
        Return $ScriptString
    }

    # Set boolean variable to encapsulate member with double quotes if it is setting a value like below.
    # E.g. New-Object PSObject -Property @{ "P`AY`LOaDS" = $Payload }
    $EncapsulateWithDoubleQuotes = $FALSE
    If ($ScriptString.SubString(0, $Token.Start).Contains('@{') -AND ($ScriptString.SubString($Token.Start + $Token.Length).Trim()[0] -eq '=')) {
        $EncapsulateWithDoubleQuotes = $TRUE
    }
    
    # Convert $Token to character array for easier manipulation.
    $TokenArray = [Char[]]$Token.Content

    # Randomly upper- and lower-case characters in current token.
    $TokenArray = Out-RandomCase $TokenArray

    # Choose a random percentage of characters to obfuscate with ticks in current token.
    $ObfuscationPercent = Get-Random -Minimum 15 -Maximum 30
    
    # Convert $ObfuscationPercent to the exact number of characters to obfuscate in the current token.
    $NumberOfCharsToObfuscate = [int]($Token.Length * ($ObfuscationPercent / 100))

    # Guarantee that at least one character will be obfuscated.
    If ($NumberOfCharsToObfuscate -eq 0) { $NumberOfCharsToObfuscate = 1 }

    # Select random character indexes to obfuscate with ticks (excluding first and last character in current token).
    $CharIndexesToObfuscate = (Get-Random -InputObject (1..($TokenArray.Length - 2)) -Count $NumberOfCharsToObfuscate)
    
    # Special characters in PowerShell must be upper-cased before adding a tick before the character.
    $SpecialCharacters = @('a', 'b', 'f', 'n', 'r', 'u', 't', 'v', '0')
 
    # Remove the possibility of a single tick being placed only before the token string.
    # This would leave the string value completely intact, thus defeating the purpose of the tick obfuscation.
    $ObfuscatedToken = '' #$NULL
    $ObfuscatedToken += $TokenArray[0]
    For ($i = 1; $i -le $TokenArray.Length - 1; $i++) {
        $CurrentChar = $TokenArray[$i]
        If ($CharIndexesToObfuscate -Contains $i) {
            # Set current character to upper case in case it is in $SpecialCharacters (i.e., `N instead of `n so it's not treated as a newline special character)
            If ($SpecialCharacters -Contains $CurrentChar) { $CurrentChar = ([string]$CurrentChar).ToUpper() }
            
            # Skip adding a tick if character is a special character where case does not apply.
            If ($CurrentChar -eq '0') { $ObfuscatedToken += $CurrentChar; Continue }
            
            # Add tick.
            $ObfuscatedToken += '`' + $CurrentChar
        }
        Else {
            $ObfuscatedToken += $CurrentChar
        }
    }

    # If $Token immediately follows a . or :: (and does not begin $ScriptString) then encapsulate with double quotes so ticks are valid.
    # E.g. both InvokeCommand and InvokeScript in $ExecutionContext.InvokeCommand.InvokeScript
    If ((($Token.Start -gt 0) -AND ($ScriptString.SubString($Token.Start - 1, 1) -eq '.')) -OR (($Token.Start -gt 1) -AND ($ScriptString.SubString($Token.Start - 2, 2) -eq '::'))) {
        # Encapsulate the obfuscated token with double quotes since ticks were introduced.
        $ObfuscatedToken = '"' + $ObfuscatedToken + '"'
    }
    ElseIf ($EncapsulateWithDoubleQuotes) {
        # Encapsulate the obfuscated token with double quotes since ticks were introduced.
        $ObfuscatedToken = '"' + $ObfuscatedToken + '"'
    }

    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}
