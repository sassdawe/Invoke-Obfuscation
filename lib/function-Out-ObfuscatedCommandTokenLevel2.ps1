

Function Out-ObfuscatedCommandTokenLevel2 {
    <#
.SYNOPSIS

Obfuscates command token by converting it to a concatenated string and using splatting to invoke the command.

Invoke-Obfuscation Function: Out-ObfuscatedCommandTokenLevel2
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated, Out-StringDelimitedConcatenatedAndReordered (both located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedCommandTokenLevel2 obfuscates a given command token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.PARAMETER ObfuscationLevel

Specifies whether to 1) Concatenate or 2) Reorder the splatted Command token value.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Command'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedCommandTokenLevel2 $ScriptString $Token 1}
C:\PS> $ScriptString

&('Wr'+'itE-'+'HOSt') 'Hello World!' -ForegroundColor Green; .('WrITe-Ho'+'s'+'t') 'Obfuscation Rocks!' -ForegroundColor Green

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Command'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedCommandTokenLevel2 $ScriptString $Token 1}
C:\PS> $ScriptString

&("{1}{0}{2}"-f'h','wRiTE-','ost') 'Hello World!' -ForegroundColor Green; .("{2}{1}{0}" -f'ost','-h','wrIte') 'Obfuscation Rocks!' -ForegroundColor Green

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
        $Token,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateSet(1, 2)]
        [Int]
        $ObfuscationLevel
    )

    # Set $Token.Content in a separate variable so it can be modified since Content is a ReadOnly property of $Token.
    $TokenContent = $Token.Content

    # If ticks are already present in current Token then remove so they will not interfere with string concatenation.
    If ($TokenContent.Contains('`')) { $TokenContent = $TokenContent.Replace('`', '') }

    # Convert $Token to character array for easier manipulation.
    $TokenArray = [Char[]]$TokenContent
    
    # Randomly upper- and lower-case characters in current token.
    $ObfuscatedToken = Out-RandomCase $TokenArray

    # User input $ObfuscationLevel (1-2) will choose between concatenating Command token value string (after trimming square brackets) or reordering it with the -F format operator.
    # I am leaving out Out-ObfuscatedStringCommand's option 3 since that may introduce a Type token unnecessarily ([Regex]).
    Switch ($ObfuscationLevel) {
        1 { $ObfuscatedToken = Out-StringDelimitedAndConcatenated $TokenContent -PassThru }
        2 { $ObfuscatedToken = Out-StringDelimitedConcatenatedAndReordered $TokenContent -PassThru }
        default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for Command Token Obfuscation."; Exit }
    }
     
    # Evenly trim leading/trailing parentheses.
    While ($ObfuscatedToken.StartsWith('(') -AND $ObfuscatedToken.EndsWith(')')) {
        $ObfuscatedToken = ($ObfuscatedToken.SubString(1, $ObfuscatedToken.Length - 2)).Trim()
    }

    # Encapsulate $ObfuscatedToken with parentheses.
    $ObfuscatedToken = '(' + $ObfuscatedToken + ')'
    
    # Check if the command is already prepended with an invocation operator. If it is then do not add an invocation operator.
    # E.g. & powershell -Sta -Command $cmd
    # E.g. https://github.com/adaptivethreat/Empire/blob/master/data/module_source/situational_awareness/host/Invoke-WinEnum.ps1#L139
    $SubStringLength = 15
    If ($Token.Start -lt $SubStringLength) {
        $SubStringLength = $Token.Start
    }

    # Extract substring leading up to the current token.
    $SubString = $ScriptString.SubString($Token.Start - $SubStringLength, $SubStringLength).Trim()

    # Set $InvokeOperatorAlreadyPresent boolean variable to TRUE if the substring ends with invocation operators . or &
    $InvokeOperatorAlreadyPresent = $FALSE
    If ($SubString.EndsWith('.') -OR $SubString.EndsWith('&')) {
        $InvokeOperatorAlreadyPresent = $TRUE
    }

    If (!$InvokeOperatorAlreadyPresent) {
        # Randomly choose between the & and . Invoke Operators.
        # In certain large scripts where more than one parameter are being passed into a custom function 
        # (like Add-SignedIntAsUnsigned in Invoke-Mimikatz.ps1) then using . will cause errors but & will not.
        # For now we will default to only & if $ScriptString.Length -gt 10000
        If ($ScriptString.Length -gt 10000) { $RandomInvokeOperator = '&' }
        Else { $RandomInvokeOperator = Get-Random -InputObject @('&', '.') }
    
        # Add invoke operator (and potentially whitespace) to complete splatting command.
        $ObfuscatedToken = $RandomInvokeOperator + $ObfuscatedToken
    }

    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    
    Return $ScriptString
}
