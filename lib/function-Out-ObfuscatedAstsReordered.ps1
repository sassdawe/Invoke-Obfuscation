
function Out-ObfuscatedAstsReordered {
    <#

    .SYNOPSIS

    Obfuscates and re-orders ChildrenAsts inside of a ParentAst PipelineAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedAstsReordered obfuscates an Ast using AbstractSyntaxTree-based obfuscation rules, and re-orders the obfuscated
    ChildrenAsts of the ParentAst inside of the ParentAst.

    .PARAMETER ParentAst

    Specifies the ParentAst, of which it's children should be re-ordered.

    .PARAMETER ChildrenAsts

    Specifies the ChildrenAsts within the ParentAst that can be re-ordered.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root Ast should be obfuscated, obfuscation should not be applied recursively to the ChildrenAsts.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedAstsReordered -ParentAst $ParentAst -ChildrenAsts (Get-ChildrenAst -Ast $ParentAst)

    .NOTES

    Out-ObfuscatedAstsReordered is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast', 'AbstractSyntaxTree')]
        [System.Management.Automation.Language.Ast] $ParentAst,

        [Parameter(Position = 1, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.Ast[]] $ChildrenAsts,
        
        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Write-Verbose "[Out-ObfuscatedAstsReordered]"
    If ($DisableNestedObfuscation) {
        $ChildrenObfuscatedExtents = ($ChildrenAsts | % { $_.Extent.Text }) -as [array]
    }
    Else {
        $ChildrenObfuscatedExtents = ($ChildrenAsts | Out-ObfuscatedAst -AstTypesToObfuscate $AstTypesToObfuscate) -as [array]
    }

    $ObfuscatedString = $ParentAst.Extent.Text
    $PrevChildrenLength = 0
    $PrevObfuscatedChildrenLength = 0
    If ($ChildrenObfuscatedExtents.Count -gt 1) {
        $ChildrenObfuscatedExtents = $ChildrenObfuscatedExtents | Get-Random -Count $ChildrenObfuscatedExtents.Count
        For ([Int] $i = 0; $i -lt $ChildrenAsts.Count; $i++) {
            $LengthDifference = $ObfuscatedString.Length - $ParentAst.Extent.Text.Length
            $BeginLength = ($ChildrenAsts[$i].Extent.StartOffset - $ParentAst.Extent.StartOffset) + $LengthDifference
            $EndStartIndex = ($ChildrenAsts[$i].Extent.StartOffset - $ParentAst.Extent.StartOffset) + $ChildrenAsts[$i].Extent.Text.Length
            
            $ObfuscatedString = [String] $ObfuscatedString.SubString(0, $BeginLength)
            $ObfuscatedString += [String] $ChildrenObfuscatedExtents[$i]
            $ObfuscatedString += [String] $ParentAst.Extent.Text.Substring($EndStartIndex)
        }
    }

    $ObfuscatedString
}
