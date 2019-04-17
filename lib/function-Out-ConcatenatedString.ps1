

Function Out-ConcatenatedString {
    <#
.SYNOPSIS

HELPER FUNCTION :: Obfuscates any string by randomly concatenating it and encapsulating the result with input single- or double-quotes.

Invoke-Obfuscation Function: Out-ConcatenatedString
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ConcatenatedString obfuscates given input as a helper function to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER InputVal

Specifies the string to obfuscate.

.PARAMETER Quote

Specifies the single- or double-quote used to encapsulate the concatenated string.

.EXAMPLE

C:\PS> Out-ConcatenatedString "String to be concatenated" '"'

"String "+"to be "+"co"+"n"+"c"+"aten"+"at"+"ed

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
        $InputVal,
    
        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [Char]
        $Quote
    )

    # Strip leading and trailing single- or double-quotes if there are no more quotes of the same kind in $InputVal.
    # E.g. 'stringtoconcat' will have the leading and trailing quotes removed and will use $Quote.
    # But a string "'G'+'" passed to this function as 'G'+' will have all quotes remain as part of the $InputVal string.
    If ($InputVal.Contains("'")) { $InputVal = $InputVal.Replace("'", "`'") }
    If ($InputVal.Contains('"')) { $InputVal = $InputVal.Replace('"', '`"') }
    
    # Do nothing if string is of length 2 or less
    $ObfuscatedToken = ''
    If ($InputVal.Length -le 2) {
        $ObfuscatedToken = $Quote + $InputVal + $Quote
        Return $ObfuscatedToken
    }

    # Choose a random percentage of characters to have concatenated in current token.
    # If the current token is greater than 1000 characters (as in SecureString or Base64 strings) then set $ConcatPercent much lower
    If ($InputVal.Length -gt 25000) {
        $ConcatPercent = Get-Random -Minimum 0.05 -Maximum 0.10
    }
    ElseIf ($InputVal.Length -gt 1000) {
        $ConcatPercent = Get-Random -Minimum 2 -Maximum 4
    }
    Else {
        $ConcatPercent = Get-Random -Minimum 15 -Maximum 30
    }
    
    # Convert $ConcatPercent to the exact number of characters to concatenate in the current token.
    $ConcatCount = [Int]($InputVal.Length * ($ConcatPercent / 100))

    # Guarantee that at least one concatenation will occur.
    If ($ConcatCount -eq 0) {
        $ConcatCount = 1
    }

    # Select random indexes on which to concatenate.
    $CharIndexesToConcat = (Get-Random -InputObject (1..($InputVal.Length - 1)) -Count $ConcatCount) | Sort-Object
  
    # Perform inline concatenation.
    $LastIndex = 0

    ForEach ($IndexToObfuscate in $CharIndexesToConcat) {
        # Extract substring to concatenate with $ObfuscatedToken.
        $SubString = $InputVal.SubString($LastIndex, $IndexToObfuscate - $LastIndex)
       
        # Concatenate with quotes and addition operator.
        $ObfuscatedToken += $SubString + $Quote + "+" + $Quote

        $LastIndex = $IndexToObfuscate
    }

    # Add final substring.
    $ObfuscatedToken += $InputVal.SubString($LastIndex)
    $ObfuscatedToken += $FinalSubString

    # Add final quotes if necessary.
    If (!($ObfuscatedToken.StartsWith($Quote) -AND $ObfuscatedToken.EndsWith($Quote))) {
        $ObfuscatedToken = $Quote + $ObfuscatedToken + $Quote
    }
   
    # Remove any existing leading or trailing empty string concatenation.
    If ($ObfuscatedToken.StartsWith("''+")) {
        $ObfuscatedToken = $ObfuscatedToken.SubString(3)
    }
    If ($ObfuscatedToken.EndsWith("+''")) {
        $ObfuscatedToken = $ObfuscatedToken.SubString(0, $ObfuscatedToken.Length - 3)
    }
    
    Return $ObfuscatedToken
}
