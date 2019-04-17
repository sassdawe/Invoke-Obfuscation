

Function Out-ObfuscatedTypeToken {
    <#
.SYNOPSIS

Obfuscates type token by using direct type cast syntax and concatenating or reordering the Type token value.
This function only applies to Type tokens immediately followed by . or :: operators and then a Member token.
E.g. [Char][Int]'123' will not be obfuscated by this function, but [Console]::WriteLine will be obfuscated.

Invoke-Obfuscation Function: Out-ObfuscatedTypeToken
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated, Out-StringDelimitedConcatenatedAndReordered (both located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedTypeToken obfuscates a given token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.PARAMETER ObfuscationLevel

Specifies whether to 1) Concatenate or 2) Reorder the Type token value.

.EXAMPLE

C:\PS> $ScriptString = "[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Type'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedTypeToken $ScriptString $Token 1}
C:\PS> $ScriptString

sET  EOU ( [TYPe]('CO'+'NS'+'oLe')) ;    (  CHILdiTEM  VariablE:EOU ).VALUE::WriteLine('Hello World!');   $eoU::WriteLine('Obfuscation Rocks!')

C:\PS> $ScriptString = "[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'Type'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedTypeToken $ScriptString $Token 2}
C:\PS> $ScriptString

SET-vAriablE  BVgz6n ([tYpe]("{2}{1}{0}" -f'sOle','On','C')  )  ;    $BVGz6N::WriteLine('Hello World!');  ( cHilDItem  vAriAbLE:bVGZ6n ).VAlue::WriteLine('Obfuscation Rocks!')

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')} 'Type' 1
C:\PS> Out-ObfuscatedTokenCommand {[console]::WriteLine('Hello World!'); [console]::WriteLine('Obfuscation Rocks!')} 'Type' 2
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

    # If we are dealing with a Type that is found in $TypesThatCannotByDirectTypeCasted then return as is since it will error if we try to direct Type cast.
    ForEach ($Type in $TypesThatCannotByDirectTypeCasted) {
        If ($Token.Content.ToLower().Contains($Type)) {
            Return $ScriptString
        }
    }

    # If we are dealing with a Type that is NOT immediately followed by a Member token (denoted by . or :: operators) then we won't obfuscated.
    # This is for Type tokens like: [Char][Int]'123' etc.
    If (($ScriptString.SubString($Token.Start + $Script:TypeTokenScriptStringGrowth + $Token.Length, 1) -ne '.') -AND ($ScriptString.SubString($Token.Start + $Script:TypeTokenScriptStringGrowth + $Token.Length, 2) -ne '::')) {
        Return $ScriptString
    }

    # This variable will be used to track the growth in length of $ScriptString since we'll be appending variable creation at the beginning of $ScriptString.
    # This will allow us to avoid tokenizing $ScriptString for every single Type token that is present.
    $PrevLength = $ScriptString.Length

    # See if we've already set another instance of this same Type token previously in this obfsucation iteration.
    $RandomVarName = $NULL
    $UsingPreviouslyDefinedVarName = $FALSE
    ForEach ($DefinedTokenVariable in $Script:TypeTokenVariableArray) {
        If ($Token.Content.ToLower() -eq $DefinedTokenVariable[0]) {
            $RandomVarName = $DefinedTokenVariable[1]
            $UsingPreviouslyDefinedVarName = $TRUE
        }
    }

    # If we haven't already defined a random variable for this Token type then we will do that. Otherwise we will use the previously-defined variable.
    If (!($UsingPreviouslyDefinedVarName)) {
        # User input $ObfuscationLevel (1-2) will choose between concatenating Type token value string (after trimming square brackets) or reordering it with the -F format operator.
        # I am leaving out Out-ObfuscatedStringCommand's option 3 since that may introduce another Type token unnecessarily ([Regex]).

        # Trim of encapsulating square brackets before obfuscating the string value of the Type token.
        $TokenContent = $Token.Content.Trim('[]')

        Switch ($ObfuscationLevel) {
            1 { $ObfuscatedToken = Out-StringDelimitedAndConcatenated $TokenContent -PassThru }
            2 { $ObfuscatedToken = Out-StringDelimitedConcatenatedAndReordered $TokenContent -PassThru }
            default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for Type Token Obfuscation."; Exit }
        }
        
        # Evenly trim leading/trailing parentheses.
        While ($ObfuscatedToken.StartsWith('(') -AND $ObfuscatedToken.EndsWith(')')) {
            $ObfuscatedToken = ($ObfuscatedToken.SubString(1, $ObfuscatedToken.Length - 2)).Trim()
        }

        # Add syntax for direct type casting.
        $ObfuscatedTokenTypeCast = '[type]' + '(' + $ObfuscatedToken + ')'

        # Characters we will use to generate random variable names.
        # For simplicity do NOT include single- or double-quotes in this array.
        $CharsToRandomVarName = @(0..9)
        $CharsToRandomVarName += @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z')

        # Randomly choose variable name starting length.
        $RandomVarLength = (Get-Random -Input @(3..6))
   
        # Create random variable with characters from $CharsToRandomVarName.
        If ($CharsToRandomVarName.Count -lt $RandomVarLength) { $RandomVarLength = $CharsToRandomVarName.Count }
        $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ', '')

        # Keep generating random variables until we find one that is not a substring of $ScriptString.
        While ($ScriptString.ToLower().Contains($RandomVarName.ToLower())) {
            $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ', '')
            $RandomVarLength++
        }

        # Track this variable name and Type token so we can reuse this variable name for future uses of this same Type token in this obfuscation iteration.
        $Script:TypeTokenVariableArray += , @($Token.Content, $RandomVarName)
    }

    # Randomly decide if the variable name will be concatenated inline or not.
    # Handle both <varname> and <variable:varname> syntaxes depending on which option is chosen concerning GET variable syntax.
    $RandomVarNameMaybeConcatenated = $RandomVarName
    $RandomVarNameMaybeConcatenatedWithVariablePrepended = 'variable:' + $RandomVarName
    If ((Get-Random -Input @(0..1)) -eq 0) {
        $RandomVarNameMaybeConcatenated = '(' + (Out-ConcatenatedString $RandomVarName (Get-Random -Input @('"', "'"))) + ')'
        $RandomVarNameMaybeConcatenatedWithVariablePrepended = '(' + (Out-ConcatenatedString "variable:$RandomVarName" (Get-Random -Input @('"', "'"))) + ')'
    }
    
    # Generate random variable SET syntax.
    $RandomVarSetSyntax = @()
    $RandomVarSetSyntax += '$' + $RandomVarName + ' ' * (Get-Random @(0..2)) + '=' + ' ' * (Get-Random @(0..2)) + $ObfuscatedTokenTypeCast
    $RandomVarSetSyntax += (Get-Random -Input @('Set-Variable', 'SV', 'Set')) + ' ' * (Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + ' ' * (Get-Random @(1..2)) + '(' + ' ' * (Get-Random @(0..2)) + $ObfuscatedTokenTypeCast + ' ' * (Get-Random @(0..2)) + ')'
    $RandomVarSetSyntax += 'Set-Item' + ' ' * (Get-Random @(1..2)) + $RandomVarNameMaybeConcatenatedWithVariablePrepended + ' ' * (Get-Random @(1..2)) + '(' + ' ' * (Get-Random @(0..2)) + $ObfuscatedTokenTypeCast + ' ' * (Get-Random @(0..2)) + ')'

    # Randomly choose from above variable syntaxes.
    $RandomVarSet = (Get-Random -Input $RandomVarSetSyntax)

    # Randomize the case of selected variable syntaxes.
    $RandomVarSet = Out-RandomCase $RandomVarSet
  
    # Generate random variable GET syntax.
    $RandomVarGetSyntax = @()
    $RandomVarGetSyntax += '$' + $RandomVarName
    $RandomVarGetSyntax += '(' + ' ' * (Get-Random @(0..2)) + (Get-Random -Input @('Get-Variable', 'Variable')) + ' ' * (Get-Random @(1..2)) + $RandomVarNameMaybeConcatenated + (Get-Random -Input ((' ' * (Get-Random @(0..2)) + ').Value'), (' ' * (Get-Random @(1..2)) + ('-ValueOnly'.SubString(0, (Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length + 1)))) + ' ' * (Get-Random @(0..2)) + ')')))
    $RandomVarGetSyntax += '(' + ' ' * (Get-Random @(0..2)) + (Get-Random -Input @('DIR', 'Get-ChildItem', 'GCI', 'ChildItem', 'LS', 'Get-Item', 'GI', 'Item')) + ' ' * (Get-Random @(1..2)) + $RandomVarNameMaybeConcatenatedWithVariablePrepended + ' ' * (Get-Random @(0..2)) + ').Value'
    
    # Randomly choose from above variable syntaxes.
    $RandomVarGet = (Get-Random -Input $RandomVarGetSyntax)

    # Randomize the case of selected variable syntaxes.
    $RandomVarGet = Out-RandomCase $RandomVarGet

    # If we're using an existing variable already set in ScriptString for the current Type token then we don't need to prepend an additional SET variable syntax.
    $PortionToPrependToScriptString = ''
    If (!($UsingPreviouslyDefinedVarName)) {
        $PortionToPrependToScriptString = ' ' * (Get-Random @(0..2)) + $RandomVarSet + ' ' * (Get-Random @(0..2)) + ';' + ' ' * (Get-Random @(0..2))
    }

    # Add the obfuscated token back to $ScriptString.
    $ScriptString = $PortionToPrependToScriptString + $ScriptString.SubString(0, $Token.Start + $Script:TypeTokenScriptStringGrowth) + ' ' * (Get-Random @(1..2)) + $RandomVarGet + $ScriptString.SubString($Token.Start + $Token.Length + $Script:TypeTokenScriptStringGrowth)

    # Keep track how much $ScriptString grows for each Type token obfuscation iteration.
    $Script:TypeTokenScriptStringGrowth = $Script:TypeTokenScriptStringGrowth + $PortionToPrependToScriptString.Length

    Return $ScriptString
}
