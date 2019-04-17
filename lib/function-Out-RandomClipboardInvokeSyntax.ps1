
Function Out-RandomClipboardInvokeSyntax {
    <#
.SYNOPSIS

HELPER FUNCTION :: Generates randomized PowerShell syntax for invoking a command stored in the clipboard.

Invoke-Obfuscation Function: Out-RandomClipboardInvokeSyntax
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-ObfuscatedTokenCommand, Out-EncapsulatedInvokeExpression (found in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-RandomClipboardInvokeSyntax generates random PowerShell syntax for invoking a command stored in the clipboard. This technique is included to show the Blue Team that powershell.exe's command line arguments may not contain any contents of the command itself, but these could be stored in the parent/grandparent process if passed to powershell.exe via clipboard.

.EXAMPLE

C:\PS> Out-RandomClipboardInvokeSyntax

.  (  \"{0}{1}\" -f(  \"{1}{0}\"-f 'p','Add-Ty'  ),'e'  ) -AssemblyName (  \"{1}{0}{3}{2}\"-f ( \"{2}{0}{3}{1}\"-f'Wi','dows.Fo','em.','n'),(\"{1}{0}\"-f 'yst','S'),'s','rm'  )   ; (.( \"{0}\" -f'GV'  ) (\"{2}{3}{1}{0}{4}\" -f 'E','onCoNT','EXEC','UTi','XT')).\"Va`LuE\".\"inVOK`Ec`OMmANd\".\"inVOKe`SC`RIpT\"(( [sYsTEM.WInDOwS.foRMS.ClIPbOard]::( \"{1}{0}\"-f (\"{2}{1}{0}\" -f'XT','tTE','e'),'g').Invoke(  ) ) )   ;[System.Windows.Forms.Clipboard]::( \"{1}{0}\"-f'ar','Cle' ).Invoke(   )

.NOTES

This cmdlet is a helper function for Out-PowerShellLauncher's more sophisticated $LaunchType options where the PowerShell command is passed to powershell.exe via clipboard for command line obfuscation benefits.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    # Set variables necessary for loading appropriate class/type to be able to interact with the clipboard.
    $ReflectionAssembly = Get-Random -Input @('System.Reflection.Assembly', 'Reflection.Assembly')
    $WindowsClipboard = Get-Random -Input @('Windows.Clipboard', 'System.Windows.Clipboard')
    $WindowsFormsClipboard = Get-Random -Input @('System.Windows.Forms.Clipboard', 'Windows.Forms.Clipboard')
    
    # Randomly select flag argument substring for Add-Type -AssemblyCore.
    $FullArgument = "-AssemblyName"
    # Take into account the shorted flag of -AN as well.
    $AssemblyNameFlags = @()
    $AssemblyNameFlags += '-AN'
    For ($Index = 2; $Index -le $FullArgument.Length; $Index++) {
        $AssemblyNameFlags += $FullArgument.SubString(0, $Index)
    }
    $AssemblyNameFlag = Get-Random -Input $AssemblyNameFlags

    # Characters we will use to generate random variable name.
    # For simplicity do NOT include single- or double-quotes in this array.
    $CharsToRandomVarName = @(0..9)
    $CharsToRandomVarName += @('A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z')

    # Randomly choose variable name starting length.
    $RandomVarLength = (Get-Random -Input @(3..6))
   
    # Create random variable with characters from $CharsToRandomVarName.
    If ($CharsToRandomVarName.Count -lt $RandomVarLength) { $RandomVarLength = $CharsToRandomVarName.Count }
    $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ', '')

    # Generate random variable name.
    $RandomVarName = ((Get-Random -Input $CharsToRandomVarName -Count $RandomVarLength) -Join '').Replace(' ', '')

    # Generate paired random syntax options for: A) loading necessary class/assembly, B) retrieving contents from clipboard, and C) clearing/overwritting clipboard contents.
    $RandomClipSyntaxValue = Get-Random -Input @(1..3)
    Switch ($RandomClipSyntaxValue) {
        1 {
            $LoadClipboardClassOption = "Add-Type $AssemblyNameFlag PresentationCore"
            $GetClipboardContentsOption = "([$WindowsClipboard]::GetText())"
            $ClearClipboardOption = "[$WindowsClipboard]::" + (Get-Random -Input @('Clear()', "SetText(' ')"))
        }
        2 {
            $LoadClipboardClassOption = "Add-Type $AssemblyNameFlag System.Windows.Forms"
            $GetClipboardContentsOption = "([$WindowsFormsClipboard]::GetText())"
            $ClearClipboardOption = "[$WindowsFormsClipboard]::" + (Get-Random -Input @('Clear()', "SetText(' ')"))
        }
        3 {
            $LoadClipboardClassOption = (Get-Random -Input @('[Void]', '$NULL=', "`$$RandomVarName=")) + "[$ReflectionAssembly]::LoadWithPartialName('System.Windows.Forms')"
            $GetClipboardContentsOption = "([$WindowsFormsClipboard]::GetText())"
            $ClearClipboardOption = "[$WindowsFormsClipboard]::" + (Get-Random -Input @('Clear()', "SetText(' ')"))
        }
        default { Write-Error "An invalid RandomClipSyntaxValue value ($RandomClipSyntaxValue) was passed to switch block for Out-RandomClipboardInvokeSyntax."; Exit; }
    }
    
    # Generate syntax options for invoking clipboard contents, including numerous ways to invoke with $ExecutionContext as a variable, including Get-Variable varname, Get-ChildItem Variable:varname, Get-Item Variable:varname, etc.
    $ExecContextVariables = @()
    $ExecContextVariables += '(' + (Get-Random -Input @('DIR', 'Get-ChildItem', 'GCI', 'ChildItem', 'LS', 'Get-Item', 'GI', 'Item')) + ' ' + "'variable:" + (Get-Random -Input @('ex*xt', 'ExecutionContext')) + "').Value"
    $ExecContextVariables += '(' + (Get-Random -Input @('Get-Variable', 'GV', 'Variable')) + ' ' + "'" + (Get-Random -Input @('ex*xt', 'ExecutionContext')) + "'" + (Get-Random -Input (').Value', (' ' + ('-ValueOnly'.SubString(0, (Get-Random -Minimum 3 -Maximum ('-ValueOnly'.Length + 1)))) + ')')))
    # Select random option from above.
    $ExecContextVariable = Get-Random -Input $ExecContextVariables

    # Generate random invoke operation syntax.
    # 50% split between using $ExecutionContext invocation syntax versus IEX/Invoke-Expression/variable-obfuscated-'iex' syntax generated by Out-EncapsulatedInvokeExpression.
    $ExpressionToInvoke = $GetClipboardContentsOption
    If (Get-Random -Input @(0..1)) {
        # Randomly decide on invoke operation since we've applied an additional layer of string manipulation in above steps.
        $InvokeOption = Out-EncapsulatedInvokeExpression $ExpressionToInvoke
    }
    Else {
        $InvokeOption = (Get-Random -Input @('$ExecutionContext', '${ExecutionContext}', $ExecContextVariable)) + '.InvokeCommand.InvokeScript(' + ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ExpressionToInvoke + ' ' * (Get-Random -Minimum 0 -Maximum 3) + ')'
    }

    # Random case of $InvokeOption.
    $InvokeOption = ([Char[]]$InvokeOption.ToLower() | ForEach-Object { $Char = $_; If (Get-Random -Input (0..1)) { $Char = $Char.ToString().ToUpper() } $Char }) -Join ''

    # Set final syntax for invoking clipboard contents.
    $PowerShellClip = $LoadClipboardClassOption + ' ' * (Get-Random -Minimum 0 -Maximum 3) + ';' + ' ' * (Get-Random -Minimum 0 -Maximum 3) + $InvokeOption
    
    # Add syntax for clearing clipboard contents.
    $PowerShellClip = $PowerShellClip + ' ' * (Get-Random -Minimum 0 -Maximum 3) + ';' + ' ' * (Get-Random -Minimum 0 -Maximum 3) + $ClearClipboardOption

    # Run through all relevant token obfuscation functions except Type since it causes error for direct type casting relevant classes in a non-interactive PowerShell session.
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Member'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Member'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Command'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'CommandArgument'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'Variable'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'String'
    $PowerShellClip = Out-ObfuscatedTokenCommand -ScriptBlock ([ScriptBlock]::Create($PowerShellClip)) 'RandomWhitespace'
    
    # For obfuscated commands generated for $PowerShellClip syntax, single-escape & < > and | characters for cmd.exe.
    ForEach ($Char in @('<', '>', '|', '&')) {
        # Remove single escaping and then escape all characters. This will handle single-escaped and not-escaped characters.
        If ($PowerShellClip.Contains("$Char")) {
            $PowerShellClip = $PowerShellClip.Replace("$Char", "^$Char")
        }
    }
    
    # Escape double-quote with backslash for powershell.exe.
    If ($PowerShellClip.Contains('"')) {
        $PowerShellClip = $PowerShellClip.Replace('"', '\"')
    }

    Return $PowerShellClip
}