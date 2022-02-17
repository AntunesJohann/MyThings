# |-----------------------------------------------------------------------------------------------|  ----------------------------
# |===============================================================================================|  -- These are things that  --
# |  === === === === === === ===  Start of Global Powershell Settings === === === === === === === |  -- will autorun everytime --
# |===============================================================================================|  -- PowerShell starts.     --
# |-----------------------------------------------------------------------------------------------|  ----------------------------

# "Clear-host" just so that banner won't bother me (and I'm too lazzy to edit the shortcut with '-NoLogo').
Clear-Host

# This next one will make powershell have a dropdown prediction menu (based on host history) as you write a command.
Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -ErrorAction SilentlyContinue

# These two variables will be useful throughout this profile script.
$PSAdminSession = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
$PSSessionOwner = [Security.Principal.WindowsIdentity]::GetCurrent().Name

# Lets make the PowerShell prompt a bit prettier and more organized, shall we? <(￣︶￣)>
# Here, take this simple Prompt function; it will run each time you confirm a command.
function Global:Prompt {
	Write-Host "$($PSSessionOwner.Split('\')[1])" -ForegroundColor DarkYellow -NoNewline
	Write-Host '@' -NoNewline
	Write-Host "$PWD" -ForegroundColor DarkCyan
	if ($PSAdminSession) {
		Write-Host '#' -ForegroundColor Green -NoNewline
	}
	return '> '
} # End of function Prompt



# Adding some useful global variables here.

# This is the settings file of Windows Terminal (now integrated into Windows 11).
Set-Variable `
	-Name "WinTermPROFILE" `
	-Value (Resolve-Path -Path "$env:LOCALAPPDATA\Packages\*WindowsTerminal*\LocalState\settings.json" -ErrorAction SilentlyContinue).Path `
	-Scope Global
# This is the powershell commands history file.
Set-Variable `
	-Name "ConsoleHostHistory" `
	-Value (Resolve-Path -Path "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -ErrorAction SilentlyContinue).Path `
	-Scope Global
# A variable that tells you when the session started can be really useful.
<#
Set-Variable `
	-Name "PSSessionStartTime" `
	-Value Get-Date | Select-Object -Property Day, Month, Year, Hour, Minute, Second, Millisecond | Format-Table `
	-Scope Global
#>
# This will get all the shortcuts created for installed programs. Should be useful too...
Set-Variable `
	-Name "DesktopShortcuts" `
	-Value (
	Get-ChildItem `
		-Path "$env:ProgramData\Microsoft\Windows\Start Menu", "$env:HOMEDRIVE$env:HOMEPATH\AppData\Roaming\Microsoft\Windows\Start Menu" `
		-Recurse `
		-Include '*.lnk', '*.url' -Exclude '*uninstall*' `
		-Force
).FullName `
	-Scope Global
