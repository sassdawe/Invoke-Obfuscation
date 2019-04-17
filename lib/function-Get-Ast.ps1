
function Get-Ast {
    <#

    .SYNOPSIS

    Gets the root Ast for a given script.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: none
    Optional Dependencies: none

    .DESCRIPTION

    Get-Ast gets the AbstractSyntaxTree that represents a given script.

    .PARAMETER ScriptString

    Specifies the String containing a script to get the AbstractSyntaxTree of.

    .PARAMETER ScriptBlock

    Specifies the ScriptBlock containing a script to get the AbstractSyntaxTree of.

    .PARAMETER ScriptPath

    Specifies the Path to a file containing the script to get the AbstractSyntaxTree of.

    .PARAMETER ScriptUri

    Specifies the URI of the script to get the AbstractSyntaxTree of.

    .OUTPUTS

    System.Management.Automation.Language.Ast

    .EXAMPLE

    Get-Ast "Write-Host example"

    .EXAMPLE

    Get-Ast {Write-Host example}

    .EXAMPLE

    Get-Ast -ScriptPath Write-Example.ps1

    .EXAMPLE

    Get-ChildItem /path/to/scripts -Recurse -Include *.ps1 | Get-Ast

    .EXAMPLE

    @('Write-Host example1', 'Write-Host example2', 'Write-Host example3') | Get-Ast

    .EXAMPLE

    @({ Write-Host example1 }, { Write-Host example2 }, { Write-Host example3 }) | Get-Ast

    .NOTES

    Get-Ast is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    [CmdletBinding(DefaultParameterSetName = "ByString")] Param(
        [Parameter(ParameterSetName = "ByString", Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $ScriptString,

        [Parameter(ParameterSetName = "ByScriptBlock", Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock] $ScriptBlock,

        [Parameter(ParameterSetName = "ByPath", Position = 0, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateScript({Test-Path $_ -PathType leaf})]
        [Alias('PSPath')]
        [String] $ScriptPath,

        [Parameter(ParameterSetName = "ByUri", Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateScript({$_.Scheme -match 'http|https'})]
        [Uri] $ScriptUri
    )
    Process {
        If ($ScriptBlock) { $ScriptString = $ScriptBlock -as [String] }
        ElseIf ($ScriptPath) { $ScriptString = Get-Content -Path $ScriptPath -Raw }
        ElseIf ($ScriptUri) { $ScriptString = [Net.Webclient]::new().DownloadString($ScriptUri) }

        # Parse script and return root Ast
        [Management.Automation.Language.ParseError[]] $ParseErrors = @()
        $Ast = [Management.Automation.Language.Parser]::ParseInput($ScriptString, $null, [ref] $null, [ref] $ParseErrors)
        $Ast
    }
}