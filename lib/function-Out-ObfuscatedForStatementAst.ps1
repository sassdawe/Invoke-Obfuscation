function Out-ObfuscatedForStatementAst {
    <#

    .SYNOPSIS

    Obfuscates a ForStatementAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedForStatementAst obfuscates a ForStatementAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the ForStatementAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root ForStatementAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedForStatementAst -Ast $ForStatementAst

    .NOTES

    Out-ObfuscatedForStatementAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.ForStatementAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedForStatementAst]"
        If (-not $DisableNestedObfuscation) {
            Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
        }
        Else { $AbstractSyntaxTree.Extent.Text }
    }
}