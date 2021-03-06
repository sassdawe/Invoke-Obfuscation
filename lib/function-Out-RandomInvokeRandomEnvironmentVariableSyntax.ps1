

Function Out-RandomInvokeRandomEnvironmentVariableSyntax {
    <#
.SYNOPSIS

HELPER FUNCTION :: Generates randomized syntax for invoking a process-level environment variable.

Invoke-Obfuscation Function: Out-RandomInvokeRandomEnvironmentVariableSyntax
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-ObfuscatedTokenCommand, Out-EncapsulatedInvokeExpression (found in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-RandomInvokeRandomEnvironmentVariableSyntax generates random invoke syntax and random process-level environment variable retrieval syntax for invoking command contents that are stored in a user-input process-level environment variable. This function is primarily used as a helper function for Out-PowerShellLauncher.

.PARAMETER EnvVarName

User input string or array of strings containing environment variable names to randomly select and apply invoke syntax.

.EXAMPLE

C:\PS> Out-RandomInvokeRandomEnvironmentVariableSyntax 'varname'

.(\"In\"  +\"v\"  +  \"o\"+  \"Ke-ExpRes\"+ \"sION\" ) (^&( \"GC\" +\"i\"  ) eNV:vaRNAMe  ).\"V`ALue\"

.NOTES

This cmdlet is a helper function for Out-PowerShellLauncher's more sophisticated $LaunchType options where the PowerShell command is set in process-level environment variables for command line obfuscation benefits.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $EnvVarName
    )

    # Retrieve random variable from variable name array passed in as argument.
    $EnvVarName = Get-Random -Input $EnvVarName

    # Generate numerous ways to invoke with $ExecutionContext as a variable, including Get-Variable varname, Get-ChildItem Variable:varname, Get-Item Variable:varname, etc.
    $ExecContextVariables = @()
    $ExecContextVariables += '(' + (Get-Random -Input @('DIR', 'Get-ChildItem', 'GCI', 'ChildItem', 'LS', 'Get-Item', 'GI', 'Item')) + ' ' + "'variable:" + (Get-Random -Input @('ex*xt', 'ExecutionContext')) + "').Value"
    $ExecContextVariables += '(' + (Get-Random -Input @('Get-Variable', 'GV', 'Variable')) + ' ' + "'" + (Get-Random -Input @('ex*xt', 'ExecutionContext')) + "'" + (Get-Random -Input (').Value', (' ' + ('-ValueOnly'.SubString(0, (Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length + 1)))) + ')')))

    # Select random option from above.
    $ExecContextVariable = Get-Random -Input $ExecContextVariables

    # Generate numerous ways to invoke command stored in environment variable.
    $GetRandomVariableSyntax = @()
    $GetRandomVariableSyntax += '(' + (Get-Random -Input @('DIR', 'Get-ChildItem', 'GCI', 'ChildItem', 'LS', 'Get-Item', 'GI', 'Item')) + ' ' + 'env:' + $EnvVarName + ').Value'
    $GetRandomVariableSyntax += ('(' + '[Environment]::GetEnvironmentVariable(' + "'$EnvVarName'" + ',' + "'Process'" + ')' + ')')
    
    # Select random option from above.
    $GetRandomVariableSyntax = Get-Random -Input $GetRandomVariableSyntax

    # Generate random invoke operation syntax.
    # 50% split between using $ExecutionContext invocation syntax versus IEX/Invoke-Expression/variable-obfuscated-'iex' syntax generated by Out-EncapsulatedInvokeExpression.
    $ExpressionToInvoke = $GetRandomVariableSyntax
    If (Get-Random -Input @(0..1)) {
        # Randomly decide on invoke operation since we've applied an additional layer of string manipulation in above steps.
        $InvokeOption = Out-EncapsulatedInvokeExpression $ExpressionToInvoke
    }
    Else {
        $InvokeOption = (Get-Random -Input @('$ExecutionContext', '${ExecutionContext}', $ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ExpressionToInvoke + ' ' * (Get-Random -Minimum 0 -Maximum 3) + ')'
    }

    # Random case of $InvokeOption.
    $InvokeOption = ([Char[]]$InvokeOption.ToLower() | ForEach-Object { $Char = $_; If (Get-Random -Input (0..1)) { $Char = $Char.ToString().ToUpper() } $Char }) -Join ''

    # Run random invoke operation through the appropriate token obfuscators if $PowerShellStdIn is not simply a value of - from above random options.
    If ($InvokeOption -ne '-') {
        # Run through all available token obfuscation functions in random order.
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption))
        $InvokeOption = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($InvokeOption)) 'RandomWhitespace' 1
    }
    
    # For obfuscated commands generated for $InvokeOption syntax, single-escape & < > and | characters for cmd.exe.
    ForEach ($Char in @('<', '>', '|', '&')) {
        # Remove single escaping and then escape all characters. This will handle single-escaped and not-escaped characters.
        If ($InvokeOption.Contains("$Char")) {
            $InvokeOption = $InvokeOption.Replace("$Char", "^$Char")
        }
    }
    
    # Escape double-quote with backslash for powershell.exe.
    If ($InvokeOption.Contains('"')) {
        $InvokeOption = $InvokeOption.Replace('"', '\"')
    }
    
    Return $InvokeOption
}

