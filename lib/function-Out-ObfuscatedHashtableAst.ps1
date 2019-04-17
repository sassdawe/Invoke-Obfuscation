

function Out-ObfuscatedHashtableAst {
    <#

    .SYNOPSIS

    Obfuscates a HashtableAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedHashtableAst obfuscates a HashtableAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the HashtableAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root HashtableAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedHashtableAst -Ast $HashtableAst

    .NOTES

    Out-ObfuscatedHashtableAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.HashtableAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedHashtableAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        Else {
            $ObfuscatedKeyValuePairs = @()
            $ChildrenAsts = $AbstractSyntaxTree.KeyValuePairs | %  { $_.Item1; $_.Item2 }
            If ($DisableNestedObfuscation) {
                $ObfuscatedKeyValuePairs = $AbstractSyntaxTree.KeyValuePairs
            }
            Else {
                ForEach ($KeyValuePair in $AbstractSyntaxTree.KeyValuePairs) {
                    $ObfuscatedItem1 = Out-ObfuscatedAst $KeyValuePair.Item1 -AstTypesToObfuscate $AstTypesToObfuscate
                    $ObfuscatedItem2 = Out-ObfuscatedAst $KeyValuePair.Item2 -AstTypesToObfuscate $AstTypesToObfuscate
                    $ObfuscatedKeyValuePairs += [System.Tuple]::Create($ObfuscatedItem1, $ObfuscatedItem2)
                }
            }

            $ObfuscatedString = $AbstractSyntaxTree.Extent.Text
            $ObfuscatedString = "@{"
            If ($ObfuscatedKeyValuePairs.Count -ge 1) {
                $ObfuscatedKeyValuePairs = $ObfuscatedKeyValuePairs | Get-Random -Count $ObfuscatedKeyValuePairs.Count
                ForEach ($ObfuscatedKeyValuePair in $ObfuscatedKeyValuePairs) {
                    $ObfuscatedString += $ObfuscatedKeyValuePair.Item1 + "=" + $ObfuscatedKeyValuePair.Item2 + ";"
                }
            }
            $ObfuscatedString += "}"

            $ObfuscatedString
        }
    }
}