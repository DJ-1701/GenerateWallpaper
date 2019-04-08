# Wallpaper folder source.
$Domain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
$NetworkSource = "\\$Domain\NetLogon\Establishment\Wallpaper"
$LocalSource = "$Env:ProgramFiles\Establishment\Wallpaper"

# Custom wallpaper override file.
# Note: Value used to prevent deletion of local file when mirroring.
$Override = "$LocalSource\Override.jpg"

# Path to robocopy command.
$WinDir = (Get-Childitem env:WinDir).Value
$Robocopy = "$WinDir\System32\Robocopy.exe"
If (!(Test-Path($Robocopy)))
{
    Write-Host "$Robocopy does not exist."
    Exit
}

If (!(Test-Path($NetworkSource)))
{
    Write-Host "$NetworkSource does not exist."
    Exit
}

If (!(Test-Path($LocalSource)))
{
      New-Item -ItemType directory -Path $LocalSource
}

# Update local wallpapers.
&$Robocopy "$NetworkSource" "$LocalSource" /MIR /XF "$Override" /R:1 /W:1 /NP