
function Get-AstChildren {
    <#

    .SYNOPSIS

    Gets the children Asts of a given AbstractSyntaxTree.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: none
    Optional Dependencies: none

    .DESCRIPTION

    Get-AstChildren gets the children Asts of a given AbstractSyntaxTree by searching the parent Ast's property
    values for Ast types.

    .PARAMETER AbstractSyntaxTree

    Specifies the parent Ast to get the children Asts from.

    .OUTPUTS

    [System.Management.Automation.Ast[]]

    .EXAMPLE

    Get-AstChildren -Ast $Ast

    .NOTES

    Get-AstChildren is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.Ast] $AbstractSyntaxTree
    )
    Process {
        Write-Verbose "[Get-AstChildren]"
        ForEach ($Property in $AbstractSyntaxTree.PSObject.Properties) {
            If ($Property.Name -eq 'Parent') { continue }

            $PropertyValue = $Property.Value
            If ($PropertyValue -ne $null -AND $PropertyValue -is [System.Management.Automation.Language.Ast]) {
                $PropertyValue
            }
            Else {
                $Collection = $PropertyValue -as [System.Management.Automation.Language.Ast[]]
                If ($Collection -ne $null) {
                    $Collection
                }
            }
        }
    }
}
