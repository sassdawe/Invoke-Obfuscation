
function Out-ParenthesizedString {
    <#

    .SYNOPSIS

    Outputs a string that is guaranteed to be surrounded in a single set of parentheses.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: none
    Optional Dependencies: none

    .DESCRIPTION

    Out-ParenthesizedString outputs a string that is guaranteed to be surrounded in a single set of parentheses, which is
    often needed when re-ordering Asts within a script.

    .PARAMETER ScriptString

    Specifies the string that should be parenthesized.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ParenthesizedString -ScriptString $ScriptString

    .NOTES

    Out-ParenthesizedString is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param(
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [String] $ScriptString
    )
    Process {
        Write-Verbose "[Out-ParenthesizedString]"
        $TrimmedString = $ScriptString.Trim()
        If ($TrimmedString.StartsWith("(") -and $TrimmedString.EndsWith(")")) {
            $StackDepth = 1
            $SurroundingMatch = $True
            For([Int]$i = 1; $i -lt $TrimmedString.Length - 1; $i++) {
                $Char = $TrimmedString[$i]
                If ($Char -eq ")") {
                    If ($StackDepth -eq 1) { $SurroundingMatch = $False; break; }
                    Else { $StackDepth -= 1 }
                }
                ElseIf ($Char -eq "(") { $StackDepth += 1 }
            }
            If ($SurroundingMatch) { $ScriptString }
            Else { "(" + $ScriptString + ")" }
        } Else {
            "(" + $ScriptString + ")"
        }
    }
}
