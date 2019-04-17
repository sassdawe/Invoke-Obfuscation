
function Out-ObfuscatedChildrenAst {
    <#

    .SYNOPSIS

    Recursively obfuscates the ChildrenAsts of an Ast.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedChildrenAst recursively obfuscates the ChildrenAsts of an Ast using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the parent Ast, whose children will be recursively obfuscated.

    .PARAMETER ChildrenAsts

    Optionally specifies the ChildrenAsts within the ParentAst that should be recursively obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root Ast should be obfuscated, obfuscation should not be applied recursively to the ChildrenAsts.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedChildrenAst -Ast $Ast -ChildrenAsts (Get-ChildrenAst -Ast $ParentAst)

    .NOTES

    Out-ObfuscatedChildrenAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.Ast] $AbstractSyntaxTree,

        [Parameter(Position = 1)]
        [System.Management.Automation.Language.Ast[]] $ChildrenAsts = @(),

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),
        
        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedChildrenAst]"
        If ($ChildrenAsts.Count -eq 0) {
            $ChildrenAsts = (Get-AstChildren -AbstractSyntaxTree $AbstractSyntaxTree | ? { $_.Extent.StartScriptPosition.GetType().Name -ne 'EmptyScriptPosition' } | Sort-Object { $_.Extent.StartOffset }) -as [array]
        }
        If ($ChildrenAsts.Count -gt 0) {
            $ChildrenObfuscatedExtents = ($ChildrenAsts | Out-ObfuscatedAst -AstTypesToObfuscate $AstTypesToObfuscate) -as [array]
        }

        $ObfuscatedExtent = $AbstractSyntaxTree.Extent.Text
        If ($ChildrenObfuscatedExtents.Count -gt 0 -AND $ChildrenAsts.Count -gt 0 -AND $ChildrenObfuscatedExtents.Count -eq $ChildrenAsts.Count) {
            For ([Int] $i = 0; $i -lt $ChildrenAsts.Length; $i++) {
                $LengthDifference = $ObfuscatedExtent.Length - $AbstractSyntaxTree.Extent.Text.Length
                $EndStartIndex = ($ChildrenAsts[$i].Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset) + $ChildrenAsts[$i].Extent.Text.Length
                $StartLength = ($ChildrenAsts[$i].Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset) + $LengthDifference
                $ObfuscatedExtent = [String] $ObfuscatedExtent.Substring(0, $StartLength)
                If (-not $ChildrenObfuscatedExtents[$i]) {
                    $ObfuscatedExtent += [String] $ChildrenAsts[$i].Extent.Text
                }
                Else {
                    $ObfuscatedExtent += [String] $ChildrenObfuscatedExtents[$i]
                }
                $ObfuscatedExtent += [String] $AbstractSyntaxTree.Extent.Text.Substring($EndStartIndex)
            }
        }
        $ObfuscatedExtent
    }
}
