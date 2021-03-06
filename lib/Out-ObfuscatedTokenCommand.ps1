
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.



Function Out-ObfuscatedTokenCommand {
    <#
.SYNOPSIS

Master function that orchestrates the tokenization and application of all token-based obfuscation functions to provided PowerShell script.

Invoke-Obfuscation Function: Out-ObfuscatedTokenCommand
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: None
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedTokenCommand orchestrates the tokenization and application of all token-based obfuscation functions to provided PowerShell script and places obfuscated tokens back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. If no $TokenTypeToObfuscate is defined then Out-ObfuscatedTokenCommand will automatically perform ALL token obfuscation functions in random order at the highest obfuscation level.

.PARAMETER ScriptBlock

Specifies a scriptblock containing your payload.

.PARAMETER Path

Specifies the path to your payload.

.PARAMETER TokenTypeToObfuscate

(Optional) Specifies the token type to obfuscate ('Command', 'CommandArgument', 'Comment', 'Member', 'String', 'Type', 'Variable', 'RandomWhitespace'). If not defined then Out-ObfuscatedTokenCommand will automatically perform ALL token obfuscation functions in random order at the highest obfuscation level.

.PARAMETER ObfuscationLevel

(Optional) Specifies the obfuscation level for the given TokenTypeToObfuscate. If not defined then Out-ObfuscatedTokenCommand will automatically perform obfuscation function at the highest available obfuscation level. 
Each token has different available obfuscation levels:
'Argument' 1-4
'Command' 1-3
'Comment' 1
'Member' 1-4
'String' 1-2
'Type' 1-2
'Variable' 1
'Whitespace' 1
'All' 1

.EXAMPLE

C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green}

.(  "{0}{2}{1}" -f'Write','t','-Hos'  ) ( 'Hell' + 'o '  +'Wor'+  'ld!'  ) -ForegroundColor (  "{1}{0}" -f 'een','Gr') ;    .(  "{1}{2}{0}"-f'ost','Writ','e-H' ) (  'O' + 'bfusca'+  't' +  'ion Rocks'  + '!') -ForegroundColor (  "{1}{0}"-f'een','Gr' )

.NOTES

