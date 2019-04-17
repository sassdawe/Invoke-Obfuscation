

Function Out-ObfuscatedMemberTokenLevel3 {
    <#
.SYNOPSIS

Obfuscates member token by randomizing its case, randomly concatenating the member as a string and adding the .invoke operator. This enables us to treat a member token as a string to gain the obfuscation benefits of a string.

Invoke-Obfuscation Function: Out-ObfuscatedMemberTokenLevel3
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated, Out-StringDelimitedConcatenatedAndReordered (both located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedMemberTokenLevel3 obfuscates a given token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Tokens

Specifies the token array containing the token we will obfuscate.

.PARAMETER Index

Specifies the index of the token to obfuscate.

.PARAMETER ObfuscationLevel

Specifies whether to 1) Concatenate or 2) Reorder the Member token value.

.EXAMPLE

C:\PS> $ScriptString = "[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {If($Tokens[$i].Type -eq 'Member') {$ScriptString = Out-ObfuscatedMemberTokenLevel3 $ScriptString $Tokens $i 1}}
C:\PS> $ScriptString

[console]::('wR'+'It'+'eline').Invoke('Hello World!'); [console]::('wrItEL'+'IN'+'E').Invoke('Obfuscation Rocks!')

C:\PS> $ScriptString = "[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null)
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {If($Tokens[$i].Type -eq 'Member') {$ScriptString = Out-ObfuscatedMemberTokenLevel3 $ScriptString $Tokens $i 2}}
C:\PS> $ScriptString

