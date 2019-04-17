Function Show-Menu {
    <#
        .SYNOPSIS

            HELPER FUNCTION :: Displays current menu with obfuscation navigation and application options for Invoke-Obfuscation.

            Invoke-Obfuscation Function: Show-Menu
            Author: David Sass (@sassdawe)
            License: Apache License, Version 2.0
            Required Dependencies: None
            Optional Dependencies: None
        
        .DESCRIPTION

            Show-Menu displays current menu with obfuscation navigation and application options for Invoke-Obfuscation.

        .PARAMETER Menu

        Specifies the menu options to display, with acceptable input options parsed out of this array.

        .PARAMETER MenuName

        Specifies the menu header display and the breadcrumb used in the interactive prompt display.

        .PARAMETER Script:OptionsMenu

        Specifies the script-wide variable containing additional acceptable input in addition to each menu's specific acceptable input (e.g. EXIT, QUIT, BACK, HOME, MAIN, etc.).

        .EXAMPLE

        C:\PS> Show-Menu

        .NOTES

        This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

        .LINK

        http://www.danielbohannon.com
    #>

    Param(
        [Parameter(ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Object[]]
        $Menu,

        [String]
        $MenuName,

        [Object[]]
        $Script:OptionsMenu
    )

    # Extract all acceptable values from $Menu.
    $AcceptableInput = @()
    $SelectionContainsCommand = $FALSE
    ForEach ($Line in $Menu) {
        # If there are 4 items in each $Line in $Menu then the fourth item is a command to exec if selected.
        If ($Line.Count -eq 4) {
            $SelectionContainsCommand = $TRUE
        }
        $AcceptableInput += ($Line[1]).Trim(' ')
    }

    $UserInput = $NULL
    
    While ($AcceptableInput -NotContains $UserInput) {
        # Format custom breadcrumb prompt.
        Write-Host "`n"
        $BreadCrumb = $MenuName.Trim('_')
        If ($BreadCrumb.Length -gt 1) {
            If ($BreadCrumb.ToLower() -eq 'show options') {
                $BreadCrumb = 'Show Options'
            }
            If ($MenuName -ne '') {
                # Handle specific case substitutions from what is ALL CAPS in interactive menu and then correct casing we want to appear in the Breadcrumb.
                $BreadCrumbOCD = @()
                $BreadCrumbOCD += , @('ps'      , 'PS')
                $BreadCrumbOCD += , @('cmd'     , 'Cmd')
                $BreadCrumbOCD += , @('wmic'    , 'Wmic')
                $BreadCrumbOCD += , @('rundll'  , 'RunDll')
                $BreadCrumbOCD += , @('var+'    , 'Var+')
                $BreadCrumbOCD += , @('stdin+'  , 'StdIn+')
                $BreadCrumbOCD += , @('clip+'   , 'Clip+')
                $BreadCrumbOCD += , @('var++'   , 'Var++')
                $BreadCrumbOCD += , @('stdin++' , 'StdIn++')
                $BreadCrumbOCD += , @('clip++'  , 'Clip++')
                $BreadCrumbOCD += , @('rundll++', 'RunDll++')
                $BreadCrumbOCD += , @('mshta++' , 'Mshta++')
                $BreadCrumbOCD += , @('ast', 'AST')

                $BreadCrumbArray = @()
                ForEach ($Crumb in $BreadCrumb.Split('_')) {
                    # Perform casing substitutions for any matches in $BreadCrumbOCD array.
                    $StillLookingForSubstitution = $TRUE
                    ForEach ($Substitution in $BreadCrumbOCD) {
                        If ($Crumb.ToLower() -eq $Substitution[0]) {
                            $BreadCrumbArray += $Substitution[1]
                            $StillLookingForSubstitution = $FALSE
                        }
                    }

                    # If no substitution occurred above then simply upper-case the first character and lower-case all the remaining characters.
                    If ($StillLookingForSubstitution) {
                        $BreadCrumbArray += $Crumb.SubString(0, 1).ToUpper() + $Crumb.SubString(1).ToLower()

                        # If no substitution was found for the 3rd or later BreadCrumb element (only for Launcher BreadCrumb) then throw a warning so we can add this substitution pair to $BreadCrumbOCD.
                        If (($BreadCrumb.Split('_').Count -eq 2) -AND ($BreadCrumb.StartsWith('Launcher_')) -AND ($Crumb -ne 'Launcher')) {
                            Write-Warning "No substituion pair was found for `$Crumb=$Crumb in `$BreadCrumb=$BreadCrumb. Add this `$Crumb substitution pair to `$BreadCrumbOCD array in Invoke-Obfuscation."
                        }
                    }
                }
                $BreadCrumb = $BreadCrumbArray -Join '\'
            }
            $BreadCrumb = '\' + $BreadCrumb
        }
        
        # Output menu heading.
        $FirstLine = "Choose one of the below "
        If ($BreadCrumb -ne '') {
            $FirstLine = $FirstLine + $BreadCrumb.Trim('\') + ' '
        }
        Write-Host "$FirstLine" -NoNewLine
        
        # Change color and verbiage if selection will execute command.
        If ($SelectionContainsCommand) {
            Write-Host "options" -NoNewLine -ForegroundColor Green
            Write-Host " to" -NoNewLine
            Write-Host " APPLY" -NoNewLine -ForegroundColor Green
            Write-Host " to current payload" -NoNewLine
        }
        Else {
            Write-Host "options" -NoNewLine -ForegroundColor Yellow
        }
        Write-Host ":`n"
    
        ForEach ($Line in $Menu) {
            $LineSpace = $Line[0]
            $LineOption = $Line[1]
            $LineValue = $Line[2]
            Write-Host $LineSpace -NoNewLine

            # If not empty then include breadcrumb in $LineOption output (is not colored and won't affect user input syntax).
            If (($BreadCrumb -ne '') -AND ($LineSpace.StartsWith('['))) {
                Write-Host ($BreadCrumb.ToUpper().Trim('\') + '\') -NoNewLine
            }
            
            # Change color if selection will execute command.
            If ($SelectionContainsCommand) {
                Write-Host $LineOption -NoNewLine -ForegroundColor Green
            }
            Else {
                Write-Host $LineOption -NoNewLine -ForegroundColor Yellow
            }
            
            # Add additional coloring to string encapsulated by <> if it exists in $LineValue.
            If ($LineValue.Contains('<') -AND $LineValue.Contains('>')) {
                $FirstPart = $LineValue.SubString(0, $LineValue.IndexOf('<'))
                $MiddlePart = $LineValue.SubString($FirstPart.Length + 1)
                $MiddlePart = $MiddlePart.SubString(0, $MiddlePart.IndexOf('>'))
                $LastPart = $LineValue.SubString($FirstPart.Length + $MiddlePart.Length + 2)
                Write-Host "`t$FirstPart" -NoNewLine
                Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan

                # Handle if more than one term needs to be output in different color.
                If ($LastPart.Contains('<') -AND $LastPart.Contains('>')) {
                    $LineValue = $LastPart
                    $FirstPart = $LineValue.SubString(0, $LineValue.IndexOf('<'))
                    $MiddlePart = $LineValue.SubString($FirstPart.Length + 1)
                    $MiddlePart = $MiddlePart.SubString(0, $MiddlePart.IndexOf('>'))
                    $LastPart = $LineValue.SubString($FirstPart.Length + $MiddlePart.Length + 2)
                    Write-Host "$FirstPart" -NoNewLine
                    If ($MiddlePart.EndsWith("(PS3.0+)")) {
                        Write-Host $MiddlePart -NoNewline -ForegroundColor Red
                    }
                    Else {
                        Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
                    }
                }

                Write-Host $LastPart
            }
            Else {
                Write-Host "`t$LineValue"
            }
        }
        
        # Prompt for user input with custom breadcrumb prompt.
        Write-Host ''
        If ($UserInput -ne '') { Write-Host '' }
        $UserInput = ''
        
        While (($UserInput -eq '') -AND ($Script:CompoundCommand.Count -eq 0)) {
            # Output custom prompt.
            Write-Host "Invoke-Obfuscation$BreadCrumb> " -NoNewLine -ForegroundColor Magenta

            # Get interactive user input if CliCommands input variable was not specified by user.
            If (($Script:CliCommands.Count -gt 0) -OR ($Script:CliCommands -ne $NULL)) {
                If ($Script:CliCommands.GetType().Name -eq 'String') {
                    $NextCliCommand = $Script:CliCommands.Trim()
                    $Script:CliCommands = @()
                }
                Else {
                    $NextCliCommand = ([String]$Script:CliCommands[0]).Trim()
                    $Script:CliCommands = For ($i = 1; $i -lt $Script:CliCommands.Count; $i++) { $Script:CliCommands[$i] }
                }

                $UserInput = $NextCliCommand
            }
            Else {
                # If Command was defined on command line and NoExit switch was not defined then output final ObfuscatedCommand to stdout and then quit. Otherwise continue with interactive Invoke-Obfuscation.
                If ($CliWasSpecified -AND ($Script:CliCommands.Count -lt 1) -AND ($Script:CompoundCommand.Count -lt 1) -AND ($Script:QuietWasSpecified -OR !$NoExitWasSpecified)) {
                    If ($Script:QuietWasSpecified) {
                        # Remove Write-Host and Start-Sleep proxy functions so that Write-Host and Start-Sleep cmdlets will be called during the remainder of the interactive Invoke-Obfuscation session.
                        Remove-Item -Path Function:Write-Host
                        Remove-Item -Path Function:Start-Sleep

                        $Script:QuietWasSpecified = $FALSE

                        # Automatically run 'Show Options' so the user has context of what has successfully been executed.
                        $UserInput = 'show options'
                        $BreadCrumb = 'Show Options'
                    }
                    # -NoExit wasn't specified and -Command was, so we will output the result back in the main While loop.
                    If (!$NoExitWasSpecified) {
                        $UserInput = 'quit'
                    }
                }
                Else {
                    $UserInput = (Read-Host).Trim()
                }

                # Process interactive UserInput using CLI syntax, so comma-delimited and slash-delimited commands can be processed interactively.
                If (($Script:CliCommands.Count -eq 0) -AND !$UserInput.ToLower().StartsWith('set ') -AND $UserInput.Contains(',')) {
                    $Script:CliCommands = $UserInput.Split(',')
                    
                    # Reset $UserInput so current While loop will be traversed once more and process UserInput command as a CliCommand.
                    $UserInput = ''
                }
            }
        }

        # Trim any leading trailing slashes so it doesn't misinterpret it as a compound command unnecessarily.
        $UserInput = $UserInput.Trim('/\')

        # Cause UserInput of base menu level directories to automatically work.
        # The only exception is STRING if the current MenuName is _token since it can be the base menu STRING or TOKEN/STRING.
        If ((($MenuLevel | ForEach-Object { $_[1].Trim() }) -Contains $UserInput.Split('/\')[0]) -AND !(('string' -Contains $UserInput.Split('/\')[0]) -AND ($MenuName -eq '_token')) -AND ($MenuName -ne '')) {
            $UserInput = 'home/' + $UserInput.Trim()
        }

        # If current command contains \ or / and does not start with SET or OUT then we are dealing with a compound command.
        # Setting $Script:CompounCommand in below IF block.
        If (($Script:CompoundCommand.Count -eq 0) -AND !$UserInput.ToLower().StartsWith('set ') -AND !$UserInput.ToLower().StartsWith('out ') -AND ($UserInput.Contains('\') -OR $UserInput.Contains('/'))) {
            $Script:CompoundCommand = $UserInput.Split('/\')
        }

        # If current command contains \ or / and does not start with SET then we are dealing with a compound command.
        # Parsing out next command from $Script:CompounCommand in below IF block.
        If ($Script:CompoundCommand.Count -gt 0) {
            $UserInput = ''
            While (($UserInput -eq '') -AND ($Script:CompoundCommand.Count -gt 0)) {
                # If last compound command then it will be a string.
                If ($Script:CompoundCommand.GetType().Name -eq 'String') {
                    $NextCompoundCommand = $Script:CompoundCommand.Trim()
                    $Script:CompoundCommand = @()
                }
                Else {
                    # If there are more commands left in compound command then it won't be a string (above IF block).
                    # In this else block we get the next command from CompoundCommand array.
                    $NextCompoundCommand = ([String]$Script:CompoundCommand[0]).Trim()
                    
                    # Set remaining commands back into CompoundCommand.
                    $Temp = $Script:CompoundCommand
                    $Script:CompoundCommand = @()
                    For ($i = 1; $i -lt $Temp.Count; $i++) {
                        $Script:CompoundCommand += $Temp[$i]
                    }
                }
                $UserInput = $NextCompoundCommand
            }
        }

        # Handle new RegEx functionality.
        # Identify if there is any regex in current UserInput by removing all alphanumeric characters (and + or # which are found in launcher names).
        $TempUserInput = $UserInput.ToLower()
        @(97..122) | ForEach-Object { $TempUserInput = $TempUserInput.Replace([String]([Char]$_), '') }
        @(0..9) | ForEach-Object { $TempUserInput = $TempUserInput.Replace($_, '') }
        $TempUserInput = $TempUserInput.Replace(' ', '').Replace('+', '').Replace('#', '').Replace('\', '').Replace('/', '').Replace('-', '').Replace('?', '')

        If (($TempUserInput.Length -gt 0) -AND !($UserInput.Trim().ToLower().StartsWith('set ')) -AND !($UserInput.Trim().ToLower().StartsWith('out '))) {
            # Replace any simple wildcard with .* syntax.
            $UserInput = $UserInput.Replace('.*', '_____').Replace('*', '.*').Replace('_____', '.*')

            # Prepend UserInput with ^ and append with $ if not already there.
            If (!$UserInput.Trim().StartsWith('^') -AND !$UserInput.Trim().StartsWith('.*')) {
                $UserInput = '^' + $UserInput
            }
            If (!$UserInput.Trim().EndsWith('$') -AND !$UserInput.Trim().EndsWith('.*')) {
                $UserInput = $UserInput + '$'
            }

            # See if there are any filtered matches in the current menu.
            Try {
                $MenuFiltered = ($Menu | Where-Object { ($_[1].Trim() -Match $UserInput) -AND ($_[1].Trim().Length -gt 0) } | ForEach-Object { $_[1].Trim() })
            }
            Catch {
                # Output error message if Regular Expression causes error in above filtering step.
                # E.g. Using *+ instead of *[+]
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host ' The current Regular Expression caused the following error:'
                write-host "       $_" -ForegroundColor Red
            }

            # If there are filtered matches in the current menu then randomly choose one for the UserInput value.
            If ($MenuFiltered -ne $NULL) {
                # Randomly select UserInput from filtered options.
                $UserInput = (Get-Random -Input $MenuFiltered).Trim()

                # Output randomly chosen option (and filtered options selected from) if more than one option were returned from regex.
                If ($MenuFiltered.Count -gt 1) {
                    # Change color and verbiage if acceptable options will execute an obfuscation function.
                    If ($SelectionContainsCommand) {
                        $ColorToOutput = 'Green'
                    }
                    Else {
                        $ColorToOutput = 'Yellow'
                    }

                    Write-Host "`n`nRandomly selected " -NoNewline
                    Write-Host $UserInput -NoNewline -ForegroundColor $ColorToOutput
                    write-host " from the following filtered options: " -NoNewline

                    For ($i = 0; $i -lt $MenuFiltered.Count - 1; $i++) {
                        Write-Host $MenuFiltered[$i].Trim() -NoNewLine -ForegroundColor $ColorToOutput
                        Write-Host ', ' -NoNewLine
                    }
                    Write-Host $MenuFiltered[$MenuFiltered.Count - 1].Trim() -NoNewLine -ForegroundColor $ColorToOutput
                }
            }
        }

        # If $UserInput is all numbers and is in a menu in $MenusWithMultiSelectNumbers
        $OverrideAcceptableInput = $FALSE
        $MenusWithMultiSelectNumbers = @('\Launcher')
        If (($UserInput.Trim(' 0123456789').Length -eq 0) -AND $BreadCrumb.Contains('\') -AND ($MenusWithMultiSelectNumbers -Contains $BreadCrumb.SubString(0, $BreadCrumb.LastIndexOf('\')))) {
            $OverrideAcceptableInput = $TRUE
        }
        
        If ($ExitInputOptions -Contains $UserInput.ToLower()) {
            Return $ExitInputOptions[0]
        }
        ElseIf ($MenuInputOptions -Contains $UserInput.ToLower()) {
            # Commands like 'back' that will return user to previous interactive menu.
            If ($BreadCrumb.Contains('\')) { $UserInput = $BreadCrumb.SubString(0, $BreadCrumb.LastIndexOf('\')).Replace('\', '_') }
            Else { $UserInput = '' }

            Return $UserInput.ToLower()
        }
        ElseIf ($HomeMenuInputOptions[0] -Contains $UserInput.ToLower()) {
            Return $UserInput.ToLower()
        }
        ElseIf ($UserInput.ToLower().StartsWith('set ')) {
            # Extract $UserInputOptionName and $UserInputOptionValue from $UserInput SET command.
            $UserInputOptionName = $NULL
            $UserInputOptionValue = $NULL
            $HasError = $FALSE
    
            $UserInputMinusSet = $UserInput.SubString(4).Trim()
            If ($UserInputMinusSet.IndexOf(' ') -eq -1) {
                $HasError = $TRUE
                $UserInputOptionName = $UserInputMinusSet.Trim()
            }
            Else {
                $UserInputOptionName = $UserInputMinusSet.SubString(0, $UserInputMinusSet.IndexOf(' ')).Trim().ToLower()
                $UserInputOptionValue = $UserInputMinusSet.SubString($UserInputMinusSet.IndexOf(' ')).Trim()
            }

            # Validate that $UserInputOptionName is defined in $SettableInputOptions.
            If ($SettableInputOptions -Contains $UserInputOptionName) {
                # Perform separate validation for $UserInputOptionValue before setting value. Set to 'emptyvalue' if no value was entered.
                If ($UserInputOptionValue.Length -eq 0) { $UserInputOptionName = 'emptyvalue' }
                Switch ($UserInputOptionName.ToLower()) {
                    'scriptpath' {
                        If ($UserInputOptionValue -AND ((Test-Path $UserInputOptionValue) -OR ($UserInputOptionValue -Match '(http|https)://'))) {
                            # Reset ScriptBlock in case it contained a value.
                            $Script:ScriptBlock = ''
                        
                            # Check if user-input ScriptPath is a URL or a directory.
                            If ($UserInputOptionValue -Match '(http|https)://') {
                                # ScriptPath is a URL.
                            
                                # Download content.
                                $Script:ScriptBlock = (New-Object Net.WebClient).DownloadString($UserInputOptionValue)
                            
                                # Set script-wide variables for future reference.
                                $Script:ScriptPath = $UserInputOptionValue
                                $Script:ObfuscatedCommand = $Script:ScriptBlock
                                $Script:ObfuscatedCommandHistory = @()
                                $Script:ObfuscatedCommandHistory += $Script:ScriptBlock
                                $Script:CliSyntax = @()
                                $Script:ExecutionCommands = @()
                                $Script:LauncherApplied = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath (as URL):" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                            ElseIf ((Get-Item $UserInputOptionValue) -is [System.IO.DirectoryInfo]) {
                                # ScriptPath does not exist.
                                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                                Write-Host ' Path is a directory instead of a file (' -NoNewLine
                                Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                                Write-Host ").`n" -NoNewLine
                            }
                            Else {
                                # Read contents from user-input ScriptPath value.
                                Get-ChildItem $UserInputOptionValue -ErrorAction Stop | Out-Null
                                $Script:ScriptBlock = [IO.File]::ReadAllText((Resolve-Path $UserInputOptionValue))
                        
                                # Set script-wide variables for future reference.
                                $Script:ScriptPath = $UserInputOptionValue
                                $Script:ObfuscatedCommand = $Script:ScriptBlock
                                $Script:ObfuscatedCommandHistory = @()
                                $Script:ObfuscatedCommandHistory += $Script:ScriptBlock
                                $Script:CliSyntax = @()
                                $Script:ExecutionCommands = @()
                                $Script:LauncherApplied = $FALSE
                            
                                Write-Host "`n`nSuccessfully set ScriptPath:" -ForegroundColor Cyan
                                Write-Host $Script:ScriptPath -ForegroundColor Magenta
                            }
                        }
                        Else {
                            # ScriptPath not found (failed Test-Path).
                            Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                            Write-Host ' Path not found (' -NoNewLine
                            Write-Host "$UserInputOptionValue" -NoNewLine -ForegroundColor Cyan
                            Write-Host ").`n" -NoNewLine
                        }
                    }
                    'scriptblock' {
                        # Remove evenly paired {} '' or "" if user includes it around their scriptblock input.
                        ForEach ($Char in @(@('{', '}'), @('"', '"'), @("'", "'"))) {
                            While ($UserInputOptionValue.StartsWith($Char[0]) -AND $UserInputOptionValue.EndsWith($Char[1])) {
                                $UserInputOptionValue = $UserInputOptionValue.SubString(1, $UserInputOptionValue.Length - 2).Trim()
                            }
                        }

                        # Check if input is PowerShell encoded command syntax so we can decode for scriptblock.
                        If ($UserInputOptionValue -Match 'powershell(.exe | )\s*-(e |ec |en |enc |enco |encod |encode)\s*["'']*[a-z=]') {
                            # Extract encoded command.
                            $EncodedCommand = $UserInputOptionValue.SubString($UserInputOptionValue.ToLower().IndexOf(' -e') + 3)
                            $EncodedCommand = $EncodedCommand.SubString($EncodedCommand.IndexOf(' ')).Trim(" '`"")

                            # Decode Unicode-encoded $EncodedCommand
                            $UserInputOptionValue = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedCommand))
                        }

                        # Set script-wide variables for future reference.
                        $Script:ScriptPath = 'N/A'
                        $Script:ScriptBlock = $UserInputOptionValue
                        $Script:ObfuscatedCommand = $UserInputOptionValue
                        $Script:ObfuscatedCommandHistory = @()
                        $Script:ObfuscatedCommandHistory += $UserInputOptionValue
                        $Script:CliSyntax = @()
                        $Script:ExecutionCommands = @()
                        $Script:LauncherApplied = $FALSE
                    
                        Write-Host "`n`nSuccessfully set ScriptBlock:" -ForegroundColor Cyan
                        Write-Host $Script:ScriptBlock -ForegroundColor Magenta
                    }
                    'emptyvalue' {
                        # No OPTIONVALUE was entered after OPTIONNAME.
                        $HasError = $TRUE
                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host ' No value was entered after' -NoNewLine
                        Write-Host ' SCRIPTBLOCK/SCRIPTPATH' -NoNewLine -ForegroundColor Cyan
                        Write-Host '.' -NoNewLine
                    }
                    default { Write-Error "An invalid OPTIONNAME ($UserInputOptionName) was passed to switch block."; Exit }
                }
            }
            Else {
                $HasError = $TRUE
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host ' OPTIONNAME' -NoNewLine
                Write-Host " $UserInputOptionName" -NoNewLine -ForegroundColor Cyan
                Write-Host " is not a settable option." -NoNewLine
            }
    
            If ($HasError) {
                Write-Host "`n       Correct syntax is" -NoNewLine
                Write-Host ' SET OPTIONNAME VALUE' -NoNewLine -ForegroundColor Green
                Write-Host '.' -NoNewLine
        
                Write-Host "`n       Enter" -NoNewLine
                Write-Host ' SHOW OPTIONS' -NoNewLine -ForegroundColor Yellow
                Write-Host ' for more details.'
            }
        }
        ElseIf (($AcceptableInput -Contains $UserInput) -OR ($OverrideAcceptableInput)) {
            # User input matches $AcceptableInput extracted from the current $Menu, so decide if:
            # 1) an obfuscation function needs to be called and remain in current interactive prompt, or
            # 2) return value to enter into a new interactive prompt.

            # Format breadcrumb trail to successfully retrieve the next interactive prompt.
            $UserInput = $BreadCrumb.Trim('\').Replace('\', '_') + '_' + $UserInput
            If ($BreadCrumb.StartsWith('\')) { $UserInput = '_' + $UserInput }

            # If the current selection contains a command to execute then continue. Otherwise return to go to another menu.
            If ($SelectionContainsCommand) {
                # Make sure user has entered command or path to script.
                If ($Script:ObfuscatedCommand -ne $NULL) {
                    # Iterate through lines in $Menu to extract command for the current selection in $UserInput.
                    ForEach ($Line in $Menu) {
                        If ($Line[1].Trim(' ') -eq $UserInput.SubString($UserInput.LastIndexOf('_') + 1)) { $CommandToExec = $Line[3]; Continue }
                    }

                    If (!$OverrideAcceptableInput) {
                        # Extract arguments from $CommandToExec.
                        $Function = $CommandToExec[0]
                        $Token = $CommandToExec[1]
                        $ObfLevel = $CommandToExec[2]
                    }
                    Else {
                        # Overload above arguments if $OverrideAcceptableInput is $TRUE, and extract $Function from $BreadCrumb
                        Switch ($BreadCrumb.ToLower()) {
                            '\launcher\ps' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 1 }
                            '\launcher\cmd' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 2 }
                            '\launcher\wmic' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 3 }
                            '\launcher\rundll' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 4 }
                            '\launcher\var+' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 5 }
                            '\launcher\stdin+' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 6 }
                            '\launcher\clip+' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 7 }
                            '\launcher\var++' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 8 }
                            '\launcher\stdin++' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 9 }
                            '\launcher\clip++' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 10 }
                            '\launcher\rundll++' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 11 }
                            '\launcher\mshta++' { $Function = 'Out-PowerShellLauncher'; $ObfLevel = 12 }
                            default { Write-Error "An invalid value ($($BreadCrumb.ToLower())) was passed to switch block for setting `$Function when `$OverrideAcceptableInput -eq `$TRUE."; Exit }
                        }
                        # Extract $ObfLevel from first element in array (in case 0th element is used for informational purposes), and extract $Token from $BreadCrumb.
                        $ObfLevel = $Menu[1][3][2]
                        $Token = $UserInput.SubString($UserInput.LastIndexOf('_') + 1)
                    }

                    # Convert ObfuscatedCommand (string) to ScriptBlock for next obfuscation function.
                    If (!($Script:LauncherApplied)) {
                        $ObfCommandScriptBlock = $ExecutionContext.InvokeCommand.NewScriptBlock($Script:ObfuscatedCommand)
                    }
                    
                    # Validate that user has set SCRIPTPATH or SCRIPTBLOCK (by seeing if $Script:ObfuscatedCommand is empty).
                    If ($Script:ObfuscatedCommand -eq '') {
                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host " Cannot execute obfuscation commands without setting ScriptPath or ScriptBlock values in SHOW OPTIONS menu. Set these by executing" -NoNewLine
                        Write-Host ' SET SCRIPTBLOCK script_block_or_command' -NoNewLine -ForegroundColor Green
                        Write-Host ' or' -NoNewLine
                        Write-Host ' SET SCRIPTPATH path_to_script_or_URL' -NoNewLine -ForegroundColor Green
                        Write-Host '.'
                        Continue
                    }

                    # Save current ObfuscatedCommand to see if obfuscation was successful (i.e. no warnings prevented obfuscation from occurring).
                    $ObfuscatedCommandBefore = $Script:ObfuscatedCommand
                    $CmdToPrint = $NULL
                    If ($Function -eq 'Out-ObfuscatedAst' -AND $PSVersionTable.PSVersion.Major -lt 3) {
                        $AstPS3ErrorMessage = "AST obfuscation can only be used with PS3.0+. Update to PS3.0 or higher to use AST obfuscation."
                        If ($Script:QuietWasSpecified) {
                            Write-Error $AstPS3ErrorMessage
                        }
                        Else {
                            Write-Host "`n`nERROR: " -NoNewLine -ForegroundColor Red
                            Write-Host $AstPS3ErrorMessage -NoNewLine
                        }
                    }
                    ElseIf ($Script:LauncherApplied) {
                        If ($Function -eq 'Out-PowerShellLauncher') {
                            $ErrorMessage = ' You have already applied a launcher to ObfuscatedCommand.'
                        }
                        Else {
                            $ErrorMessage = ' You cannot obfuscate after applying a Launcher to ObfuscatedCommand.'
                        }

                        Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                        Write-Host $ErrorMessage -NoNewLine
                        Write-Host "`n       Enter" -NoNewLine
                        Write-Host ' UNDO' -NoNewLine -ForegroundColor Yellow
                        Write-Host " to remove the launcher from ObfuscatedCommand.`n" -NoNewLine
                    }
                    Else {
                        # Switch block to route to the correct function.
                        Switch ($Function) {
                            'Out-ObfuscatedTokenCommand' {
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand        -ScriptBlock $ObfCommandScriptBlock $Token $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock ", " '$Token' $ObfLevel")
                            }
                            'Out-ObfuscatedTokenCommandAll' {
                                $Script:ObfuscatedCommand = Out-ObfuscatedTokenCommand        -ScriptBlock $ObfCommandScriptBlock
                                $CmdToPrint = @("Out-ObfuscatedTokenCommand -ScriptBlock ", "")
                            }
                            'Out-ObfuscatedAst' {
                                $Script:ObfuscatedCommand = Out-ObfuscatedAst                 -ScriptBlock $ObfCommandScriptBlock -AstTypesToObfuscate $Token
                                $CmdToPrint = @("Out-ObfuscatedAst -ScriptBlock ", "")
                            }
                            'Out-ObfuscatedStringCommand' {
                                $Script:ObfuscatedCommand = Out-ObfuscatedStringCommand       -ScriptBlock $ObfCommandScriptBlock $ObfLevel
                                $CmdToPrint = @("Out-ObfuscatedStringCommand -ScriptBlock ", " $ObfLevel")
                            }
                            'Out-EncodedAsciiCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedAsciiCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedAsciiCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedHexCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedHexCommand             -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedHexCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedOctalCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedOctalCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedOctalCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedBinaryCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedBinaryCommand          -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedBinaryCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-SecureStringCommand' {
                                $Script:ObfuscatedCommand = Out-SecureStringCommand           -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-SecureStringCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedBXORCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedBXORCommand            -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedBXORCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedSpecialCharOnlyCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedSpecialCharOnlyCommand -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedSpecialCharOnlyCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-EncodedWhitespaceCommand' {
                                $Script:ObfuscatedCommand = Out-EncodedWhitespaceCommand      -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-EncodedWhitespaceCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-CompressedCommand' {
                                $Script:ObfuscatedCommand = Out-CompressedCommand             -ScriptBlock $ObfCommandScriptBlock -PassThru
                                $CmdToPrint = @("Out-CompressedCommand -ScriptBlock ", " -PassThru")
                            }
                            'Out-PowerShellLauncher' {
                                # Extract numbers from string so we can output proper flag syntax in ExecutionCommands history.
                                $SwitchesAsStringArray = [char[]]$Token | Sort-Object -Unique | Where-Object { $_ -ne ' ' }
                                
                                If ($SwitchesAsStringArray -Contains '0') {
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock ", " $ObfLevel")
                                }
                                Else {
                                    $HasWindowStyle = $FALSE
                                    $SwitchesToPrint = @()
                                    ForEach ($Value in $SwitchesAsStringArray) {
                                        Switch ($Value) {
                                            1 { $SwitchesToPrint += '-NoExit' }
                                            2 { $SwitchesToPrint += '-NonInteractive' }
                                            3 { $SwitchesToPrint += '-NoLogo' }
                                            4 { $SwitchesToPrint += '-NoProfile' }
                                            5 { $SwitchesToPrint += '-Command' }
                                            6 { If (!$HasWindowStyle) { $SwitchesToPrint += '-WindowStyle Hidden'; $HasWindowStyle = $TRUE } }
                                            7 { $SwitchesToPrint += '-ExecutionPolicy Bypass' }
                                            8 { $SwitchesToPrint += '-Wow64' }
                                            default { Write-Error "An invalid `$SwitchesAsString value ($Value) was passed to switch block."; Exit; }
                                        }
                                    }
                                    $SwitchesToPrint = $SwitchesToPrint -Join ' '
                                    $CmdToPrint = @("Out-PowerShellLauncher -ScriptBlock ", " $SwitchesToPrint $ObfLevel")
                                }
                                
                                $Script:ObfuscatedCommand = Out-PowerShellLauncher -ScriptBlock $ObfCommandScriptBlock -SwitchesAsString $Token $ObfLevel
                                
                                # Only set LauncherApplied to true if before/after are different (i.e. no warnings prevented launcher from being applied).
                                If ($ObfuscatedCommandBefore -ne $Script:ObfuscatedCommand) {
                                    $Script:LauncherApplied = $TRUE
                                }
                            }
                            default { Write-Error "An invalid `$Function value ($Function) was passed to switch block."; Exit; }
                        }

                        If (($Script:ObfuscatedCommand -ceq $ObfuscatedCommandBefore) -AND ($MenuName.StartsWith('_Token_'))) {
                            Write-Host "`nWARNING:" -NoNewLine -ForegroundColor Red
                            Write-Host " There were not any" -NoNewLine
                            If ($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\') + 1).ToLower() -ne 'all') { Write-Host " $($BreadCrumb.SubString($BreadCrumb.LastIndexOf('\')+1))" -NoNewLine -ForegroundColor Yellow }
                            Write-Host " tokens to further obfuscate, so nothing changed."
                        }
                        Else {
                            # Add to $Script:ObfuscatedCommandHistory if a change took place for the current ObfuscatedCommand.
                            $Script:ObfuscatedCommandHistory += , $Script:ObfuscatedCommand
    
                            # Convert UserInput to CLI syntax to store in CliSyntax variable if obfuscation occurred.
                            $CliSyntaxCurrentCommand = $UserInput.Trim('_ ').Replace('_', '\')
    
                            # Add CLI command syntax to $Script:CliSyntax to maintain a history of commands to arrive at current obfuscated command for CLI syntax.
                            $Script:CliSyntax += $CliSyntaxCurrentCommand

                            # Add execution syntax to $Script:ExecutionCommands to maintain a history of commands to arrive at current obfuscated command.
                            $Script:ExecutionCommands += ($CmdToPrint[0] + '$ScriptBlock' + $CmdToPrint[1])

                            # Output syntax of CLI syntax and full command we executed in above Switch block.
                            Write-Host "`nExecuted:`t"
                            Write-Host "  CLI:  " -NoNewline
                            Write-Host $CliSyntaxCurrentCommand -ForegroundColor Cyan
                            Write-Host "  FULL: " -NoNewline
                            Write-Host $CmdToPrint[0] -NoNewLine -ForegroundColor Cyan
                            Write-Host '$ScriptBlock' -NoNewLine -ForegroundColor Magenta
                            Write-Host $CmdToPrint[1] -ForegroundColor Cyan

                            # Output obfuscation result.
                            Write-Host "`nResult:`t"
                            Out-ScriptContents $Script:ObfuscatedCommand -PrintWarning
                        }
                    }
                }
            }
            Else {
                Return $UserInput
            }
        }
        Else {
            If ($MenuInputOptionsShowHelp[0] -Contains $UserInput) { Show-HelpMenu }
            ElseIf ($MenuInputOptionsShowOptions[0] -Contains $UserInput) { Show-OptionsMenu }
            ElseIf ($TutorialInputOptions[0] -Contains $UserInput) { Show-Tutorial }
            ElseIf ($ClearScreenInputOptions[0] -Contains $UserInput) { Clear-Host }
            # For Version 1.0 ASCII art is not necessary.
            #ElseIf($ShowAsciiArtInputOptions[0]     -Contains $UserInput) {Show-AsciiArt -Random}
            ElseIf ($ResetObfuscationInputOptions[0] -Contains $UserInput) {
                If (($Script:ObfuscatedCommand -ne $NULL) -AND ($Script:ObfuscatedCommand.Length -eq 0)) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand has not been set. There is nothing to reset."
                }
                ElseIf ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " No obfuscation has been applied to ObfuscatedCommand. There is nothing to reset."
                }
                Else {
                    $Script:LauncherApplied = $FALSE
                    $Script:ObfuscatedCommand = $Script:ScriptBlock
                    $Script:ObfuscatedCommandHistory = @($Script:ScriptBlock)
                    $Script:CliSyntax = @()
                    $Script:ExecutionCommands = @()
                    
                    Write-Host "`n`nSuccessfully reset ObfuscatedCommand." -ForegroundColor Cyan
                }
            }
            ElseIf ($UndoObfuscationInputOptions[0] -Contains $UserInput) {
                If (($Script:ObfuscatedCommand -ne $NULL) -AND ($Script:ObfuscatedCommand.Length -eq 0)) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " ObfuscatedCommand has not been set. There is nothing to undo."
                }
                ElseIf ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " No obfuscation has been applied to ObfuscatedCommand. There is nothing to undo."
                }
                Else {
                    # Set ObfuscatedCommand to the last state in ObfuscatedCommandHistory.
                    $Script:ObfuscatedCommand = $Script:ObfuscatedCommandHistory[$Script:ObfuscatedCommandHistory.Count - 2]

                    # Remove the last state from ObfuscatedCommandHistory.
                    $Temp = $Script:ObfuscatedCommandHistory
                    $Script:ObfuscatedCommandHistory = @()
                    For ($i = 0; $i -lt $Temp.Count - 1; $i++) {
                        $Script:ObfuscatedCommandHistory += $Temp[$i]
                    }

                    # Remove last command from CliSyntax. Trim all trailing OUT or CLIP commands until an obfuscation command is removed.
                    $CliSyntaxCount = $Script:CliSyntax.Count
                    While (($Script:CliSyntax[$CliSyntaxCount - 1] -Match '^(clip|out )') -AND ($CliSyntaxCount -gt 0)) {
                        $CliSyntaxCount--
                    }
                    $Temp = $Script:CliSyntax
                    $Script:CliSyntax = @()
                    For ($i = 0; $i -lt $CliSyntaxCount - 1; $i++) {
                        $Script:CliSyntax += $Temp[$i]
                    }

                    # Remove last command from ExecutionCommands.
                    $Temp = $Script:ExecutionCommands
                    $Script:ExecutionCommands = @()
                    For ($i = 0; $i -lt $Temp.Count - 1; $i++) {
                        $Script:ExecutionCommands += $Temp[$i]
                    }

                    # If this is removing a launcher then we must change the launcher state so we can continue obfuscating.
                    If ($Script:LauncherApplied) {
                        $Script:LauncherApplied = $FALSE
                        Write-Host "`n`nSuccessfully removed launcher from ObfuscatedCommand." -ForegroundColor Cyan
                    }
                    Else {
                        Write-Host "`n`nSuccessfully removed last obfuscation from ObfuscatedCommand." -ForegroundColor Cyan
                    }
                }
            }
            ElseIf (($OutputToDiskInputOptions[0] -Contains $UserInput) -OR ($OutputToDiskInputOptions[0] -Contains $UserInput.Trim().Split(' ')[0])) {
                If (($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock)) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " You haven't applied any obfuscation.`n         Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
                ElseIf ($Script:ObfuscatedCommand -ne '') {
                    # Get file path information from compound user input (e.g. OUT C:\FILENAME.TXT).
                    If ($UserInput.Trim().Split(' ').Count -gt 1) {
                        # Get file path information from user input.
                        $UserInputOutputFilePath = $UserInput.Trim().SubString(4).Trim()
                        Write-Host ''
                    }
                    Else {
                        # Get file path information from user interactively.
                        $UserInputOutputFilePath = Read-Host "`n`nEnter path for output file (or leave blank for default)"
                    }                    
                    # Decipher if user input a full file path, just a file name or nothing (default).
                    If ($UserInputOutputFilePath.Trim() -eq '') {
                        # User did not input anything so use default filename and current directory of this script.
                        $OutputFilePath = "$ScriptDir\Obfuscated_Command.txt"
                    }
                    ElseIf (!($UserInputOutputFilePath.Contains('\')) -AND !($UserInputOutputFilePath.Contains('/'))) {
                        # User input is not a file path so treat it as a filename and use current directory of this script.
                        $OutputFilePath = "$ScriptDir\$($UserInputOutputFilePath.Trim())"
                    }
                    Else {
                        # User input is a full file path.
                        $OutputFilePath = $UserInputOutputFilePath
                    }
                    
                    # Write ObfuscatedCommand out to disk.
                    Write-Output $Script:ObfuscatedCommand > $OutputFilePath

                    If ($Script:LauncherApplied -AND (Test-Path $OutputFilePath)) {
                        $Script:CliSyntax += "out $OutputFilePath"
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host ".`nA Launcher has been applied so this script cannot be run as a standalone .ps1 file." -ForegroundColor Cyan
                        If ($Env:windir) { C:\Windows\Notepad.exe $OutputFilePath }
                    }
                    ElseIf (!$Script:LauncherApplied -AND (Test-Path $OutputFilePath)) {
                        $Script:CliSyntax += "out $OutputFilePath"
                        Write-Host "`nSuccessfully output ObfuscatedCommand to" -NoNewLine -ForegroundColor Cyan
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                        Write-Host "." -ForegroundColor Cyan
                        If ($Env:windir) { C:\Windows\Notepad.exe $OutputFilePath }
                    }
                    Else {
                        Write-Host "`nERROR: Unable to write ObfuscatedCommand out to" -NoNewLine -ForegroundColor Red
                        Write-Host " $OutputFilePath" -NoNewLine -ForegroundColor Yellow
                    }
                }
                ElseIf ($Script:ObfuscatedCommand -eq '') {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " There isn't anything to write out to disk.`n       Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
            }
            ElseIf ($CopyToClipboardInputOptions[0] -Contains $UserInput) {
                If (($Script:ObfuscatedCommand -ne '') -AND ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock)) {
                    Write-Host "`n`nWARNING:" -NoNewLine -ForegroundColor Red
                    Write-Host " You haven't applied any obfuscation.`n         Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand."
                }
                ElseIf ($Script:ObfuscatedCommand -ne '') {
                    # Copy ObfuscatedCommand to clipboard.
                    # Try-Catch block introduced since PowerShell v2.0 without -STA defined will not be able to perform clipboard functionality.
                    Try {
                        $Null = [Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
                        [Windows.Forms.Clipboard]::SetText($Script:ObfuscatedCommand)

                        If ($Script:LauncherApplied) {
                            Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard." -ForegroundColor Cyan
                        }
                        Else {
                            Write-Host "`n`nSuccessfully copied ObfuscatedCommand to clipboard.`nNo Launcher has been applied, so command can only be pasted into powershell.exe." -ForegroundColor Cyan
                        }
                    }
                    Catch {
                        $ErrorMessage = "Clipboard functionality will not work in PowerShell version $($PsVersionTable.PsVersion.Major) unless you add -STA (Single-Threaded Apartment) execution flag to powershell.exe."

                        If ((Get-Command Write-Host).CommandType -ne 'Cmdlet') {
                            # Retrieving Write-Host and Start-Sleep Cmdlets to get around the current proxy functions of Write-Host and Start-Sleep that are overloaded if -Quiet flag was used.
                            . ((Get-Command Write-Host) | Where-Object { $_.CommandType -eq 'Cmdlet' }) "`n`nWARNING: " -NoNewLine -ForegroundColor Red
                            . ((Get-Command Write-Host) | Where-Object { $_.CommandType -eq 'Cmdlet' }) $ErrorMessage -NoNewLine

                            . ((Get-Command Start-Sleep) | Where-Object { $_.CommandType -eq 'Cmdlet' }) 2
                        }
                        Else {
                            Write-Host "`n`nWARNING: " -NoNewLine -ForegroundColor Red
                            Write-Host $ErrorMessage

                            If ($Script:CliSyntax -gt 0) { Start-Sleep 2 }
                        }
                    }
                    
                    $Script:CliSyntax += 'clip'
                }
                ElseIf ($Script:ObfuscatedCommand -eq '') {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " There isn't anything to copy to your clipboard.`n       Just enter" -NoNewLine
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " and look at ObfuscatedCommand." -NoNewLine
                }
                
            }
            ElseIf ($ExecutionInputOptions[0] -Contains $UserInput) {
                If ($Script:LauncherApplied) {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " Cannot execute because you have applied a Launcher.`n       Enter" -NoNewLine
                    Write-Host " COPY" -NoNewLine -ForeGroundColor Yellow
                    Write-Host "/" -NoNewLine
                    Write-Host "CLIP" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " and paste into cmd.exe.`n       Or enter" -NoNewLine
                    Write-Host " UNDO" -NoNewLine -ForeGroundColor Yellow
                    Write-Host " to remove the Launcher from ObfuscatedCommand."
                }
                ElseIf ($Script:ObfuscatedCommand -ne '') {
                    If ($Script:ObfuscatedCommand -ceq $Script:ScriptBlock) { Write-Host "`n`nInvoking (though you haven't obfuscated anything yet):" }
                    Else { Write-Host "`n`nInvoking:" }
                    
                    Out-ScriptContents $Script:ObfuscatedCommand
                    Write-Host ''
                    $null = Invoke-Expression $Script:ObfuscatedCommand
                }
                Else {
                    Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                    Write-Host " Cannot execute because you have not set ScriptPath or ScriptBlock.`n       Enter" -NoNewline
                    Write-Host " SHOW OPTIONS" -NoNewLine -ForegroundColor Yellow
                    Write-Host " to set ScriptPath or ScriptBlock."
                }
            }
            Else {
                Write-Host "`n`nERROR:" -NoNewLine -ForegroundColor Red
                Write-Host " You entered an invalid option. Enter" -NoNewLine
                Write-Host " HELP" -NoNewLine -ForegroundColor Yellow
                Write-Host " for more information."

                # If the failed input was part of $Script:CompoundCommand then cancel out the rest of the compound command so it is not further processed.
                If ($Script:CompoundCommand.Count -gt 0) {
                    $Script:CompoundCommand = @()
                }

                # Output all available/acceptable options for current menu if invalid input was entered.
                If ($AcceptableInput.Count -gt 1) {
                    $Message = 'Valid options for current menu include:'
                }
                Else {
                    $Message = 'Valid option for current menu includes:'
                }
                Write-Host "       $Message " -NoNewLine

                $Counter = 0
                ForEach ($AcceptableOption in $AcceptableInput) {
                    $Counter++

                    # Change color and verbiage if acceptable options will execute an obfuscation function.
                    If ($SelectionContainsCommand) {
                        $ColorToOutput = 'Green'
                    }
                    Else {
                        $ColorToOutput = 'Yellow'
                    }

                    Write-Host $AcceptableOption -NoNewLine -ForegroundColor $ColorToOutput
                    If (($Counter -lt $AcceptableInput.Length) -AND ($AcceptableOption.Length -gt 0)) {
                        Write-Host ', ' -NoNewLine
                    }
                }
                Write-Host ''
            }
        }
    }
    
    Return $UserInput.ToLower()
}