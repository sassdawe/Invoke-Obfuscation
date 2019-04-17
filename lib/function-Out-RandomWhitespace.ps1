

Function Out-RandomWhitespace {
    <#
.SYNOPSIS

Obfuscates operator/groupstart/groupend/statementseparator token by adding random amounts of whitespace before/after the token depending on the token value and its immediate surroundings in the input script.

Invoke-Obfuscation Function: Out-RandomWhitespace
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-RandomWhitespace adds random whitespace before/after a given token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Tokens

Specifies the token array containing the token we will obfuscate.

.PARAMETER Index

Specifies the index of the token to obfuscate.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host ('Hel'+'lo Wo'+'rld!') -ForegroundColor Green; Write-Host ('Obfu'+'scation Ro'+'cks!') -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {If(($Tokens[$i].Type -eq 'Operator') -OR ($Tokens[$i].Type -eq 'GroupStart') -OR ($Tokens[$i].Type -eq 'GroupEnd')) {$ScriptString = Out-RandomWhitespace $ScriptString $Tokens $i}}
C:\PS> $ScriptString

Write-Host ('Hel'+  'lo Wo'  + 'rld!') -ForegroundColor Green; Write-Host ( 'Obfu'  +'scation Ro' +  'cks!') -ForegroundColor Green

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {Write-Host ('Hel'+'lo Wo'+'rld!') -ForegroundColor Green; Write-Host ('Obfu'+'scation Ro'+'cks!') -ForegroundColor Green} 'RandomWhitespace' 1
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
        [System.Management.Automation.PSToken[]]
        $Tokens,
        
        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $Index
    )
        
    $Token = $Tokens[$Index]

    $ObfuscatedToken = $Token.Content
    
    # Do not add DEFAULT setting in below Switch block.
    Switch ($Token.Content) {
        '(' { $ObfuscatedToken = $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        ')' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken }
        ';' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        '|' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        '+' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        '=' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        '&' { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        '.' {
            # Retrieve character in script immediately preceding the current token
            If ($Index -eq 0) { $PrevChar = ' ' }
            Else { $PrevChar = $ScriptString.SubString($Token.Start - 1, 1) }
            
            # Only add randomized whitespace to . if it is acting as a standalone invoke operator (either at the beginning of the script or immediately preceded by ; or whitespace)
            If (($PrevChar -eq ' ') -OR ($PrevChar -eq ';')) { $ObfuscatedToken = ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ObfuscatedToken + ' ' * (Get-Random -Minimum 0 -Maximum 3) }
        }
    }
    
    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}
