
function Test-ExpressionAstIsNumeric {
    <#

    .SYNOPSIS

    Recursively tests if an ExpressionAst is a numeric expression, and can be re-ordered.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: none
    Optional Dependencies: none

    .DESCRIPTION

    Test-ExpressionAstIsNumeric recursively tests if an ExpressionAst is a numeric expression, and can be re-ordered.

    .PARAMETER AbstractSyntaxTree

    Specifies the ExpressionAst that should be tested to see if it is a numeric expression.

    .OUTPUTS

    String

    .EXAMPLE

    Test-ExpressionAstIsNumeric -Ast (Get-Ast "1 + 2 + (3 - 4 * (5 / 6))")

    .NOTES

    Test-ExpressionAstIsNumeric is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.ExpressionAst] $AbstractSyntaxTree
    )
    Process {
        If ($AbstractSyntaxTree.StaticType.Name -in @('Int32', 'Int64', 'UInt32', 'UInt64', 'Decimal', 'Single', 'Double')) {
            $True
        }
        ElseIf ($AbstractSyntaxTree.Extent.Text -match "^[\d\.]+$") {
            $True
        }
        ElseIf ($AbstractSyntaxTree.Extent.Text -match "^[\d\.]+$") {
            $True
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'BinaryExpressionAst') {
            ((Test-ExpressionAstIsNumeric -Ast $AbstractSyntaxTree.Left) -AND (Test-ExpressionAstIsNumeric -Ast $AbstractSyntaxTree.Right))
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'UnaryExpressionAst' -AND [System.Management.Automation.Language.TokenTraits]::Text($AbstractSyntaxTree.TokenKind) -in @("+", "-", "*", "/", "++", "--")) {
            (Test-ExpressionAstIsNumeric -Ast $AbstractSyntaxTree.Child)
        }
        ElseIf ($AbstractSyntaxTree.GetType().Name -eq 'ParenExpressionAst' -AND $AbstractSyntaxTree.Pipeline.GetType().Name -eq 'PipelineAst') {
            $PipelineElements = ($AbstractSyntaxTree.Pipeline.PipelineElements) -as [array]
            If ($PipelineElements.Count -eq 1) {
                (Test-ExpressionAstIsNumeric -Ast $PipelineElements[0].Expression)
            } Else { $False }
        }
        Else {
            $False
        }
    }
}
