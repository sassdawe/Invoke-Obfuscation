
Function Invoke-Obfuscation {
    <#
        .SYNOPSIS
            Master function that orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents. Interactive mode enables one to explore all available obfuscation functions and apply them incrementally to input PowerShell script block or script path contents.

            Invoke-Obfuscation Function: Invoke-Obfuscation
            Author: David Sass (@sassdawe)
            License: Apache License, Version 2.0
            Required Dependencies: Show-AsciiArt, Show-HelpMenu, Show-Menu, Show-OptionsMenu, Show-Tutorial and Out-ScriptContents (all located in Invoke-Obfuscation.ps1)
            Optional Dependencies: None
        .DESCRIPTION
            Invoke-Obfuscation orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments and common parent-child process relationships.
        .PARAMETER ScriptBlock
            Specifies a scriptblock containing your payload.
        .PARAMETER ScriptPath
            Specifies the path to your payload (can be local file, UNC-path, or remote URI).
        .PARAMETER Command
            Specifies the obfuscation commands to run against the input ScriptBlock or ScriptPath parameter.
        .PARAMETER NoExit
            (Optional - only works if Command is specified) Outputs the option to not exit after running obfuscation commands defined in Command parameter.
        .PARAMETER Quiet
            (Optional - only works if Command is specified) Outputs the option to output only the final obfuscated result via stdout.
        .EXAMPLE
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green}
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -Command 'TOKEN\ALL\1,1,TEST,LAUNCHER\STDIN++\2347,CLIP'
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -Command 'TOKEN\ALL\1,1,TEST,LAUNCHER\STDIN++\2347,CLIP' -NoExit
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -Command 'TOKEN\ALL\1,1,TEST,LAUNCHER\STDIN++\2347,CLIP' -Quiet
            C:\PS> Import-Module .\Invoke-Obfuscation.psd1; Invoke-Obfuscation -ScriptBlock {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} -Command 'TOKEN\ALL\1,1,TEST,LAUNCHER\STDIN++\2347,CLIP' -NoExit -Quiet
        .NOTES
            Invoke-Obfuscation orchestrates the application of all obfuscation functions to provided PowerShell script block or script path contents to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments.
            This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.
        .LINK
            http://www.danielbohannon.com
    #>

    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'ScriptPath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptPath,

        [String]
        $Command,

        [Switch]
        $NoExit,

        [Switch]
        $Quiet
    )

    # Define variables for CLI functionality.
    $Script:CliCommands = @()
    $Script:CompoundCommand = @()
    $Script:QuietWasSpecified = $FALSE
    $CliWasSpecified = $FALSE
    $NoExitWasSpecified = $FALSE

    # Either convert ScriptBlock to a String or convert script at $Path to a String.
    If ($PSBoundParameters['ScriptBlock']) {
        $Script:CliCommands += ('set scriptblock ' + [String]$ScriptBlock)
    }
    If ($PSBoundParameters['ScriptPath']) {
        $Script:CliCommands += ('set scriptpath ' + $ScriptPath)
    }

    # Append Command to CliCommands if specified by user input.
    If ($PSBoundParameters['Command']) {
        $Script:CliCommands += $Command.Split(',')
        $CliWasSpecified = $TRUE

        If ($PSBoundParameters['NoExit']) {
            $NoExitWasSpecified = $TRUE
        }

        If ($PSBoundParameters['Quiet']) {
            # Create empty Write-Host and Start-Sleep proxy functions to cause any Write-Host or Start-Sleep invocations to not do anything until non-interactive -Command values are finished being processed.
            Function Write-Host { }
            Function Start-Sleep { }
            $Script:QuietWasSpecified = $TRUE
        }
    }

    ########################################
    ## Script-wide variable instantiation ##
    ########################################

    # Script-level array of Show Options menu, set as SCRIPT-level so it can be set from within any of the functions.
    # Build out menu for Show Options selection from user in Show-OptionsMenu menu.
    $Script:ScriptPath = ''
    $Script:ScriptBlock = ''
    $Script:CliSyntax = @()
    $Script:ExecutionCommands = @()
    $Script:ObfuscatedCommand = ''
    $Script:ObfuscatedCommandHistory = @()
    $Script:ObfuscationLength = ''
    $Script:OptionsMenu = @()
    $Script:OptionsMenu += , @('ScriptPath '       , $Script:ScriptPath       , $TRUE)
    $Script:OptionsMenu += , @('ScriptBlock'       , $Script:ScriptBlock      , $TRUE)
    $Script:OptionsMenu += , @('CommandLineSyntax' , $Script:CliSyntax        , $FALSE)
    $Script:OptionsMenu += , @('ExecutionCommands' , $Script:ExecutionCommands, $FALSE)
    $Script:OptionsMenu += , @('ObfuscatedCommand' , $Script:ObfuscatedCommand, $FALSE)
    $Script:OptionsMenu += , @('ObfuscationLength' , $Script:ObfuscatedCommand, $FALSE)
    # Build out $SetInputOptions from above items set as $TRUE (as settable).
    $SettableInputOptions = @()
    ForEach ($Option in $Script:OptionsMenu) {
        If ($Option[2]) { $SettableInputOptions += ([String]$Option[0]).ToLower().Trim() }
    }

    # Script-level variable for whether LAUNCHER has been applied to current ObfuscatedToken.
    $Script:LauncherApplied = $FALSE

    # Ensure Invoke-Obfuscation module was properly imported before continuing.
    If (!(Get-Module Invoke-Obfuscation | Where-Object { $_.ModuleType -eq 'Manifest' })) {
        $PathTopsd1 = "$ScriptDir\Invoke-Obfuscation.psd1"
        If ($PathTopsd1.Contains(' ')) { $PathTopsd1 = '"' + $PathTopsd1 + '"' }
        Write-Host "`n`nERROR: Invoke-Obfuscation module is not loaded. You must run:" -ForegroundColor Red
        Write-Host "       Import-Module $PathTopsd1`n`n" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        Exit
    }

    # Maximum size for cmd.exe and clipboard.
    $CmdMaxLength = 8190; $CmdMaxLength | Out-Null

    #region Build interactive menus.
    $LineSpacing = '[*] '

    # Main Menu.
    $MenuLevel = @()
    $MenuLevel += , @($LineSpacing, 'TOKEN'    , 'Obfuscate PowerShell command <Tokens>')
    $MenuLevel += , @($LineSpacing, 'AST'      , "`tObfuscate PowerShell <Ast> nodes <(PS3.0+)>")
    $MenuLevel += , @($LineSpacing, 'STRING'   , 'Obfuscate entire command as a <String>')
    $MenuLevel += , @($LineSpacing, 'ENCODING' , 'Obfuscate entire command via <Encoding>')
    $MenuLevel += , @($LineSpacing, 'COMPRESS'       , 'Convert entire command to one-liner and <Compress>')
    $MenuLevel += , @($LineSpacing, 'LAUNCHER'       , 'Obfuscate command args w/<Launcher> techniques (run once at end)')

    # Main\Token Menu.
    $MenuLevel_Token = @()
    $MenuLevel_Token += , @($LineSpacing, 'STRING'     , 'Obfuscate <String> tokens (suggested to run first)')
    $MenuLevel_Token += , @($LineSpacing, 'COMMAND'    , 'Obfuscate <Command> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'ARGUMENT'   , 'Obfuscate <Argument> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'MEMBER'     , 'Obfuscate <Member> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'VARIABLE'   , 'Obfuscate <Variable> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'TYPE  '     , 'Obfuscate <Type> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'COMMENT'    , 'Remove all <Comment> tokens')
    $MenuLevel_Token += , @($LineSpacing, 'WHITESPACE' , 'Insert random <Whitespace> (suggested to run last)')
    $MenuLevel_Token += , @($LineSpacing, 'ALL   '     , 'Select <All> choices from above (random order)')

    $MenuLevel_Token_String = @()
    $MenuLevel_Token_String += , @($LineSpacing, '1' , "Concatenate --> e.g. <('co'+'ffe'+'e')>"                           , @('Out-ObfuscatedTokenCommand', 'String', 1))
    $MenuLevel_Token_String += , @($LineSpacing, '2' , "Reorder     --> e.g. <('{1}{0}'-f'ffee','co')>"                    , @('Out-ObfuscatedTokenCommand', 'String', 2))

    $MenuLevel_Token_Command = @()
    $MenuLevel_Token_Command += , @($LineSpacing, '1' , 'Ticks                   --> e.g. <Ne`w-O`Bject>'                   , @('Out-ObfuscatedTokenCommand', 'Command', 1))
    $MenuLevel_Token_Command += , @($LineSpacing, '2' , "Splatting + Concatenate --> e.g. <&('Ne'+'w-Ob'+'ject')>"          , @('Out-ObfuscatedTokenCommand', 'Command', 2))
    $MenuLevel_Token_Command += , @($LineSpacing, '3' , "Splatting + Reorder     --> e.g. <&('{1}{0}'-f'bject','New-O')>"   , @('Out-ObfuscatedTokenCommand', 'Command', 3))

    $MenuLevel_Token_Argument = @()
    $MenuLevel_Token_Argument += , @($LineSpacing, '1' , 'Random Case --> e.g. <nEt.weBclIenT>'                              , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 1))
    $MenuLevel_Token_Argument += , @($LineSpacing, '2' , 'Ticks       --> e.g. <nE`T.we`Bc`lIe`NT>'                          , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 2))
    $MenuLevel_Token_Argument += , @($LineSpacing, '3' , "Concatenate --> e.g. <('Ne'+'t.We'+'bClient')>"                    , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 3))
    $MenuLevel_Token_Argument += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'bClient','Net.We')>"             , @('Out-ObfuscatedTokenCommand', 'CommandArgument', 4))

    $MenuLevel_Token_Member = @()
    $MenuLevel_Token_Member += , @($LineSpacing, '1' , 'Random Case --> e.g. <dOwnLoAdsTRing>'                             , @('Out-ObfuscatedTokenCommand', 'Member', 1))
    $MenuLevel_Token_Member += , @($LineSpacing, '2' , 'Ticks       --> e.g. <d`Ow`NLoAd`STRin`g>'                         , @('Out-ObfuscatedTokenCommand', 'Member', 2))
    $MenuLevel_Token_Member += , @($LineSpacing, '3' , "Concatenate --> e.g. <('dOwnLo'+'AdsT'+'Ring').Invoke()>"          , @('Out-ObfuscatedTokenCommand', 'Member', 3))
    $MenuLevel_Token_Member += , @($LineSpacing, '4' , "Reorder     --> e.g. <('{1}{0}'-f'dString','Downloa').Invoke()>"   , @('Out-ObfuscatedTokenCommand', 'Member', 4))

    $MenuLevel_Token_Variable = @()
    $MenuLevel_Token_Variable += , @($LineSpacing, '1' , 'Random Case + {} + Ticks --> e.g. <${c`hEm`eX}>'                   , @('Out-ObfuscatedTokenCommand', 'Variable', 1))

    $MenuLevel_Token_Type = @()
    $MenuLevel_Token_Type += , @($LineSpacing, '1' , "Type Cast + Concatenate --> e.g. <[Type]('Con'+'sole')>"           , @('Out-ObfuscatedTokenCommand', 'Type', 1))
    $MenuLevel_Token_Type += , @($LineSpacing, '2' , "Type Cast + Reordered   --> e.g. <[Type]('{1}{0}'-f'sole','Con')>" , @('Out-ObfuscatedTokenCommand', 'Type', 2))

    $MenuLevel_Token_Whitespace = @()
    $MenuLevel_Token_Whitespace += , @($LineSpacing, '1' , "`tRandom Whitespace --> e.g. <.( 'Ne'  +'w-Ob' +  'ject')>"        , @('Out-ObfuscatedTokenCommand', 'RandomWhitespace', 1))

    $MenuLevel_Token_Comment = @()
    $MenuLevel_Token_Comment += , @($LineSpacing, '1' , "Remove Comments   --> e.g. self-explanatory"                       , @('Out-ObfuscatedTokenCommand', 'Comment', 1))

    $MenuLevel_Token_All = @()
    $MenuLevel_Token_All += , @($LineSpacing, '1' , "`tExecute <ALL> Token obfuscation techniques (random order)"       , @('Out-ObfuscatedTokenCommandAll', '', ''))

    # Main\Token Menu.
    $MenuLevel_Ast = @()
    $MenuLevel_Ast += , @($LineSpacing, 'NamedAttributeArgumentAst' , 'Obfuscate <NamedAttributeArgumentAst> nodes')
    $MenuLevel_Ast += , @($LineSpacing, 'ParamBlockAst'             , "`t`tObfuscate <ParamBlockAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'ScriptBlockAst'            , "`t`tObfuscate <ScriptBlockAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'AttributeAst'              , "`t`tObfuscate <AttributeAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'BinaryExpressionAst'       , "`tObfuscate <BinaryExpressionAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'HashtableAst'              , "`t`tObfuscate <HashtableAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'CommandAst'                , "`t`tObfuscate <CommandAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'AssignmentStatementAst'    , "`tObfuscate <AssignmentStatementAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'TypeExpressionAst'         , "`tObfuscate <TypeExpressionAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'TypeConstraintAst'         , "`tObfuscate <TypeConstraintAst> nodes")
    $MenuLevel_Ast += , @($LineSpacing, 'ALL'                       , "`t`t`tSelect <All> choices from above")

    $MenuLevel_Ast_NamedAttributeArgumentAst = @()
    $MenuLevel_Ast_NamedAttributeArgumentAst += , @($LineSpacing, '1' , 'Reorder e.g. <[Parameter(Mandatory, ValueFromPipeline = $True)]> --> <[Parameter(Mandatory = $True, ValueFromPipeline)]>'                     , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.NamedAttributeArgumentAst'), 1))

    $MenuLevel_Ast_ParamBlockAst = @()
    $MenuLevel_Ast_ParamBlockAst += , @($LineSpacing, '1' , 'Reorder e.g. <Param([Int]$One, [Int]$Two)> --> <Param([Int]$Two, [Int]$One)>'                                                                 , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.ParamBlockAst'), 1))

    $MenuLevel_Ast_ScriptBlockAst = @()
    $MenuLevel_Ast_ScriptBlockAst += , @($LineSpacing, '1' , 'Reorder e.g. <{ Begin {} Process {} End {} }> --> <{ End {} Begin {} Process {} }>'                                                           , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.ScriptBlockAst'), 1))

    $MenuLevel_Ast_AttributeAst = @()
    $MenuLevel_Ast_AttributeAst += , @($LineSpacing, '1' , 'Reorder e.g. <[Parameter(Position = 0, Mandatory)]> --> <[Parameter(Mandatory, Position = 0)]>'                                               , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.AttributeAst'), 1))

    $MenuLevel_Ast_BinaryExpressionAst = @()
    $MenuLevel_Ast_BinaryExpressionAst += , @($LineSpacing, '1' , 'Reorder e.g. <(2 + 3) * 4> --> <4 * (3 + 2)>'                                                                                                 , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.BinaryExpressionAst'), 1))

    $MenuLevel_Ast_HashtableAst = @()
    $MenuLevel_Ast_HashtableAst += , @($LineSpacing, '1' , "Reorder e.g. <@{ProviderName = 'Microsoft-Windows-PowerShell'; Id = 4104}> --> <@{Id = 4104; ProviderName = 'Microsoft-Windows-PowerShell'}>" , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.HashtableAst'), 1))

    $MenuLevel_Ast_CommandAst = @()
    $MenuLevel_Ast_CommandAst += , @($LineSpacing, '1' , 'Reorder e.g. <Get-Random -Min 1 -Max 100> --> <Get-Random -Max 100 -Min 1>'                                                                   , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.CommandAst'), 1))

    $MenuLevel_Ast_AssignmentStatementAst = @()
    $MenuLevel_Ast_AssignmentStatementAst += , @($LineSpacing, '1' , 'Rename e.g. <$Example = "Example"> --> <Set-Variable -Name Example -Value ("Example")>'                                                       , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.AssignmentStatementAst'), 1))

    $MenuLevel_Ast_TypeExpressionAst = @()
    $MenuLevel_Ast_TypeExpressionAst += , @($LineSpacing, '1' , 'Rename e.g. <[ScriptBlock]> --> <[Management.Automation.ScriptBlock]>'                                                                        , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.TypeExpressionAst'), 1))

    $MenuLevel_Ast_TypeConstraintAst = @()
    $MenuLevel_Ast_TypeConstraintAst += , @($LineSpacing, '1' , 'Rename e.g. <[Int] $Integer = 1> --> <[System.Int32] $Integer = 1>'                                                                             , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.TypeConstraintAst'), 1))

    $MenuLevel_Ast_All = @()
    $MenuLevel_Ast_All += , @($LineSpacing, '1' , "`tExecute <ALL> Ast obfuscation techniques"                                                                                                   , @('Out-ObfuscatedAst', @('System.Management.Automation.Language.NamedAttributeArgumentAst', 'System.Management.Automation.Language.ParamBlockAst', 'System.Management.Automation.Language.ScriptBlockAst', 'System.Management.Automation.Language.AttributeAst', 'System.Management.Automation.Language.BinaryExpressionAst', 'System.Management.Automation.Language.HashtableAst', 'System.Management.Automation.Language.CommandAst', 'System.Management.Automation.Language.AssignmentStatementAst', 'System.Management.Automation.Language.TypeExpressionAst', 'System.Management.Automation.Language.TypeConstraintAst'), ''))

    # Main\String Menu.
    $MenuLevel_String = @()
    $MenuLevel_String += , @($LineSpacing, '1' , '<Concatenate> entire command'                                      , @('Out-ObfuscatedStringCommand', '', 1))
    $MenuLevel_String += , @($LineSpacing, '2' , '<Reorder> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 2))
    $MenuLevel_String += , @($LineSpacing, '3' , '<Reverse> entire command after concatenating'                      , @('Out-ObfuscatedStringCommand', '', 3))

    # Main\Encoding Menu.
    $MenuLevel_Encoding = @()
    $MenuLevel_Encoding += , @($LineSpacing, '1' , "`tEncode entire command as <ASCII>"                                , @('Out-EncodedAsciiCommand'           , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '2' , "`tEncode entire command as <Hex>"                                  , @('Out-EncodedHexCommand'             , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '3' , "`tEncode entire command as <Octal>"                                , @('Out-EncodedOctalCommand'           , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '4' , "`tEncode entire command as <Binary>"                               , @('Out-EncodedBinaryCommand'          , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '5' , "`tEncrypt entire command as <SecureString> (AES)"                  , @('Out-SecureStringCommand'           , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '6' , "`tEncode entire command as <BXOR>"                                 , @('Out-EncodedBXORCommand'            , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '7' , "`tEncode entire command as <Special Characters>"                   , @('Out-EncodedSpecialCharOnlyCommand' , '', ''))
    $MenuLevel_Encoding += , @($LineSpacing, '8' , "`tEncode entire command as <Whitespace>"                           , @('Out-EncodedWhitespaceCommand'      , '', ''))

    # Main\Compress Menu.
    $MenuLevel_Compress = @()
    $MenuLevel_Compress += , @($LineSpacing, '1' , "Convert entire command to one-liner and <compress>"                , @('Out-CompressedCommand'             , '', ''))

    # Main\Launcher Menu.
    $MenuLevel_Launcher = @()
    $MenuLevel_Launcher += , @($LineSpacing, 'PS'            , "`t<PowerShell>")
    $MenuLevel_Launcher += , @($LineSpacing, 'CMD'           , '<Cmd> + PowerShell')
    $MenuLevel_Launcher += , @($LineSpacing, 'WMIC'          , '<Wmic> + PowerShell')
    $MenuLevel_Launcher += , @($LineSpacing, 'RUNDLL'        , '<Rundll32> + PowerShell')
    $MenuLevel_Launcher += , @($LineSpacing, 'VAR+'          , 'Cmd + set <Var> && PowerShell iex <Var>')
    $MenuLevel_Launcher += , @($LineSpacing, 'STDIN+'        , 'Cmd + <Echo> | PowerShell - (stdin)')
    $MenuLevel_Launcher += , @($LineSpacing, 'CLIP+'         , 'Cmd + <Echo> | Clip && PowerShell iex <clipboard>')
    $MenuLevel_Launcher += , @($LineSpacing, 'VAR++'         , 'Cmd + set <Var> && Cmd && PowerShell iex <Var>')
    $MenuLevel_Launcher += , @($LineSpacing, 'STDIN++'       , 'Cmd + set <Var> && Cmd <Echo> | PowerShell - (stdin)')
    $MenuLevel_Launcher += , @($LineSpacing, 'CLIP++'        , 'Cmd + <Echo> | Clip && Cmd && PowerShell iex <clipboard>')
    $MenuLevel_Launcher += , @($LineSpacing, 'RUNDLL++'      , 'Cmd + set Var && <Rundll32> && PowerShell iex Var')
    $MenuLevel_Launcher += , @($LineSpacing, 'MSHTA++'       , 'Cmd + set Var && <Mshta> && PowerShell iex Var')

    $MenuLevel_Launcher_PS = @()
    $MenuLevel_Launcher_PS += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '1'))
    $MenuLevel_Launcher_PS += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '1'))

    $MenuLevel_Launcher_CMD = @()
    $MenuLevel_Launcher_CMD += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '2'))
    $MenuLevel_Launcher_CMD += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '2'))

    $MenuLevel_Launcher_WMIC = @()
    $MenuLevel_Launcher_WMIC += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '3'))
    $MenuLevel_Launcher_WMIC += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '3'))

    $MenuLevel_Launcher_RUNDLL = @()
    $MenuLevel_Launcher_RUNDLL += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '4'))
    $MenuLevel_Launcher_RUNDLL += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '4'))

    ${MenuLevel_Launcher_VAR+} = @()
    ${MenuLevel_Launcher_VAR+} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '5'))
    ${MenuLevel_Launcher_VAR+} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '5'))

    ${MenuLevel_Launcher_STDIN+} = @()
    ${MenuLevel_Launcher_STDIN+} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '6'))
    ${MenuLevel_Launcher_STDIN+} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '6'))

    ${MenuLevel_Launcher_CLIP+} = @()
    ${MenuLevel_Launcher_CLIP+} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '7'))
    ${MenuLevel_Launcher_CLIP+} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '7'))

    ${MenuLevel_Launcher_VAR++} = @()
    ${MenuLevel_Launcher_VAR++} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '8'))
    ${MenuLevel_Launcher_VAR++} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '8'))

    ${MenuLevel_Launcher_STDIN++} = @()
    ${MenuLevel_Launcher_STDIN++} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '0' , "`tNO EXECUTION FLAGS"                                        , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '1' , "`t-NoExit"                                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '2' , "`t-NonInteractive"                                           , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '3' , "`t-NoLogo"                                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '4' , "`t-NoProfile"                                                , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '5' , "`t-Command"                                                  , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '6' , "`t-WindowStyle Hidden"                                       , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '7' , "`t-ExecutionPolicy Bypass"                                   , @('Out-PowerShellLauncher', '', '9'))
    ${MenuLevel_Launcher_STDIN++} += , @($LineSpacing, '8' , "`t-Wow64 (to path 32-bit powershell.exe)"                    , @('Out-PowerShellLauncher', '', '9'))

    ${MenuLevel_Launcher_CLIP++} = @()
    ${MenuLevel_Launcher_CLIP++} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '10'))
    ${MenuLevel_Launcher_CLIP++} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '10'))

    ${MenuLevel_Launcher_RUNDLL++} = @()
    ${MenuLevel_Launcher_RUNDLL++} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '11'))
    ${MenuLevel_Launcher_RUNDLL++} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '11'))

    ${MenuLevel_Launcher_MSHTA++} = @()
    ${MenuLevel_Launcher_MSHTA++} += , @("Enter string of numbers with all desired flags to pass to function. (e.g. 23459)`n", ''  , ''   , @('', '', ''))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '0' , 'NO EXECUTION FLAGS'                                          , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '1' , '-NoExit'                                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '2' , '-NonInteractive'                                             , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '3' , '-NoLogo'                                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '4' , '-NoProfile'                                                  , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '5' , '-Command'                                                    , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '6' , '-WindowStyle Hidden'                                         , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '7' , '-ExecutionPolicy Bypass'                                     , @('Out-PowerShellLauncher', '', '12'))
    ${MenuLevel_Launcher_MSHTA++} += , @($LineSpacing, '8' , '-Wow64 (to path 32-bit powershell.exe)'                      , @('Out-PowerShellLauncher', '', '12'))
    #endregion Build interactive menus.
    
    # Input options to display non-interactive menus or perform actions.
    $TutorialInputOptions = @(@('tutorial')                            , "<Tutorial> of how to use this tool        `t  " )
    $MenuInputOptionsShowHelp = @(@('help', 'get-help', '?', '-?', '/?', 'menu'), "Show this <Help> Menu                     `t  " )
    $MenuInputOptionsShowOptions = @(@('show options', 'show', 'options')       , "<Show options> for payload to obfuscate   `t  " )
    $ClearScreenInputOptions = @(@('clear', 'clear-host', 'cls')            , "<Clear> screen                            `t  " )
    $CopyToClipboardInputOptions = @(@('copy', 'clip', 'clipboard')             , "<Copy> ObfuscatedCommand to clipboard     `t  " )
    $OutputToDiskInputOptions = @(@('out')                                 , "Write ObfuscatedCommand <Out> to disk     `t  " )
    $ExecutionInputOptions = @(@('exec', 'execute', 'test', 'run')         , "<Execute> ObfuscatedCommand locally       `t  " )
    $ResetObfuscationInputOptions = @(@('reset')                               , "<Reset> ALL obfuscation for ObfuscatedCommand  ")
    $UndoObfuscationInputOptions = @(@('undo')                                , "<Undo> LAST obfuscation for ObfuscatedCommand  ")
    $BackCommandInputOptions = @(@('back', 'cd ..')                        , "Go <Back> to previous obfuscation menu    `t  " )
    $ExitCommandInputOptions = @(@('quit', 'exit')                         , "<Quit> Invoke-Obfuscation                 `t  " )
    $HomeMenuInputOptions = @(@('home', 'main')                         , "Return to <Home> Menu                     `t  " )
    # For Version 1.0 ASCII art is not necessary.
    #$ShowAsciiArtInputOptions     = @(@('ascii')                               , "Display random <ASCII> art for the lulz :)`t")

    # Add all above input options lists to be displayed in SHOW OPTIONS menu.
    $AllAvailableInputOptionsLists = @()
    $AllAvailableInputOptionsLists += , $TutorialInputOptions
    $AllAvailableInputOptionsLists += , $MenuInputOptionsShowHelp
    $AllAvailableInputOptionsLists += , $MenuInputOptionsShowOptions
    $AllAvailableInputOptionsLists += , $ClearScreenInputOptions
    $AllAvailableInputOptionsLists += , $ExecutionInputOptions
    $AllAvailableInputOptionsLists += , $CopyToClipboardInputOptions
    $AllAvailableInputOptionsLists += , $OutputToDiskInputOptions
    $AllAvailableInputOptionsLists += , $ResetObfuscationInputOptions
    $AllAvailableInputOptionsLists += , $UndoObfuscationInputOptions
    $AllAvailableInputOptionsLists += , $BackCommandInputOptions    
    $AllAvailableInputOptionsLists += , $ExitCommandInputOptions
    $AllAvailableInputOptionsLists += , $HomeMenuInputOptions
    # For Version 1.0 ASCII art is not necessary.
    #$AllAvailableInputOptionsLists  += , $ShowAsciiArtInputOptions

    # Input options to change interactive menus.
    $ExitInputOptions = $ExitCommandInputOptions[0]
    $MenuInputOptions = $BackCommandInputOptions[0] ; $MenuInputOptions | Out-Null

    # Obligatory ASCII Art.
    Show-AsciiArt
    Start-Sleep -Seconds 2

    # Show Help Menu once at beginning of script.
    Show-HelpMenu

    # Main loop for user interaction. Show-Menu function displays current function along with acceptable input options (defined in arrays instantiated above).
    # User input and validation is handled within Show-Menu.
    $UserResponse = ''
    While ($ExitInputOptions -NotContains ([String]$UserResponse).ToLower()) {
        $UserResponse = ([String]$UserResponse).Trim()

        If ($HomeMenuInputOptions[0] -Contains ([String]$UserResponse).ToLower()) {
            $UserResponse = ''
        }

        # Display menu if it is defined in a menu variable with $UserResponse in the variable name.
        If (Test-Path ('Variable:' + "MenuLevel$UserResponse")) {
            $UserResponse = Show-Menu (Get-Variable "MenuLevel$UserResponse").Value $UserResponse $Script:OptionsMenu
        }
        Else {
            Write-Error "The variable MenuLevel$UserResponse does not exist."
            $UserResponse = 'quit'
        }

        If (($UserResponse -eq 'quit') -AND $CliWasSpecified -AND !$NoExitWasSpecified) {
            Write-Output $Script:ObfuscatedCommand.Trim("`n")
            $UserInput = 'quit'; $UserInput | Out-Null
        }
    }
}


# Get location of this script no matter what the current directory is for the process executing this script.
$ScriptDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)