[console]::("{0}{2}{1}"-f 'W','ITEline','r').Invoke('Hello World!'); [console]::("{2}{1}{0}" -f 'liNE','RITE','W').Invoke('Obfuscation Rocks!')

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')} 'Member' 3
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
        $Index,

        [Parameter(Position = 3, Mandatory = $True)]
        [ValidateSet(1, 2)]
        [Int]
        $ObfuscationLevel
    )

    $Token = $Tokens[$Index]

    # The Parameter Attributes in $MemberTokensToOnlyRandomCase (defined at beginning of script) cannot be obfuscated like other Member Tokens
    # For these tokens we will only randomize the case and then return as is.
    # Source: https://social.technet.microsoft.com/wiki/contents/articles/15994.powershell-advanced-function-parameter-attributes.aspx
    If ($MemberTokensToOnlyRandomCase -Contains $Token.Content.ToLower()) {
        $ObfuscatedToken = Out-RandomCase $Token.Content
        $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
        Return $ScriptString
    }

    # If $Token immediately follows a . or :: (and does not begin $ScriptString) of if followed by [] type cast within 
    #   parentheses then only allow Member token to be obfuscated with ticks and quotes.
    # The exception to this is when the $Token is immediately followed by an opening parenthese, like in .DownloadString(
    # E.g. both InvokeCommand and InvokeScript in $ExecutionContext.InvokeCommand.InvokeScript
    # E.g. If $Token is 'Invoke' then concatenating it and then adding .Invoke() would be redundant.
    $RemainingSubString = 50
    If ($RemainingSubString -gt $ScriptString.SubString($Token.Start + $Token.Length).Length) {
        $RemainingSubString = $ScriptString.SubString($Token.Start + $Token.Length).Length
    }

    # Parse out $SubSubString to make next If block a little cleaner for handling fringe cases in which we will revert to ticks instead of concatenation or reordering of the Member token value.
    $SubSubString = $ScriptString.SubString($Token.Start + $Token.Length, $RemainingSubString)
    
    If (($Token.Content.ToLower() -eq 'invoke') `
            -OR ($Token.Content.ToLower() -eq 'computehash') `
            -OR ($Token.Content.ToLower() -eq 'tobase64string') `
            -OR ($Token.Content.ToLower() -eq 'getstring') `
            -OR ($Token.Content.ToLower() -eq 'getconstructor') `
            -OR (((($Token.Start -gt 0) -AND ($ScriptString.SubString($Token.Start - 1, 1) -eq '.')) `
                    -OR (($Token.Start -gt 1) -AND ($ScriptString.SubString($Token.Start - 2, 2) -eq '::'))) `
                -AND (($ScriptString.Length -ge $Token.Start + $Token.Length + 1) -AND (($SubSubString.SubString(0, 1) -ne '(') -OR (($SubSubString.Contains('[')) -AND !($SubSubString.SubString(0, $SubSubString.IndexOf('[')).Contains(')'))))))) {
        # We will use the scriptString length prior to obfuscating 'invoke' to help extract the this token after obfuscation so we can add quotes before re-inserting it. 
        $PrevLength = $ScriptString.Length

        # Obfuscate 'invoke' token with ticks.
        $ScriptString = Out-ObfuscatedWithTicks $ScriptString $Token
        
        #$TokenLength = 'invoke'.Length + ($ScriptString.Length - $PrevLength)
        $TokenLength = $Token.Length + ($ScriptString.Length - $PrevLength)
        
        # Encapsulate obfuscated and extracted token with double quotes if it is not already.
        $ObfuscatedTokenExtracted = $ScriptString.SubString($Token.Start, $TokenLength)
        If ($ObfuscatedTokenExtracted.StartsWith('"') -AND $ObfuscatedTokenExtracted.EndsWith('"')) {
            $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedTokenExtracted + $ScriptString.SubString($Token.Start + $TokenLength)
        }
        Else {
            $ScriptString = $ScriptString.SubString(0, $Token.Start) + '"' + $ObfuscatedTokenExtracted + '"' + $ScriptString.SubString($Token.Start + $TokenLength)
        }

        Return $ScriptString
    }

    # Set $Token.Content in a separate variable so it can be modified since Content is a ReadOnly property of $Token.
    $TokenContent = $Token.Content
    
    # If ticks are already present in current Token then remove so they will not interfere with string concatenation.
    If ($TokenContent.Contains('`')) { $TokenContent = $TokenContent.Replace('`', '') }

    # Convert $Token to character array for easier manipulation.
    $TokenArray = [Char[]]$TokenContent

    # Randomly upper- and lower-case characters in current token.
    $TokenArray = Out-RandomCase $TokenArray
    
    # User input $ObfuscationLevel (1-2) will choose between concatenating Member token value string or reordering it with the -F format operator.
    # I am leaving out Out-ObfuscatedStringCommand's option 3 since that may introduce a Type token unnecessarily ([Regex]).
    Switch ($ObfuscationLevel) {
        1 { $ObfuscatedToken = Out-StringDelimitedAndConcatenated $TokenContent -PassThru }
        2 { $ObfuscatedToken = Out-StringDelimitedConcatenatedAndReordered $TokenContent -PassThru }
        default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for Member Token Obfuscation."; Exit }
    }
    
    # Evenly trim leading/trailing parentheses -- .Trim does this unevenly.
    While ($ObfuscatedToken.StartsWith('(') -AND $ObfuscatedToken.EndsWith(')')) {
        $ObfuscatedToken = ($ObfuscatedToken.SubString(1, $ObfuscatedToken.Length - 2)).Trim()
    }

    # Encapsulate $ObfuscatedToken with parentheses.
    $ObfuscatedToken = '(' + $ObfuscatedToken + ')'

    # Retain current token before re-tokenizing if 'invoke' member was introduced (see next For loop below)
    $InvokeToken = $Token
    # Retain how much the token has increased during obfuscation process so far.
    $TokenLengthIncrease = $ObfuscatedToken.Length - $Token.Content.Length

    # Add .Invoke if Member token was originally immediately followed by '('
    If (($Index -lt $Tokens.Count) -AND ($Tokens[$Index + 1].Content -eq '(') -AND ($Tokens[$Index + 1].Type -eq 'GroupStart')) {
        $ObfuscatedToken = $ObfuscatedToken + '.Invoke'
    }
    
    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)  

    Return $ScriptString
}
