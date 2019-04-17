
function Out-ObfuscatedBinaryExpressionAst {
    <#

    .SYNOPSIS

    Obfuscates a BinaryExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Test-ExpressionAstIsNumeric, Out-ObfuscatedAst, Out-ParenthesizedString, Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedBinaryExpressionAst obfuscates a BinaryExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the BinaryExpressionAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root BinaryExpressionAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedBinaryExpressionAst -Ast $BinaryExpressionAst

    .NOTES

    Out-ObfuscatedBinaryExpressionAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.BinaryExpressionAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedBinaryExpressionAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        Else {
            $OperatorText = [System.Management.Automation.Language.TokenTraits]::Text($AbstractSyntaxTree.Operator)

            $ObfuscatedString = $AbstractSyntaxTree.Extent.Text

            # Numeric operation obfuscation
            If((Test-ExpressionAstIsNumeric -Ast $AbstractSyntaxTree.Left) -AND (Test-ExpressionAstIsNumeric -Ast $AbstractSyntaxTree.Right)) {
                $Whitespace = ""
                If ((Get-Random @(0,1)) -eq 0) { $Whitespace = " " }
                # Operators that can be reordered
                $LeftString = $AbstractSyntaxTree.Left.Extent.Text
                $RightString = $AbstractSyntaxTree.Right.Extent.Text
                If (-not $DisableNestedObfuscation) {
                    $LeftString = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate
                    $RightString = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate
                }
                If ($OperatorText -in @("+", "*")) {
                    $ObfuscatedString = $RightString + $Whitespace + $OperatorText + $Whitespace + $LeftString
                }
                ElseIf ($OperatorText -eq "-") {
                    $ObfuscatedString = Out-ParenthesizedString ("-" + $Whitespace + (Out-ParenthesizedString ((Out-ParenthesizedString $RightString) + $Whitespace + $OperatorText + $Whitespace + (Out-ParenthesizedString $LeftString))))
                }
            }
            ElseIf (-not $DisableNestedObfuscation) { $ObfuscatedString = Out-ObfuscatedChildrenAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }

            $ObfuscatedString
        }
    }
}