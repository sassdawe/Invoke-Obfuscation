

Function Out-ObfuscatedStringTokenLevel1 {
    <#
.SYNOPSIS

Obfuscates string token by randomly concatenating the string in-line.

Invoke-Obfuscation Function: Out-ObfuscatedStringTokenLevel1
Author: David Sass (@sassdawe)
License: Apache License, Version 2.0
Required Dependencies: Out-StringDelimitedAndConcatenated, Out-StringDelimitedConcatenatedAndReordered (both located in Out-ObfuscatedStringCommand.ps1)
Optional Dependencies: None
 
.DESCRIPTION

Out-ObfuscatedStringTokenLevel1 obfuscates a given string token and places it back into the provided PowerShell script to evade detection by simple IOCs and process execution monitoring relying solely on command-line arguments. For the most complete obfuscation all tokens in a given PowerShell script or script block (cast as a string object) should be obfuscated via the corresponding obfuscation functions and desired obfuscation levels in Out-ObfuscatedTokenCommand.ps1.

.PARAMETER ScriptString

Specifies the string containing your payload.

.PARAMETER Token

Specifies the token to obfuscate.

.PARAMETER ObfuscationLevel

Specifies whether to 1) Concatenate or 2) Reorder the String token value.

.EXAMPLE

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'String'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedStringTokenLevel1 $ScriptString $Token 1}
C:\PS> $ScriptString

Write-Host ('Hello'+' W'+'orl'+'d!') -ForegroundColor Green; Write-Host ('Obfuscation R'+'oc'+'k'+'s'+'!') -ForegroundColor Green

C:\PS> $ScriptString = "Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green"
C:\PS> $Tokens = [System.Management.Automation.PSParser]::Tokenize($ScriptString,[ref]$null) | Where-Object {$_.Type -eq 'String'}
C:\PS> For($i=$Tokens.Count-1; $i -ge 0; $i--) {$Token = $Tokens[$i]; $ScriptString = Out-ObfuscatedStringTokenLevel1 $ScriptString $Token 2}
C:\PS> $ScriptString

Write-Host ("{2}{3}{0}{1}" -f 'Wo','rld!','Hel','lo ') -ForegroundColor Green; Write-Host ("{4}{0}{3}{2}{1}"-f 'bfusca','cks!','Ro','tion ','O') -ForegroundColor Green

.NOTES

This cmdlet is most easily used by passing a script block or file path to a PowerShell script into the Out-ObfuscatedTokenCommand function with the corresponding token type and obfuscation level since Out-ObfuscatedTokenCommand will handle token parsing, reverse iterating and passing tokens into this current function.
C:\PS> Out-ObfuscatedTokenCommand {Write-Host 'Hello World!' -ForegroundColor Green; Write-Host 'Obfuscation Rocks!' -ForegroundColor Green} 'String' 1
This is a personal project developed by Daniel Bohannon while an employee at MANDIANT, A FireEye Company.

.LINK

