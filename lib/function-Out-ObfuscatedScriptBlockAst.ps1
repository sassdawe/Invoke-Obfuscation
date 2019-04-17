function Out-ObfuscatedScriptBlockAst {
    <#

    .SYNOPSIS

    Obfuscates a ScriptBlockAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedChildrenAst, Out-ObfuscatedAstsReordered, Out-ObfuscatedAst, Get-AstChildren
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedScriptBlockAst obfuscates a ScriptBlockAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the ScriptBlockAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root ScriptBlockAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedScriptBlockAst -Ast $ScriptBlockAst

    .NOTES

    Out-ObfuscatedScriptBlockAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.ScriptBlockAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedScriptBlockAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        ElseIf (-not $DisableNestedObfuscation) {
            $Children = (Get-AstChildren -Ast $AbstractSyntaxTree | ? { $_.Extent.StartScriptPosition.GetType().Name -ne 'EmptyScriptPosition' }) -as [array]
            $RealChildren = $Children
            $FunctionDefinitionBlocks = @()
            If ($AbstractSyntaxTree.BeginBlock) { $FunctionDefinitionBlocks += $AbstractSyntaxTree.BeginBlock }
            If ($AbstractSyntaxTree.ProcessBlock) { $FunctionDefinitionBlocks += $AbstractSyntaxTree.ProcessBlock }
            If ($AbstractSyntaxTree.EndBlock) { $FunctionDefinitionBlocks += $AbstractSyntaxTree.EndBlock }

            If ($Children.Count -eq 2 -AND $Children[0].GetType().Name -eq 'ParamBlockAst' -AND $Children[1].GetType().Name -eq 'NamedBlockAst' -AND $Children[1] -eq $AbstractSyntaxTree.EndBlock) {
                [System.Management.Automation.Language.Ast[]] $RealChildren = ($Children[0]) -as [array]
                $RealChildren += (Get-AstChildren -Ast $Children[1] | ? { $_.Extent.StartScriptPosition.GetType().Name -ne 'EmptyScriptPosition' } | Sort-Object { $_.Extent.StartOffset }) -as [array]
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -ChildrenAsts $RealChildren -AstTypesToObfuscate $AstTypesToObfuscate
            }
            ElseIf ($FunctionDefinitionBlocks.Count -gt 1) {
                $Children = $Children | Sort-Object { $_.Extent.StartOffset }
                $Reordered  = Out-ObfuscatedAstsReordered -ParentAst $AbstractSyntaxTree -ChildrenAsts ($FunctionDefinitionBlocks | Sort-Object { $_.Extent.StartOffset }) -AstTypesToObfuscate $AstTypesToObfuscate

                If ($AbstractSyntaxTree.ParamBlock) {
                    $ObfuscatedParamBlock = Out-ObfuscatedAst -AbstractSyntaxTree $AbstractSyntaxTree.ParamBlock -AstTypesToObfuscate $AstTypesToObfuscate
                    $FinalObfuscated = [String] $AbstractSyntaxTree.Extent.Text.Substring(0, $AbstractSyntaxTree.ParamBlock.Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset)
                    $FinalObfuscated += [String] $ObfuscatedParamBlock
                    $FinalObfuscated += [String] $Reordered.Substring($AbstractSyntaxTree.ParamBlock.Extent.StartOffset - $AbstractSyntaxTree.Extent.StartOffset + $AbstractSyntaxTree.ParamBlock.Extent.Text.Length)
                } Else { $FinalObfuscated = $Reordered }

                $FinalObfuscated
            }
            Else {
                $Children = $Children | Sort-Object { $_.Extent.StartOffset }
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -ChildrenAsts $Children -AstTypesToObfuscate $AstTypesToObfuscate
            }
        }
        Else { $AbstractSyntaxTree.Extent.Text }
    }
}