Out-ObfuscatedTokenCommand orchestrates the tokenization and application of all token-based obfuscation functions to provided PowerShell script and places obfuscated tokens back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. If no $TokenTypeToObfuscate is defined then Out-ObfuscatedTokenCommand will automatically perform ALL token obfuscation functions in random order at the highest obfuscation level.
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding( DefaultParameterSetName = 'FilePath')] Param (
        [Parameter(Position = 0, ValueFromPipeline = $True, ParameterSetName = 'ScriptBlock')]
        [ValidateNotNullOrEmpty()]
        [ScriptBlock]
        $ScriptBlock,

        [Parameter(Position = 0, ParameterSetName = 'FilePath')]
        [ValidateNotNullOrEmpty()]
        [String]
        $Path,

        [ValidateSet('Member', 'Command', 'CommandArgument', 'String', 'Variable', 'Type', 'RandomWhitespace', 'Comment')]
        [Parameter(Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $TokenTypeToObfuscate,

        [Parameter(Position = 2)]
        [ValidateNotNullOrEmpty()]
        [Int]
        $ObfuscationLevel = 10 # Default to highest obfuscation level if $ObfuscationLevel isn't defined
    )

    # Either convert ScriptBlock to a String or convert script at $Path to a String.
    If ($PSBoundParameters['Path']) {
        Get-ChildItem $Path -ErrorAction Stop | Out-Null
        $ScriptString = [IO.File]::ReadAllText((Resolve-Path $Path))
    }
    Else {
        $ScriptString = [String]$ScriptBlock
    }
    
    # If $TokenTypeToObfuscate was not defined then we will automate randomly calling all available obfuscation functions in Out-ObfuscatedTokenCommand.
    If ($TokenTypeToObfuscate.Length -eq 0) {
        # All available obfuscation token types (minus 'String') currently supported in Out-ObfuscatedTokenCommand.
        # 'Comment' and 'String' will be manually added first and second respectively for reasons defined below.
        # 'RandomWhitespace' will be manually added last for reasons defined below.
        $ObfuscationChoices = @()
        $ObfuscationChoices += 'Member'
        $ObfuscationChoices += 'Command'
        $ObfuscationChoices += 'CommandArgument'
        $ObfuscationChoices += 'Variable'
        $ObfuscationChoices += 'Type'
        
        # Create new array with 'String' plus all obfuscation types above in random order. 
        $ObfuscationTypeOrder = @()
        # Run 'Comment' first since it will be the least number of tokens to iterate through, and comments may be introduced as obfuscation technique in future revisions.
        $ObfuscationTypeOrder += 'Comment'
        # Run 'String' second since otherwise we will have unnecessary command bloat since other obfuscation functions create additional strings.
        $ObfuscationTypeOrder += 'String'
        $ObfuscationTypeOrder += (Get-Random -Input $ObfuscationChoices -Count $ObfuscationChoices.Count)

        # Apply each randomly-ordered $ObfuscationType from above step.
        ForEach ($ObfuscationType in $ObfuscationTypeOrder) {
            $ScriptString = Out-ObfuscatedTokenCommand ([ScriptBlock]::Create($ScriptString)) $ObfuscationType $ObfuscationLevel
        }
        Return $ScriptString
    }

    # Parse out and obfuscate tokens (in reverse to make indexes simpler for adding in obfuscated tokens).
    $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString, [ref]$null)
    
    # Handle fringe case of retrieving count of all tokens used when applying random whitespace.
    $TokenCount = ([System.Management.Automation.PSParser]::Tokenize($ScriptString, [ref]$null) | Where-Object { $_.Type -eq $TokenTypeToObfuscate }).Count
    $TokensForInsertingWhitespace = @('Operator', 'GroupStart', 'GroupEnd', 'StatementSeparator')

    # Script-wide variable ($Script:TypeTokenScriptStringGrowth) to speed up Type token obfuscation by avoiding having to re-tokenize ScriptString for every token.
    # This is because we are appending variable instantiation at the beginning of each iteration of ScriptString.
    # Additional script-wide variable ($Script:TypeTokenVariableArray) allows each unique Type token to only be set once per command/script for efficiency and to create less items to create indicators off of.
    $Script:TypeTokenScriptStringGrowth = 0
    $Script:TypeTokenVariableArray = @()
    
    If ($TokenTypeToObfuscate -eq 'RandomWhitespace') {
        # If $TokenTypeToObfuscate='RandomWhitespace' then calculate $TokenCount for output by adding token count for all tokens in $TokensForInsertingWhitespace.
        $TokenCount = 0
        ForEach ($TokenForInsertingWhitespace in $TokensForInsertingWhitespace) {
            $TokenCount += ([System.Management.Automation.PSParser]::Tokenize($ScriptString, [ref]$null) | Where-Object { $_.Type -eq $TokenForInsertingWhitespace }).Count
        }
    }

    # Handle fringe case of outputting verbiage consistent with options presented in Invoke-Obfuscation.
    If ($TokenCount -gt 0) {
        # To be consistent with verbiage in Invoke-Obfuscation we will print Argument/Whitespace instead of CommandArgument/RandomWhitespace.
        $TokenTypeToObfuscateToPrint = $TokenTypeToObfuscate
        If ($TokenTypeToObfuscateToPrint -eq 'CommandArgument') { $TokenTypeToObfuscateToPrint = 'Argument' }
        If ($TokenTypeToObfuscateToPrint -eq 'RandomWhitespace') { $TokenTypeToObfuscateToPrint = 'Whitespace' }
        If ($TokenCount -gt 1) { $Plural = 's' }
        Else { $Plural = '' }

        # Output verbiage concerning which $TokenType is currently being obfuscated and how many tokens of each type are left to obfuscate.
        # This becomes more important when obfuscated large scripts where obfuscation can take several minutes due to all of the randomization steps.
        Write-Host "`n[*] Obfuscating $($TokenCount)" -NoNewLine
        Write-Host " $TokenTypeToObfuscateToPrint" -NoNewLine -ForegroundColor Yellow
        Write-Host " token$Plural."
    }

    # Variables for outputting status of token processing for large token counts when obfuscating large scripts.
    $Counter = $TokenCount
    $OutputCount = 0
    $IterationsToOutputOn = 100
    $DifferenceForEvenOutput = $TokenCount % $IterationsToOutputOn
    
    For ($i = $Tokens.Count - 1; $i -ge 0; $i--) {
        $Token = $Tokens[$i]

        # Extra output for large scripts with several thousands tokens (like Invoke-Mimikatz).
        If (($TokenCount -gt $IterationsToOutputOn * 2) -AND ((($TokenCount - $Counter) - ($OutputCount * $IterationsToOutputOn)) -eq ($IterationsToOutputOn + $DifferenceForEvenOutput))) {
            $OutputCount++
            $ExtraWhitespace = ' ' * (([String]($TokenCount)).Length - ([String]$Counter).Length)
            If ($Counter -gt 0) {
                Write-Host "[*]             $ExtraWhitespace$Counter" -NoNewLine
                Write-Host " $TokenTypeToObfuscateToPrint" -NoNewLine -ForegroundColor Yellow
                Write-Host " tokens remaining to obfuscate."
            }
        }

        $ObfuscatedToken = ""

        If (($Token.Type -eq 'String') -AND ($TokenTypeToObfuscate.ToLower() -eq 'string')) {
            $Counter--

            # If String $Token immediately follows a period (and does not begin $ScriptString) then do not obfuscate as a String.
            # In this scenario $Token is originally a Member token that has quotes added to it.
            # E.g. both InvokeCommand and InvokeScript in $ExecutionContext.InvokeCommand.InvokeScript
            If (($Token.Start -gt 0) -AND ($ScriptString.SubString($Token.Start - 1, 1) -eq '.')) {
                Continue
            }
            
            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1, 2)

            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 }  

            # The below Parameter Binding Validation Attributes cannot have their string values formatted with the -f format operator unless treated as a scriptblock.
            # When we find strings following these Parameter Binding Validation Attributes then if we are using a -f format operator we will treat the result as a scriptblock.
            # Source: https://technet.microsoft.com/en-us/library/hh847743.aspx
            $ParameterValidationAttributesToTreatStringAsScriptblock = @()
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'alias'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'allownull'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'allowemptystring'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'allowemptycollection'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatecount'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatelength'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatepattern'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validaterange'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatescript'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validateset'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatenotnull'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'validatenotnullorempty'

            $ParameterValidationAttributesToTreatStringAsScriptblock += 'helpmessage'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'outputtype'
            $ParameterValidationAttributesToTreatStringAsScriptblock += 'diagnostics.codeanalysis.suppressmessageattribute'

            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-ObfuscatedStringTokenLevel1 $ScriptString $Token 1 }
                2 { $ScriptString = Out-ObfuscatedStringTokenLevel1 $ScriptString $Token 2 }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }

        }
        ElseIf (($Token.Type -eq 'Member') -AND ($TokenTypeToObfuscate.ToLower() -eq 'member')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1, 2, 3, 4)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 }

            # The below Parameter Attributes cannot be obfuscated like other Member Tokens, so we will only randomize the case of these tokens.
            # Source 1: https://technet.microsoft.com/en-us/library/hh847743.aspx
            $MemberTokensToOnlyRandomCase = @()
            $MemberTokensToOnlyRandomCase += 'mandatory'
            $MemberTokensToOnlyRandomCase += 'position'
            $MemberTokensToOnlyRandomCase += 'parametersetname'
            $MemberTokensToOnlyRandomCase += 'valuefrompipeline'
            $MemberTokensToOnlyRandomCase += 'valuefrompipelinebypropertyname'
            $MemberTokensToOnlyRandomCase += 'valuefromremainingarguments'
            $MemberTokensToOnlyRandomCase += 'helpmessage'
            $MemberTokensToOnlyRandomCase += 'alias'
            # Source 2: https://technet.microsoft.com/en-us/library/hh847872.aspx
            $MemberTokensToOnlyRandomCase += 'confirmimpact'
            $MemberTokensToOnlyRandomCase += 'defaultparametersetname'
            $MemberTokensToOnlyRandomCase += 'helpuri'
            $MemberTokensToOnlyRandomCase += 'supportspaging'
            $MemberTokensToOnlyRandomCase += 'supportsshouldprocess'
            $MemberTokensToOnlyRandomCase += 'positionalbinding'

            $MemberTokensToOnlyRandomCase += 'ignorecase'

            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-RandomCaseToken             $ScriptString $Token }
                2 { $ScriptString = Out-ObfuscatedWithTicks         $ScriptString $Token }
                3 { $ScriptString = Out-ObfuscatedMemberTokenLevel3 $ScriptString $Tokens $i 1 }
                4 { $ScriptString = Out-ObfuscatedMemberTokenLevel3 $ScriptString $Tokens $i 2 }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($Token.Type -eq 'CommandArgument') -AND ($TokenTypeToObfuscate.ToLower() -eq 'commandargument')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1, 2, 3, 4)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 } 
            
            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-RandomCaseToken                      $ScriptString $Token }
                2 { $ScriptString = Out-ObfuscatedWithTicks                  $ScriptString $Token }
                3 { $ScriptString = Out-ObfuscatedCommandArgumentTokenLevel3 $ScriptString $Token 1 }
                4 { $ScriptString = Out-ObfuscatedCommandArgumentTokenLevel3 $ScriptString $Token 2 }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($Token.Type -eq 'Command') -AND ($TokenTypeToObfuscate.ToLower() -eq 'command')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1, 2, 3)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 }

            # If a variable is encapsulated in curly braces (e.g. ${ExecutionContext}) then the string inside is treated as a Command token.
            # So we will force tick obfuscation (option 1) instead of splatting (option 2) as that would cause errors.
            If (($Token.Start -gt 1) -AND ($ScriptString.SubString($Token.Start - 1, 1) -eq '{') -AND ($ScriptString.SubString($Token.Start + $Token.Length, 1) -eq '}')) {
                $ObfuscationLevel = 1
            }
            
            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-ObfuscatedWithTicks          $ScriptString $Token }
                2 { $ScriptString = Out-ObfuscatedCommandTokenLevel2 $ScriptString $Token 1 }
                3 { $ScriptString = Out-ObfuscatedCommandTokenLevel2 $ScriptString $Token 2 }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($Token.Type -eq 'Variable') -AND ($TokenTypeToObfuscate.ToLower() -eq 'variable')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 } 

            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-ObfuscatedVariableTokenLevel1 $ScriptString $Token }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($Token.Type -eq 'Type') -AND ($TokenTypeToObfuscate.ToLower() -eq 'type')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1, 2)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 } 

            # The below Type value substrings are part of Types that cannot be direct Type casted, so we will not perform direct Type casting on Types containing these values.
            $TypesThatCannotByDirectTypeCasted = @()
            $TypesThatCannotByDirectTypeCasted += 'directoryservices.accountmanagement.'
            $TypesThatCannotByDirectTypeCasted += 'windows.clipboard'

            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-ObfuscatedTypeToken $ScriptString $Token 1 }
                2 { $ScriptString = Out-ObfuscatedTypeToken $ScriptString $Token 2 }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($TokensForInsertingWhitespace -Contains $Token.Type) -AND ($TokenTypeToObfuscate.ToLower() -eq 'randomwhitespace')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 } 

            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-RandomWhitespace $ScriptString $Tokens $i }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }
        ElseIf (($Token.Type -eq 'Comment') -AND ($TokenTypeToObfuscate.ToLower() -eq 'comment')) {
            $Counter--

            # Set valid obfuscation levels for current token type.
            $ValidObfuscationLevels = @(0, 1)
            
            # If invalid obfuscation level is passed to this function then default to highest obfuscation level available for current token type.
            If ($ValidObfuscationLevels -NotContains $ObfuscationLevel) { $ObfuscationLevel = $ValidObfuscationLevels | Sort-Object -Descending | Select-Object -First 1 } 
            
            Switch ($ObfuscationLevel) {
                0 { Continue }
                1 { $ScriptString = Out-RemoveComments $ScriptString $Token }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for token type $($Token.Type)."; Exit; }
            }
        }    
    }

    Return $ScriptString
}