http://www.danielbohannon.com
#>

    [CmdletBinding()] Param (
        [Parameter(Position = 0, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ScriptString,

        [Parameter(Position = 1, Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSToken]
        $Token,

        [Parameter(Position = 2, Mandatory = $True)]
        [ValidateSet(1, 2)]
        [Int]
        $ObfuscationLevel
    )

    $EncapsulateAsScriptBlockInsteadOfParentheses = $FALSE

    # Extract substring to look for parameter binding values to check against $ParameterValidationAttributesToTreatStringAsScriptblock set in the beginning of this script.
    $SubStringLength = 25
    If ($Token.Start -lt $SubStringLength) {
        $SubStringLength = $Token.Start
    }
    $SubString = $ScriptString.SubString($Token.Start - $SubStringLength, $SubStringLength).Replace(' ', '').Replace("`t", '').Replace("`n", '')
    $SubStringLength = 5
    If ($SubString.Length -lt $SubStringLength) {
        $SubStringLength = $SubString.Length
    }
    $SubString = $SubString.SubString($SubString.Length - $SubStringLength, $SubStringLength)

    # If dealing with ObfuscationLevel -gt 1 (e.g. -f format operator), perform check to see if we're dealing with a string that is part of a Parameter Binding.
    If (($ObfuscationLevel -gt 1) -AND ($Token.Start -gt 5) -AND ($SubString.Contains('(') -OR $SubString.Contains(',')) -AND $ScriptString.SubString(0, $Token.Start).Contains('[') -AND $ScriptString.SubString(0, $Token.Start).Contains('(')) {
        # Gather substring preceding the current String token to see if we need to treat the obfuscated string as a scriptblock.
        $ParameterBindingName = $ScriptString.SubString(0, $Token.Start)
        $ParameterBindingName = $ParameterBindingName.SubString(0, $ParameterBindingName.LastIndexOf('('))
        $ParameterBindingName = $ParameterBindingName.SubString($ParameterBindingName.LastIndexOf('[') + 1).Trim()
        # Filter out values that are not Parameter Binding due to contain whitespace, some special characters, etc.
        If (!$ParameterBindingName.Contains(' ') -AND !$ParameterBindingName.Contains(']') -AND !($ParameterBindingName.Length -eq 0)) {
            # If we have a match then set boolean to True so result will be encapsulated with curly braces at the end of this function.
            If ($ParameterValidationAttributesToTreatStringAsScriptblock -Contains $ParameterBindingName.ToLower()) {
                $EncapsulateAsScriptBlockInsteadOfParentheses = $TRUE
            }
        }
    }
    ElseIf (($ObfuscationLevel -gt 1) -AND ($Token.Start -gt 5) -AND $ScriptString.SubString($Token.Start - 5, 5).Contains('=')) {
        # If dealing with ObfuscationLevel -gt 1 (e.g. -f format operator), perform check to see if we're dealing with a string that is part of a Parameter Binding.
        ForEach ($Parameter in $ParameterValidationAttributesToTreatStringAsScriptblock) {
            $SubStringLength = $Parameter.Length
                
            # Add 10 more to $SubStringLength in case there is excess whitespace between the = sign.
            $SubStringLength += 10

            # Shorten substring length in case there is not enough room depending on the location of the token in the $ScriptString.
            If ($Token.Start -lt $SubStringLength) {
                $SubStringLength = $Token.Start
            }

            # Extract substring to compare against $EncapsulateAsScriptBlockInsteadOfParentheses.
            $SubString = $ScriptString.SubString($Token.Start - $SubStringLength, $SubStringLength + 1).Trim()

            # If we have a match then set boolean to True so result will be encapsulated with curly braces at the end of this function.
            If ($SubString -Match "$Parameter.*=") {
                $EncapsulateAsScriptBlockInsteadOfParentheses = $TRUE
            }
        }
    }

    # Do nothing if the token has length <= 1 (e.g. Write-Host "", single-character tokens, etc.).
    If ($Token.Content.Length -le 1) { Return $ScriptString }
    
    # Do nothing if the token has length <= 3 and $ObfuscationLevel is 2 (reordering).
    If (($Token.Content.Length -le 3) -AND $ObfuscationLevel -eq 2) { Return $ScriptString }

    # Do nothing if $Token.Content already contains a { or } to avoid parsing errors when { and } are introduced into substrings.
    If ($Token.Content.Contains('{') -OR $Token.Content.Contains('}')) { Return $ScriptString }

    # If the Token is 'invoke' then do nothing. This is because .invoke() is treated as a member but ."invoke"() is treated as a string.
    If ($Token.Content.ToLower() -eq 'invoke') { Return $ScriptString }

    # Set $Token.Content in a separate variable so it can be modified since Content is a ReadOnly property of $Token.
    $TokenContent = $Token.Content

    # Tokenizer removes ticks from strings, but we want to keep them. So we will replace the contents of $Token.Content with the manually extracted token data from the original $ScriptString.
    $TokenContent = $ScriptString.SubString($Token.Start + 1, $Token.Length - 2)

    # If a variable is present in a string, more work needs to be done to extract from string. Warning maybe should be thrown either way.
    # Must come back and address this after vacation.
    # Variable can be displaying or setting: "setting var like $($var='secret') and now displaying $var"
    # For now just split on whitespace instead of passing to Out-Concatenated
    If ($TokenContent.Contains('$') -OR $TokenContent.Contains('`')) {
        $ObfuscatedToken = ''
        $Counter = 0

        # If special use case is met then don't substring the current Token to avoid errors.
        # The special cases involve a double-quoted string containing a variable or a string-embedded-command that contains whitespace in it.
        # E.g. "string ${var name with whitespace} string" or "string $(gci *whitespace_in_command*) string"
        $TokenContentSplit = $TokenContent.Split(' ')
        $ContainsVariableSpecialCases = (($TokenContent.Contains('$(') -OR $TokenContent.Contains('${')) -AND ($ScriptString[$Token.Start] -eq '"'))
        
        If ($ContainsVariableSpecialCases) {
            $TokenContentSplit = $TokenContent
        }

        ForEach ($SubToken in $TokenContentSplit) {
            $Counter++
            
            $ObfuscatedSubToken = $SubToken

            # Determine if use case of variable inside of double quotes is present as this will be handled differently below.
            $SpecialCaseContainsVariableInDoubleQuotes = (($ObfuscatedSubToken.Contains('$') -OR $ObfuscatedSubToken.Contains('`')) -AND ($ScriptString[$Token.Start] -eq '"'))

            # Since splitting on whitespace removes legitimate whitespace we need to add back whitespace for all but the final subtoken.
            If ($Counter -lt $TokenContent.Split(' ').Count) {
                $ObfuscatedSubToken = $ObfuscatedSubToken + ' '
            }

            # Concatenate $SubToken if it's long enough to be concatenated.
            If (($ObfuscatedSubToken.Length -gt 1) -AND !($SpecialCaseContainsVariableInDoubleQuotes)) {
                # Concatenate each $SubToken via Out-StringDelimitedAndConcatenated so it will handle any replacements for special characters.
                # Define -PassThru flag so an invocation is not added to $ObfuscatedSubToken.
                $ObfuscatedSubToken = Out-StringDelimitedAndConcatenated $ObfuscatedSubToken -PassThru
            
                # Evenly trim leading/trailing parentheses.
                While ($ObfuscatedSubToken.StartsWith('(') -AND $ObfuscatedSubToken.EndsWith(')')) {
                    $ObfuscatedSubToken = ($ObfuscatedSubToken.SubString(1, $ObfuscatedSubToken.Length - 2)).Trim()
                }
            }
            Else {
                If ($SpecialCaseContainsVariableInDoubleQuotes) {
                    $ObfuscatedSubToken = '"' + $ObfuscatedSubToken + '"'
                }
                ElseIf ($ObfuscatedSubToken.Contains("'") -OR $ObfuscatedSubToken.Contains('$')) {
                    $ObfuscatedSubToken = '"' + $ObfuscatedSubToken + '"'
                }
                Else {
                    $ObfuscatedSubToken = "'" + $ObfuscatedSubToken + "'"
                }
            }

            # Add obfuscated/trimmed $SubToken back to $ObfuscatedToken if a Replace operation was used.
            If ($ObfuscatedSubToken -eq $PreObfuscatedSubToken) {
                # Same, so don't encapsulate. And maybe take off trailing whitespace?
            }
            ElseIf ($ObfuscatedSubToken.ToLower().Contains("replace")) {
                $ObfuscatedToken += ( '(' + $ObfuscatedSubToken + ')' + '+' )
            }
            Else {
                $ObfuscatedToken += ($ObfuscatedSubToken + '+' )
            }
        }

        # Trim extra whitespace and trailing + from $ObfuscatedToken.
        $ObfuscatedToken = $ObfuscatedToken.Trim(' + ')
    }
    Else {
        # For Parameter Binding the value has to either be plain concatenation or must be a scriptblock in which case we will encapsulate with {} instead of ().
        # The encapsulation will occur later in the function. At this point we're just setting the boolean variable $EncapsulateAsScriptBlockInsteadOfParentheses.
        # Actual error that led to this is: "Attribute argument must be a constant or a script block."
        # ALLOWED     :: [CmdletBinding(DefaultParameterSetName={"{1}{0}{2}"-f'd','DumpCre','s'})]
        # NOT ALLOWED :: [CmdletBinding(DefaultParameterSetName=("{1}{0}{2}"-f'd','DumpCre','s'))]
        $SubStringStart = 30
        If ($Token.Start -lt $SubStringStart) {
            $SubStringStart = $Token.Start
        }

        $SubString = $ScriptString.SubString($Token.Start - $SubStringStart, $SubStringStart).ToLower()

        If ($SubString.Contains('defaultparametersetname') -AND $SubString.Contains('=')) {
            $EncapsulateAsScriptBlockInsteadOfParentheses = $TRUE
        }

        If ($SubString.Contains('parametersetname') -OR $SubString.Contains('confirmimpact') -AND !$SubString.Contains('defaultparametersetname') -AND $SubString.Contains('=')) {
            # For strings in ParameterSetName parameter binding (but not DefaultParameterSetName) then we will only obfuscate with tick marks.
            # Otherwise we may get errors depending on the version of PowerShell being run.
            $ObfuscatedToken = $Token.Content
            $TokenForTicks = [System.Management.Automation.PSParser]::Tokenize($ObfuscatedToken, [ref]$null)
            $ObfuscatedToken = '"' + (Out-ObfuscatedWithTicks $ObfuscatedToken $TokenForTicks[0]) + '"'
        }
        Else {
            # User input $ObfuscationLevel (1-2) will choose between concatenating String token value string or reordering it with the -f format operator.
            # I am leaving out Out-ObfuscatedStringCommand's option 3 since that may introduce a Type token unnecessarily ([Regex]).
            Switch ($ObfuscationLevel) {
                1 { $ObfuscatedToken = Out-StringDelimitedAndConcatenated $TokenContent -PassThru }
                2 { $ObfuscatedToken = Out-StringDelimitedConcatenatedAndReordered $TokenContent -PassThru }
                default { Write-Error "An invalid `$ObfuscationLevel value ($ObfuscationLevel) was passed to switch block for String Token Obfuscation."; Exit }
            }
        }

        # Evenly trim leading/trailing parentheses.
        While ($ObfuscatedToken.StartsWith('(') -AND $ObfuscatedToken.EndsWith(')')) {
            $TrimmedObfuscatedToken = ($ObfuscatedToken.SubString(1, $ObfuscatedToken.Length - 2)).Trim()
            # Check if the parentheses are balanced before permenantly trimming
            $Balanced = $True
            $Counter = 0
            ForEach ($char in $TrimmedObfuscatedToken.ToCharArray()) {
                If ($char -eq '(') {
                    $Counter = $Counter + 1
                }
                ElseIf ($char -eq ')') {
                    If ($Counter -eq 0) {
                        $Balanced = $False
                        break
                    }
                    Else {
                        $Counter = $Counter - 1
                    }
                }
            }
            # If parantheses are balanced, we can safely trim the parentheses
            If ($Balanced -and $Counter -eq 0) {
                $ObfuscatedToken = $TrimmedObfuscatedToken
            }
            # If parentheses cannot be trimmed, break out of loop
            Else {
                break
            }
        }
    }

    # Encapsulate concatenated string with parentheses to avoid garbled string in scenarios like Write-* methods.
    If ($ObfuscatedToken.Length -ne ($TokenContent.Length + 2)) {
        # For Parameter Binding the value has to either be plain concatenation or must be a scriptblock in which case we will encapsulate with {} instead of ().
        # Actual error that led to this is: "Attribute argument must be a constant or a script block."
        # ALLOWED     :: [CmdletBinding(DefaultParameterSetName={"{1}{0}{2}"-f'd','DumpCre','s'})]
        # NOT ALLOWED :: [CmdletBinding(DefaultParameterSetName=("{1}{0}{2}"-f'd','DumpCre','s'))]
        If ($EncapsulateAsScriptBlockInsteadOfParentheses) {
            $ObfuscatedToken = '{' + $ObfuscatedToken + '}'
        }
        ElseIf (($ObfuscatedToken.Length -eq $TokenContent.Length + 5) -AND $ObfuscatedToken.SubString(2, $ObfuscatedToken.Length - 4) -eq ($TokenContent + ' ')) {
            If ($ContainsVariableSpecialCases) {
                $ObfuscatedToken = '"' + $TokenContent + '"'
            }
            Else {
                $ObfuscatedToken = $TokenContent
            }
        }
        ElseIf ($ObfuscatedToken.StartsWith('"') -AND $ObfuscatedToken.EndsWith('"') -AND !$ObfuscatedToken.Contains('+') -AND !$ObfuscatedToken.Contains('-f')) {
            # No encapsulation is needed for string obfuscation that is only double quotes and tick marks for ParameterSetName (and not DefaultParameterSetName).
            $ObfuscatedToken = $ObfuscatedToken
        }
        ElseIf ($ObfuscatedToken.Length -ne $TokenContent.Length + 2) {
            $ObfuscatedToken = '(' + $ObfuscatedToken + ')'
        }
    }

    # Remove redundant blank string concatenations introduced by special use case of $ inside double quotes.
    If ($ObfuscatedToken.EndsWith("+''") -OR $ObfuscatedToken.EndsWith('+""')) {
        $ObfuscatedToken = $ObfuscatedToken.SubString(0, $ObfuscatedToken.Length - 3)
    }

    # Handle dangling ticks from string concatenation where a substring ends in a tick. Move this tick to the beginning of the following substring.
    If ($ObfuscatedToken.Contains('`')) {
        If ($ObfuscatedToken.Contains('`"+"')) {
            $ObfuscatedToken = $ObfuscatedToken.Replace('`"+"', '"+"`')
        }
        If ($ObfuscatedToken.Contains("``'+'")) {
            $ObfuscatedToken = $ObfuscatedToken.Replace("``'+'", "'+'``")
        }
    }

    # Add the obfuscated token back to $ScriptString.
    # If string is preceded by a . or :: and followed by ( then it is a Member token encapsulated by quotes and now treated as a string.
    # We must add a .Invoke to the concatenated Member string to avoid syntax errors.
    If ((($Token.Start -gt 0) -AND ($ScriptString.SubString($Token.Start - 1, 1) -eq '.')) -OR (($Token.Start -gt 1) -AND ($ScriptString.SubString($Token.Start - 2, 2) -eq '::')) -AND ($ScriptString.SubString($Token.Start + $Token.Length, 1) -eq '(')) {
        $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + '.Invoke' + $ScriptString.SubString($Token.Start + $Token.Length)
    }
    Else {
        $ScriptString = $ScriptString.SubString(0, $Token.Start) + $ObfuscatedToken + $ScriptString.SubString($Token.Start + $Token.Length)
    }
    
    Return $ScriptString
}
