function Out-ObfuscatedExpressionAst {
    <#

    .SYNOPSIS

    Obfuscates a ExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedArrayExpressionAst, Out-ObfuscatedArrayLiteralAst, Out-ObfuscatedAttributedExpressionAst, Out-ObfuscatedBinaryExpressionAst, Out-ObfuscatedConstantExpressionAst, Out-ObfuscatedErrorExpressionAst, Out-ObfuscatedExpandedStringExpressionAst, Out-ObfuscatedHashtableAst, Out-ObfuscatedIndexExpressionAst, Out-ObfuscatedMemberExpressionAst, Out-ObfuscatedParenExpressionAst, Out-ObfuscatedScriptBlockExpressionAst, Out-ObfuscatedSubExpressionAst, Out-ObfuscatedTypeExpressionAst, Out-ObfuscatedUnaryExpressionAst, Out-ObfuscatedUsingExpressionAst, Out-ObfuscatedVariableExpressionAst, Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedExpressionAst obfuscates a ExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the ExpressionAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root ExpressionAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedExpressionAst -Ast $ExpressionAst

    .NOTES

    Out-ObfuscatedExpressionAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.ExpressionAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedExpressionAst]"
        # Abstract Ast Type, call inherited ast obfuscation type
        If ($AbstractSyntaxTree.GetType().Name -eq 'ArrayExpressionAst') {
            Out-ObfuscatedArrayExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ArrayLiteralAst') {
            Out-ObfuscatedArrayLiteralAst -AbstractSyntaxTree $AbstractSyntaxTree
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'AttributedExpressionAst') {
            Out-ObfuscatedAttributedExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'BinaryExpressionAst') {
            Out-ObfuscatedBinaryExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ConstantExpressionAst') {
            Out-ObfuscatedConstantExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ErrorExpressionAst') {
            Out-ObfuscatedErrorExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ExpandedStringExpressionAst') {
            Out-ObfuscatedExpandedStringExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'HashtableAst') {
            Out-ObfuscatedHashtableAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'IndexExpressionAst') {
            Out-ObfuscatedIndexExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'MemberExpressionAst') {
            Out-ObfuscatedMemberExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ParenExpressionAst') {
            Out-ObfuscatedParenExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ScriptBlockExpressionAst') {
            Out-ObfuscatedScriptBlockExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'SubExpressionAst') {
            Out-ObfuscatedSubExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'TypeExpressionAst') {
            Out-ObfuscatedTypeExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'UnaryExpressionAst') {
            Out-ObfuscatedUnaryExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'UsingExpressionAst') {
            Out-ObfuscatedUsingExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'VariableExpressionAst') {
            Out-ObfuscatedVariableExpressionAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        ElseIf (-not $DisableNestedObfuscation) {
            Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        Else {
            $AbstractSyntaxTree.Extent.Text
        }
    }
}