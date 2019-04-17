
function Out-ObfuscatedAssignmentStatementAst {
    <#

    .SYNOPSIS

    Obfuscates a AssignmentStatementAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAst, Out-ParenthesizedString, Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedAssignmentStatementAst obfuscates a AssignmentStatementAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the AssignmentStatementAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root AssignmentStatementAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedAssignmentStatementAst -Ast $AssignmentStatementAst

    .NOTES

    Out-ObfuscatedAssignmentStatementAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.AssignmentStatementAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedAssignmentStatementAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        Else {
            $OperatorText = [System.Management.Automation.Language.TokenTraits]::Text($AbstractSyntaxTree.Operator)
            If ($AbstractSyntaxTree.Left.GetType().Name -eq "VariableExpressionAst" -AND $AbstractSyntaxTree.Left.VariablePath.IsVariable) {
                If ($OperatorText -eq "=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString $RightExtent)
                }
                ElseIf ($OperatorText -eq "+=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " + " + (Out-ParenthesizedString $RightExtent)))
                }
                ElseIf ($OperatorText -eq "-=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " - " + (Out-ParenthesizedString $RightExtent)))
                }
                ElseIf ($OperatorText -eq "*=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " * " + (Out-ParenthesizedString $RightExtent)))
                }
                ElseIf ($OperatorText -eq "/=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " / " + (Out-ParenthesizedString $RightExtent)))
                }
                ElseIf ($OperatorText -eq "%=") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " % " + (Out-ParenthesizedString $RightExtent)))
                }
                ElseIf ($OperatorText -eq "++") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " + 1"))
                }
                ElseIf ($OperatorText -eq "--") {
                    $RightExtent = $AbstractSyntaxTree.Right.Extent.Text
                    If (-not $DisableNestedObfuscation) { $RightExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Right -AstTypesToObfuscate $AstTypesToObfuscate }
                    $LeftExtent = $AbstractSyntaxTree.Left.Extent.Text
                    If (-not $DisableNestedObfuscation) { $LeftExtent = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.Left -AstTypesToObfuscate $AstTypesToObfuscate }
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($LeftExtent + " - 1"))
                }
                ElseIf (-not $DisableNestedObfuscation) { Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
                Else { $AbstractSyntaxTree.Extent.Text }
            }
            ElseIf ($AbstractSyntaxTree.Left.GetType().Name -eq "ConvertExpressionAst" -AND $AbstractSyntaxTree.Left.Child.GetType().Name -eq "VariableExpressionAst" -AND
                    $AbstractSyntaxTree.Left.VariablePath.IsVariable -AND $AbstractSyntaxTree.Left.Attribute.GetType().Name -eq 'TypeConstraintName') {
                If ($OperatorText -eq "=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Right.Extent.Text))
                }
                ElseIf ($OperatorText -eq "+=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " + " + (Out-ParenthesizedString $AbstractSyntaxTree.Right.Extent.Text)))
                }
                ElseIf ($OperatorText -eq "-=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " - " + (Out-ParenthesizedString $AbstractSyntaxTree.Right.Extent.Text)))
                }
                ElseIf ($OperatorText -eq "*=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " * " + (Out-ParenthesizedString $AbstractSyntaxTree.Right.Extent.Text)))
                }
                ElseIf ($OperatorText -eq "/=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " / " + (Out-ParenthesizedString $AbstractSyntaxTree.Right.Extent.Text)))
                }
                ElseIf ($OperatorText -eq "%=") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " % " + (Out-ParenthesizedString $AbstractSyntaxTree.Right.Extent.Text)))
                }
                ElseIf ($OperatorText -eq "++") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " + 1"))
                }
                ElseIf ($OperatorText -eq "--") {
                    "Set-Variable -Name " + $AbstractSyntaxTree.Left.Child.VariablePath.UserPath + " -Value " + (Out-ParenthesizedString ($AbstractSyntaxTree.Left.Attribute.Extent.Text + " " + $AbstractSyntaxTree.Left.Extent.Text + " - 1"))
                }
                ElseIf (-not $DisableNestedObfuscation) { Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
                Else { $AbstractSyntaxTree.Extent.Text }
            }
            ElseIf (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
    }
}
