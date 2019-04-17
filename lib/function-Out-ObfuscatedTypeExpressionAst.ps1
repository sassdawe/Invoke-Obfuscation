

function Out-ObfuscatedTypeExpressionAst {
    <#

    .SYNOPSIS

    Obfuscates a TypeExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    Author: Ryan Cobb (@cobbr_io)
    License: Apache License, Version 2.0
    Required Dependecies: Out-ObfuscatedChildrenAst
    Optional Dependencies: none

    .DESCRIPTION

    Out-ObfuscatedTypeExpressionAst obfuscates a TypeExpressionAst using AbstractSyntaxTree-based obfuscation rules.

    .PARAMETER AbstractSyntaxTree

    Specifies the TypeExpressionAst to be obfuscated.
    
    .PARAMETER AstTypesToObfuscate

    Specifies the Ast Types within the root Ast that obfuscation should be applied to. Defaults to all types with obfuscation implemented.

    .PARAMETER DisableNestedObfuscation

    Specifies that only the root TypeExpressionAst should be obfuscated, obfuscation should not be applied recursively.

    .OUTPUTS

    String

    .EXAMPLE

    Out-ObfuscatedTypeExpressionAst -Ast $TypeExpressionAst

    .NOTES

    Out-ObfuscatedTypeExpressionAst is a part of Invoke-Obfuscation. Invoke-Obfuscation can be found at https://github.com/danielbohannon/Invoke-Obfuscation.

    #>
    Param (
        [Parameter(Position = 0, ValueFromPipeline, Mandatory)]
        [ValidateNotNullOrEmpty()]
        [Alias('Ast')]
        [System.Management.Automation.Language.TypeExpressionAst] $AbstractSyntaxTree,
        
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('AstTypes', 'Types')]
        [System.Type[]] $AstTypesToObfuscate = @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'),

        [Switch] $DisableNestedObfuscation
    )
    Process {
        Write-Verbose "[Out-ObfuscatedTypeExpressionAst]"
        If (-not ($AbstractSyntaxTree.GetType() -in $AstTypesToObfuscate)) {
            If (-not $DisableNestedObfuscation) {
                Out-ObfuscatedChildrenAst -AbstractSyntaxTree $AbstractSyntaxTree -AstTypesToObfuscate $AstTypesToObfuscate
            }
            Else { $AbstractSyntaxTree.Extent.Text }
        }
        Else {
            $TypeAccelerators = @(
                @("[Int]", "[System.Int32]"),
                @("[Long]", "[System.Int64]"),
                @("[Bool]", "[System.Boolean]"),
                @("[Float]", "[System.Single]"),
                @("[Regex]", "[System.Text.RegularExpressions.Regex]"),
                @("[Xml]", "[System.Xml.XmlDocument]"),
                @("[ScriptBlock]", "[System.Management.Automation.ScriptBlock]"),
                @("[Switch]", "[System.Management.Automation.SwitchParameter]"),
                @("[HashTable]", "[System.Collections.HashTable]"),
                @("[Ref]", "[System.Management.Automation.PSReference]"),
                @("[PSObject]", "[System.Management.Automation.PSObject]"),
                @("[PSCustomObject]", "[System.Management.Automation.PSCustomObject]"),
                @("[PSModuleInfo]", "[System.Management.Automation.PSModuleInfo]"),
                @("[PowerShell]", "[System.Management.Automation.PSModuleInfo]"),
                @("[RunspaceFactory]", "[System.Management.Automation.Runspaces.RunspaceFactory]"),
                @("[Runspace]", "[System.Management.Automation.Runspaces.Runspace]"),
                @("[IPAddress]", "[System.Net.IPAddress]"),
                @("[WMI]", "[System.Management.ManagementObject]"),
                @("[WMISearcher]", "[System.Management.ManagementObjectSearcher]"),
                @("[WMIClass]", "[System.Management.ManagementClass]"),
                @("[ADSI]", "[System.DirectoryServices.DirectoryEntry]"),
                @("[ADSISearcher]", "[System.DirectoryServices.DirectorySearcher]"),
                @("[PSPrimitiveDictionary]", "[System.Management.Automation.PSPrimitiveDictionary]")
            )
            $TypesCannotPrependSystem = $TypeAccelerators | %  { $_[0] }

            $ObfuscatedExtent = $AbstractSyntaxTree.Extent.Text
            $FoundEquivalent = $False
            ForEach ($TypeAccelerator in $TypeAccelerators) {
                ForEach ($TypeName in $TypeAccelerator) {
                    If ($TypeName.ToLower() -eq $AbstractSyntaxTree.Extent.Text.ToLower()) {
                        $ObfuscatedExtent = $TypeAccelerator | Get-Random
                        $FoundEquivalent = $True
                        break
                    }
                }
                If ($FoundEquivalent)  { break }
            }

            If ($ObfuscatedExtent.ToLower().StartsWith("[system.")) {
                If ((Get-Random -Minimum 1 -Maximum 3) -eq 1) {
                    $ObfuscatedExtent = "[" + $ObfuscatedExtent.SubString(8)
                }
            }
            ElseIf ((-not $ObfuscatedExtent.ToLower().StartsWith("[system.")) -AND (-not $ObfuscatedExtent -in $TypesCannotPrependSystem)) {
                If ((Get-Random -Minimum 1 -Maximum 3) -eq 1) {
                    $ObfuscatedExtent = "[System." + $ObfuscatedExtent.SubString(1)
                }
            }
            $ObfuscatedExtent
        }
    }
}