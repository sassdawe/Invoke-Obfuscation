function Out-ObfuscatedAttributeAst {
    <#

    .SYNOPSIS

    Obfuscates a AttributeAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAstsReordered
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedAttributeAst obfuscates a AttributeAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the AttributeAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root AttributeAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedAttributeAst -Ast $AttributeAst

    .NOTES

    Out-ObfuscatedAttributeAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.AttributeAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    
    Process {
        Write-Verbose "[Out-ObfuscatedAttributeAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        Else {
            $ObfuscatedString = $AbstractSyntaxTree.Extent.Text
            If ($AbstractSyntaxTree.NamedArguments.Count -gt 0) {
                $NamedArguments = $AbstractSyntaxTree.NamedArguments
                If ($DisableNestedObfuscation) {
                    $ObfuscatedString = Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts $NamedArguments -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation
                }
                Else {
                    $ObfuscatedString = Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts $NamedArguments -AstTypesToObfuscate $AstTypesToObfuscate
                }
            }
            ElseIf ($AbstractSyntaxTree.PositionalArguments.Count -gt 0) {
                If ($AbstractSyntaxTree.TypeName.FullName -in @('Alias', 'ValidateSet')) {
                    $PositionalArguments = $AbstractSyntaxTree.PositionalArguments
                    If ($DisableNestedObfuscation) {
                        $ObfuscatedString = Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts $PositionalArguments -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation
                    }
                    Else {
                        $ObfuscatedString = Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts $PositionalArguments -AstTypesToObfuscate $AstTypesToObfuscate
                    }
                }
            }

            $ObfuscatedString
        }
    }
}