Function Show-HelpMenu {
    <#
.SYNOPSIS

HELPER FUNCTION :: Displays help menu for Invoke-Obfuscation.

Invoke-Obfuscation Function: Show-HelpMenu
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Show-HelpMenu displays help menu for Invoke-Obfuscation.

.EXAMPLE

C:\PS> Show-HelpMenu

.NOTES

This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    # Show Help Menu.
    Write-Host "`n`nHELP MENU" -NoNewLine -ForegroundColor Cyan
    Write-Host " :: Available" -NoNewLine
    Write-Host " options" -NoNewLine -ForegroundColor Yellow
    Write-Host " shown below:`n"
    ForEach ($InputOptionsList in $AllAvailableInputOptionsLists) {
        $InputOptionsCommands = $InputOptionsList[0]
        $InputOptionsDescription = $InputOptionsList[1]

        # Add additional coloring to string encapsulated by <> if it exists in $InputOptionsDescription.
        If ($InputOptionsDescription.Contains('<') -AND $InputOptionsDescription.Contains('>')) {
            $FirstPart = $InputOptionsDescription.SubString(0, $InputOptionsDescription.IndexOf('<'))
            $MiddlePart = $InputOptionsDescription.SubString($FirstPart.Length + 1)
            $MiddlePart = $MiddlePart.SubString(0, $MiddlePart.IndexOf('>'))
            $LastPart = $InputOptionsDescription.SubString($FirstPart.Length + $MiddlePart.Length + 2)
            Write-Host "$LineSpacing $FirstPart" -NoNewLine
            Write-Host $MiddlePart -NoNewLine -ForegroundColor Cyan
            Write-Host $LastPart -NoNewLine
        }
        Else {
            Write-Host "$LineSpacing $InputOptionsDescription" -NoNewLine
        }
        
        $Counter = 0
        ForEach ($Command in $InputOptionsCommands) {
            $Counter++
            Write-Host $Command.ToUpper() -NoNewLine -ForegroundColor Yellow
            If ($Counter -lt $InputOptionsCommands.Count) { Write-Host ',' -NoNewLine }
        }
        Write-Host ''
    }
}