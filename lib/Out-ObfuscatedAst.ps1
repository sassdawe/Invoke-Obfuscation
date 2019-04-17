function Out-ObfuscatedAst {
    <#

    .SYNOPSIS

    Obfuscates PowerShell scripts using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: none
    Optional Dependencies: Get-Ast

    .DESCRIPTION

    Out-ObfuscatedAst obfuscates PowerShell scripts using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER ScriptString

    Specifies the string containing the script to be obfuscated.

    .PARAMETER ScriptBlock

    Specifies the ScriptBlock containing the script to be obfuscated.

    .PARAMETER ScriptPath

    Specifies the Path containing the script to be obfuscated.

    .PARAMETER ScriptUri

    Specifies the Uri of the script to be obfuscated.

    .PARAMETER AbstractSyntaxTree

    Specifies the root Ast that represents the script to be obfuscated.

    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root Ast should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedAst -Ast $AbstractSyntaxTree

    .EXAMPLE

    Out-ObfuscatedAst "Write-Host example"

    .EXAMPLE

    Out-ObfuscatedAst { Write-Host example }

    .EXAMPLE

    Out-ObfuscatedAst -ScriptPath $ScriptPath

    .EXAMPLE

    @($Ast1, $Ast2, $Ast3) | Out-ObfuscatedAst

    .NOTES

    Out-ObfuscatedAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    [CmdletBinding(DefaultParameterSetName = "ByString")]
    Param(
        [Parameter(ParameterSetName = "ByString", Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String] $ScriptString,

        [Parameter(ParameterSetName = "ByScriptBlock", Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock] $ScriptBlock,

        [Parameter(ParameterSetName = "ByPath", Position = 0, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateScript( { Test-Path $_ -PathType leaf })]
        [Alias('PSPath')]
        [String] $ScriptPath,

        [Parameter(ParameterSetName = "ByUri", Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateScript( { $_.Scheme -match 'http|https' })]
        [Uri] $ScriptUri,

        [Parameter(ParameterSetName = "ByTree", Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.Ast] $AbstractSyntaxTree,

        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        If ($ScriptString) { $AbstractSyntaxTree = Get-Ast -ScriptString $ScriptString } 
        ElseIf ($ScriptBlock) {
            $AbstractSyntaxTree = Get-Ast -ScriptBlock $ScriptBlock
        }
        ElseIf ($ScriptPath) {
            $AbstractSyntaxTree = Get-Ast -ScriptPath $ScriptPath
        }
        ElseIf ($ScriptUri) {
            $AbstractSyntaxTree = Get-Ast -ScriptUri $ScriptUri
        }
        
        Switch ($AbstractSyntaxTree.GetType().Name) {
            "ArrayExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedArrayExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedArrayExpressionAst -Ast $AbstractSyntaxTree }
            }
            "ArrayLiteralAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedArrayLiteralAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedArrayLiteralAst -AstTypesToObfuscate $AstTypesToObfuscate -Ast $AbstractSyntaxTree }
            }
            "AssignmentStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedAssignmentStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedAssignmentStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "AttributeAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedAttributeAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedAttributeAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "AttributeBaseAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedAttributeBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedAttributeBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "AttributedExpessionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedAttributedExpessionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedAssignmentStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "BaseCtorInvokeMemberExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedBaseCtorInvokeMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedBaseCtorInvokeMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "BinaryExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedBinaryExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedBinaryExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "BlockStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedBlockStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedBlockStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "BreakStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedBreakStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedBreakStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "CatchClauseAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCatchClauseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCatchClauseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "CommandAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCommandAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCommandAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "CommandBaseAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCommandBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCommandBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            } 
            "CommandElementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCommandElementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCommandElementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "CommandExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCommandExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCommandExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "CommandParameterAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedCommandParameterAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedCommandParameterAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ConfigurationDefinitionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedConfigurationDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedConfigurationDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ConstantExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedConstantExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedConstantExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ContinueStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedContinueStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { $ObfuscatedExtent = Out-ObfuscatedContinueStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ConvertExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedConvertExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedConvertExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "DataStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedDataStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedDataStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "DoUntilStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedDoUntilStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedDoUntilStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "DoWhileStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedDoWhileStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedDoWhileStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "DynamicKeywordStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedDynamicKeywordStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedDynamicKeywordStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ErrorStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedErrorStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedErrorStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ExitStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedExitStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedExitStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ExpandableStringExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedExpandableStringExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedExpandableStringExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "FileRedirectionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedFileRedirectionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedFileRedirectionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ForEachStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedForEachStatementAstt -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedForEachStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ForStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedForStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedForStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "FunctionDefinitionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedFunctionDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedFunctionDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "FunctionMemberAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedFunctionMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedFunctionMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "HashtableAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedHashtableAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedHashtableAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "IfStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedIfStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedIfStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "IndexExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedIndexExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedIndexExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "InvokeMemberExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedInvokeMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedInvokeMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "LabeledStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedLabeledStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedLabeledStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "LoopStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedLoopStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedLoopStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "MemberAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "MemberExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedMemberExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "MergingRedirectionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedMergingRedirectionAstt -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedMergingRedirectionAstt -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "NamedAttributeArgumentAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedNamedAttributeArgumentAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedNamedAttributeArgumentAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "NamedBlockAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedNamedBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedNamedBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ParamBlockAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedParamBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedParamBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ParameterAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedParameterAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedParameterAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ParenExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedParenExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedParenExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "PipelineAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedPipelineAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedPipelineAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "PipelineBaseAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedPipelineBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedPipelineBaseAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "PropertyMemberAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedPropertyMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedPropertyMemberAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "RedirectionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedRedirectionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedRedirectionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ReturnStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedReturnStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedReturnStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ScriptBlockAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedScriptBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedScriptBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ScriptBlockExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedScriptBlockExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedScriptBlockExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "StatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "StatementBlockAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedStatementBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedStatementBlockAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "StringConstantExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedStringConstantExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedStringConstantExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "SubExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedSubExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedSubExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "SwitchStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedSwitchStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedSwitchStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "ThrowStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedThrowStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedThrowStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "TrapStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedTrapStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedTrapStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "TryStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedTryStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedTryStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "TypeConstraintAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedTypeConstraintAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedTypeConstraintAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "TypeDefinitionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedTypeDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedTypeDefinitionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "TypeExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedTypeExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedTypeExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "UnaryExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedUnaryExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedUnaryExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "UsingExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedUsingExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedUsingExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "UsingStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedUsingStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedUsingStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }

            }
            "VariableExpressionAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedVariableExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedVariableExpressionAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
            "WhileStatementAst" {
                If ($DisableNestedObfuscation) { Out-ObfuscatedWhileStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate -DisableNestedObfuscation }
                Else { Out-ObfuscatedWhileStatementAst -Ast $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate }
            }
        }
    }
}

# Ast Children
# AttributeBaseAst Inherited classes
# CommandElementAst Inherited Classes
# ExpressionAst Inherited Classes
# AttributedExpressionAst Inherited Class
# ConstantExpressionAst Inherited Class
# MemberExpressionAst Inherited Class
# InvokeMemberExpressionAst Inherited Class
# MemberAst Inherited Classes
# RedirectionAst Inherited Classes
# StatementAst Inherited Classes
# CommandBaseAst Inherited Classes
# LabeledStatementAst Inherited Classes
# LoopStatementAst Inherited Classes
# PipelineBaseAst Inherited Classes
# Utility functions
