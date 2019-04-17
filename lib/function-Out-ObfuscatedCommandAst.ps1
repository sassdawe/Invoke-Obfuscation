
function Out-ObfuscatedCommandAst {
    <#

    .SYNOPSIS

    Obfuscates a CommandAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Get-AstChildren, Out-ObfuscatedAst, Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedCommandAst obfuscates a CommandAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the CommandAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root CommandAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedCommandAst -Ast $CommandAst

    .NOTES

    Out-ObfuscatedCommandAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.CommandAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedCommandAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        ElseIf (-not $DisableNestedObfuscation) {
            $Children = Get-AstChildren -AbstractSyntaxTree $AbstractSyntaxTree
            If ($Children.Count -ge 5) {
                $ReorderableIndices = @()
                $ObfuscatedReorderableExtents = @()
                $LastChild = $Children[1]
                For ([Int] $i = 2; $i -lt $Children.Count; $i++) {
                    $CurrentChild = $Children[$i]
                    If ($LastChild.GetType().Name -eq 'CommandParameterAst' -AND $CurrentChild.GetType().Name -ne 'CommandParameterAst') {
                        $FirstIndex = $LastChild.Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset
                        $PairLength = $CurrentChild.Extent.StartOffset + $CurrentChild.Extent.Text.Length - $LastChild.Extent.StartOffset
                        $SecondIndex = $CurrentChild.Extent.StartOffset + $CurrentChild.Extent.Text.Length - $AbstractSyntaxTree.Extent.StartOffset
                        $PairExtent = $AbstractSyntaxTree.Extent.Text.Substring($FirstIndex, $PairLength)
                        $ObfuscatedLastChild = Out-ObfuscatedAst -AbstractSyntaxTree $LastChild -AstTypesToObfuscate $AstTypesToObfuscate
                        $ObfuscatedCurrentChild = Out-ObfuscatedAst -AbstractSyntaxTree $CurrentChild -AstTypesToObfuscate $AstTypesToObfuscate
                        $ObfuscatedPairExtent = $ObfuscatedLastChild + " " + $ObfuscatedCurrentChild
                        $ReorderableIndices += [Tuple]::Create($FirstIndex, $SecondIndex)
                        $ObfuscatedReorderableExtents += [String] $ObfuscatedPairExtent
                    }
                    ElseIf ($LastChild.GetType().Name -eq 'CommandParameterAst' -AND $CurrentChild.GetType().Name -eq 'CommandParameterAst') {
                        $ObfuscatedLastChild = Out-ObfuscatedAst -AbstractSyntaxTree $LastChild -AstTypesToObfuscate $AstTypesToObfuscate
                        $FirstIndex = $LastChild.Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset
                        $SecondIndex = $LastChild.Extent.StartOffset + $LastChild.Extent.Text.Length - $AbstractSyntaxTree.Extent.StartOffset
                        $ReorderableIndices += [Tuple]::Create($FirstIndex, $SecondIndex)
                        $ObfuscatedReorderableExtents += [String] $ObfuscatedLastChild
                    }
                    ElseIf ($CurrentChild.GetType().Name -eq 'CommandParameterAst' -AND $i -eq ($Children.Count - 1)) {
                        $ObfuscatedCurrentChild = Out-ObfuscatedAst -AbstractSyntaxTree $CurrentChild -AstTypesToObfuscate $AstTypesToObfuscate
                        $FirstIndex = $CurrentChild.Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset
                        $SecondIndex = $CurrentChild.Extent.StartOffset + $CurrentChild.Extent.Text.Length - $AbstractSyntaxTree.Extent.StartOffset
                        $ReorderableIndices += [Tuple]::Create($FirstIndex, $SecondIndex)
                        $ObfuscatedReorderableExtents += [String] $ObfuscatedCurrentChild
                    }
                    $LastChild = $CurrentChild
                }
                If ($ObfuscatedReorderableExtents.Count -gt 1) {
                    $ObfuscatedReorderableExtents = $ObfuscatedReorderableExtents | Get-Random -Count $ObfuscatedReorderableExtents.Count
                    $ObfuscatedExtent = $AbstractSyntaxTree.Extent.Text
                    For ([Int] $i = 0; $i -lt $ObfuscatedReorderableExtents.Count; $i++) {
                        $LengthDifference = $ObfuscatedExtent.Length - $AbstractSyntaxTree.Extent.Text.Length
                        $ObfuscatedExtent = $ObfuscatedExtent.Substring(0, $ReorderableIndices[$i].Item1 + $LengthDifference)
                        $ObfuscatedExtent += [String] $ObfuscatedReorderableExtents[$i]
                        $ObfuscatedExtent += [String] $AbstractSyntaxTree.Extent.Text.Substring($ReorderableIndices[$i].Item2)
                    }
                    $ObfuscatedExtent
                }
                Else { Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            Else { Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
        }
        Else { $AbstractSyntaxTree.Extent.Text }
    }
}