<#
# Remember to put a good comment here ^^.
Set-Variable `
	-Name `
	-Value `
	-Scope Global
#>


# Shortcut to delete a line just like in VSCode.
Set-PSReadLineKeyHandler -Chord ctrl+shift+K -Function DeleteLine

# Now we'll enhance powershell with some autocompletion powers ᕦ(ò_óˇ)ᕤ
Set-PSReadlineKeyHandler -Chord @("`'", "`"", "(", "{", "[", ":", "@", "#", "Backspace") -ScriptBlock {
	param ($Key)
	function WriteChar ( [Switch]$CheckCurrentBuffer, [String]$InsChar, [Int16]$DelChar, [Int16]$CursorPos) {
		$K = $Pos = $null
		if (!$CheckCurrentBuffer) {
			Switch ($PSBoundParameters.Keys) {
				"InsChar" { [Microsoft.PowerShell.PSConsoleReadLine]::Insert($InsChar) }
				"CursorPos" {
					[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$K, [ref]$Pos)
					[Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($Pos + $CursorPos)
				}
				"DelChar" { For ($i -eq 0; $i -lt $DelChar; $i++) { [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar() } }
			}
		}
		else {
			[Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$K, [ref]$Pos)
			return [PSCustomObject]@{
				NextChar       = $K[$Pos]
				LastChar       = $K[$Pos - 1]
				SecondNextChar = $K[$Pos + 1]
				SecondLastChar = $K[$Pos - 2]
			}
		}
	}

	$CharPos = WriteChar -CheckCurrentBuffer
	$NotSurrounded = [String]::IsNullOrWhiteSpace($CharPos.LastChar) -and [String]::IsNullOrWhiteSpace($CharPos.NextChar)
	$SorroundedByBrackets = ("(", "{", "[") -icontains $CharPos.LastChar -and (")", "}", "]") -icontains $CharPos.NextChar

	if ( ($Key.Key -ne 'Backspace' -and $SorroundedByBrackets) -or ($NotSurrounded -and ("`'", "`"", "(", "{", "[") -icontains $Key.KeyChar) ) {
		Switch ($Key.KeyChar) {
			"`'" { WriteChar -InsChar "`'`'" -CursorPos -1; Break }
			"`"" { WriteChar -InsChar "`"`"" -CursorPos -1; Break }
			"(" { WriteChar -InsChar "()" -CursorPos -1; Break }
			"{" { WriteChar -InsChar "{}" -CursorPos -1; Break }
			"[" { WriteChar -InsChar "[]" -CursorPos -1; Break }
		}
	}
	elseif ( (":", "`"", "#", "{") -icontains $Key.KeyChar -and ("]", "<", "@") -icontains $CharPos.LastChar -and [String]::IsNullOrWhiteSpace($CharPos.NextChar) ) {
		Switch ($Key.KeyChar) {
			":" { WriteChar -InsChar "::"; Break }
			"{" { WriteChar -InsChar "{}" -CursorPos -1; Break }
			"#" { WriteChar -InsChar "##>" -CursorPos -2; Break }
			"`"" { WriteChar -InsChar "`"`"@" -CursorPos -2; Break }
		}
	}
	elseif ( $Key.Key -eq 'Backspace' -and ($CharPos.LastChar -and $CharPos.NextChar -eq "#") -and $CharPos.SecondLastChar -eq "<" -and $CharPos.SecondNextChar -eq ">" ) {
		WriteChar -CursorPos 2 -DelChar 4
	}
	elseif ( $Key.Key -eq 'Backspace' -and ($CharPos.LastChar -and $CharPos.NextChar -eq "`"") -and ($CharPos.SecondLastChar -and $CharPos.SecondNextChar -eq "@") ) {
		WriteChar -CursorPos 2 -DelChar 4
	}
	elseif ( $Key.Key -eq 'Backspace' -and $SorroundedByBrackets ) {
		WriteChar -CursorPos 1 -DelChar 2
	}
	elseif ( $Key.Key -eq 'Backspace' -and ("`'", "`"") -icontains $CharPos.LastChar -and ("`'", "`"") -icontains $CharPos.NextChar ) {
		WriteChar -CursorPos 1 -DelChar 2
	}
	elseif ($Key.Key -eq 'Backspace') {
		WriteChar -DelChar 1
	}
	else { WriteChar -InsChar $Key.KeyChar }
}
# |-----------------------------------------------------------------------------------------------|
# |===============================================================================================|
# | === === === === === === ===   End of Global Powershell Settings   === === === === === === === |
# |===============================================================================================|
# |-----------------------------------------------------------------------------------------------|





# |-----------------------------------------------------------------------------------------------|  ----------------------------------
# |===============================================================================================|  -- Down here goes things that   --
# |  === === === === === === === ===  Start of "Do Once" Section  === === === === === === === === |  -- should run only once (and    --
# |===============================================================================================|  -- only if session is elevated. --
# |-----------------------------------------------------------------------------------------------|  ----------------------------------
if ($PSAdminSession -and $PSSessionOwner.Split('\')[1] -ne 'SYSTEM') {


	New-Item -Path HKLM:\SOFTWARE\RunOnce -ErrorAction SilentlyContinue
	$Private:RunOnce = Get-ItemProperty -Path HKLM:\SOFTWARE\RunOnce

	if ($null -eq $RunOnce.PSNuGetProvider) {
		"Adding NuGetGallery (from nuget.org) to the packages sources list.`nThis will run just once, please wait..."
		Register-PackageSource -Name NuGetGallery -Location "https://www.nuget.org/api/v2" -ProviderName NuGet | Out-Null
		Set-ItemProperty -Path HKLM:\SOFTWARE\RunOnce -Name PSNuGetProvider -Type DWord -Value 0
		"DONE`n"
	}
	if ($null -eq $RunOnce.UpdatePSReadLine) {
		"Updating PSReadLine module to the latest version.`nThis will run just once, please wait..."
		Install-Package -Name PSReadLine -Source PSGallery -AllowPrereleaseVersions -Scope AllUsers -AcceptLicense -Force
		Set-ItemProperty -Path HKLM:\SOFTWARE\RunOnce -Name UpdatePSReadLine -Type DWord -Value 0
		"DONE`n"
	}
	if ($null -eq $RunOnce.PSWindowsUpdateModule) {
		"Installing latest version of PSWindowsUpdate module.`nThis will run just once, please wait..."
		Install-Package -Name PSWindowsUpdate -Source PSGallery -AllowPrereleaseVersions -Scope AllUsers -AcceptLicense -Force
		Set-ItemProperty -Path HKLM:\SOFTWARE\RunOnce -Name PSWindowsUpdateModule -Type DWord -Value 0
		"DONE`n"
	}
	if ($null -eq $RunOnce.SetPSSystemProfile) {
		if ( !(Test-Path -Path "$env:SystemRoot\system32\config\systemprofile\Documents\PowerShell") ) {
			New-Item -Path "$env:SystemRoot\system32\config\systemprofile\Documents\PowerShell" -ItemType Directory -Force | Out-Null
		}
		"Copying current PowerShell user profile to NT System profile.`nThis will run just once, please wait..."
		Copy-Item `
			-Path "$env:HOMEDRIVE$env:HOMEPATH\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" `
			-Destination "$env:SystemRoot\system32\config\systemprofile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
		Set-ItemProperty -Path HKLM:\SOFTWARE\RunOnce -Name SetPSSystemProfile -Type DWord -Value 0
		"DONE`n"
	}
	<#
	if ($null -eq $RunOnce.[TASK_NAME]) {
		"[TASK_DESCRIPTION].`nThis will run just once, please wait..."

		Set-ItemProperty -Path HKLM:\SOFTWARE\RunOnce -Name [TASK_NAME] -Type DWord -Value 0
		"DONE`n"
	}
	#>
}
# |-----------------------------------------------------------------------------------------------|
# |===============================================================================================|
# |  === === === === === === === ===   End of "Do Once" Section   === === === === === === === === |
# |===============================================================================================|
# |-----------------------------------------------------------------------------------------------|





# |-----------------------------------------------------------------------------------------------|  ------------------------------
# |===============================================================================================|  -- Here should go functions --
# |  === === === === === ===  Start of Powershell User Functions section  === === === === === === |  -- that can run just like   --
# |===============================================================================================|  -- any other cmdlet.        --
# |-----------------------------------------------------------------------------------------------|  ------------------------------

# |-----------------------------------------------------------------------------------------------|
# |===============================================================================================|
# |  === === === === === ===   End of Powershell User Functions section   === === === === === === |
# |===============================================================================================|
# |-----------------------------------------------------------------------------------------------|
