function Out-ObfuscatedParamBlockAst {
    <#

    .SYNOPSIS

    Obfuscates a ParamBlockAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAstsReordered, Get-AstChildren
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedParamBlockAst obfuscates a ParamBlockAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the ParamBlockAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root ParamBlockAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedParamBlockAst -Ast $ParamBlockAst

    .NOTES

    Out-ObfuscatedParamBlockAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.ParamBlockAst] $AbstractSyntaxTree,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedParamBlockAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        ElseIf (-not $DisableNestedObfuscation) {
            $Children = (Get-AstChildren -AbstractSyntaxTree $AbstractSyntaxTree | ? { $_.Extent.StartScriptPosition.GetType().Name -ne 'EmptyScriptPosition' } | Sort-Object { $_.Extent.StartOffset }) -as [array]
            # For some reason 'Attribute' children do not exist within the ParamBlockAst Extent. Very frustrating.
            $ChildrenNotAttributes = $Children | ? { -not ($_ -in $AbstractSyntaxTree.Attributes) }
            $ChildrenAttributes = $Children | ? { $_ -in $AbstractSyntaxTree.Attributes }
            
            Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts $ChildrenNotAttributes -AstTypesToObfuscate $AstTypesToObfuscate
        }
        Else { $AbstractSyntaxTree.Extent.Text }
    }
}