

Function Out-RandomCase {
    <#
        .SYNOPSIS

        HELPER FUNCTION :: Obfuscates any string or char[] by randomizing its case.

        Invoke-Obfuscation Function: Out-RandomCase
        Author: David Sass (@sassdawe)
        License: Apache License, Version 2.0
        Required Dependencies: None
        Optional Dependencies: None
        
        .DESCRIPTION

        Out-RandomCase obfuscates given input as a helper function to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

        .PARAMETER InputValStr

        Specifies the string to obfuscate.

        .PARAMETER InputVal

        Specifies the char[] to obfuscate.

        .EXAMPLE

        C:\PS> Out-RandomCase "String to have case randomized"

        STrINg to haVe caSe RAnDoMIzeD

        C:\PS> Out-RandomCase ([char[]]"String to have case randomized")

        StrING TO HavE CASE randOmIzeD

        .NOTES

        This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
        C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 'Command' 3
        This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

        .LINK

        http://www.danielbohannon.com
    #>

    [CmdletBinding( DefaultParameterSetName = 'InputVal')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'InputValStr')]
        [ValidateNotNullOrEmpty()]
        [String]
        $InputValStr,

        [Parameter(Position = 0, ParameterSetName = 'InputVal')]
        [ValidateNotNullOrEmpty()]
        [Char[]]
        $InputVal
    )
    
    If ($PSBoundParameters['InputValStr']) {
        # Convert string to char array for easier manipulation.
        $InputVal = [Char[]]$InputValStr
    }

    # Randomly convert each character to upper- or lower-case.
    $OutputVal = ($InputVal | ForEach-Object { If ((Get-Random -Minimum 0 -Maximum 2) -eq 0) { ([String]$_).ToUpper() } Else { ([String]$_).ToLower() } }) -Join ''

    Return $OutputVal
}
