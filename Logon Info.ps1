# Text for the wallpaper.
$TextLabel = "Establishment Address Here`r`n`r`nUser Name: "+($env:USERNAME)+"`r`nComputer Name: "+($env:COMPUTERNAME)+"`r`nModel: "+((Get-WmiObject Win32_ComputerSystem).Model)+"`r`nSerial Number: "+((Get-WmiObject Win32_ComputerSystemProduct).IdentifyingNumber)
$TextSizePoint = 12

# Text box colour.
$BoxRed = 0
$BoxGreen = 125
$BoxBlue = 255

# Text colour.
$TextRed = 255
$TextGreen = 255
$TextBlue = 255

# Wallpaper source folder.
$LocalSource = "$Env:ProgramFiles\Establishment\Wallpaper"

# Completed wallpaper destination location.
$DestinationFile = "$env:temp\LogonInfo.jpg"

# Clear theme cache files.
Remove-Item -Path "$($env:APPDATA)\Microsoft\Windows\Themes\*" -Recurse -Force -ErrorAction SilentlyContinue

# Ensure image is set to Stretch to screen resolution and not tile.
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value "2" -Force
Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value "0" -Force

If (!(Test-Path($LocalSource)))
{
    Write-Host "$LocalSource does not exist."
    Exit
}

# Find current screen resolution.
# Note: Interrogating [System.Windows.Forms.Screen] at boot returns false 1024x768.
#       Therefore, this login script stores the data on user login to a registry key.
#       After which the boot script can check this key. If data does not exist, it will use
#       recommended supported resolution data. If this fails, it will default to 1024x768.
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$RegistryPath = "HKLM:\Software\MachineData"
$Horizontal = [int]([System.Windows.Forms.Screen]::AllScreens[0]).Bounds.Width
$Vertical = [int]([System.Windows.Forms.Screen]::AllScreens[0]).Bounds.Height
# If no data is found in the registry for the resolution, let's setup a HLKM entry where
# authenticated users can store this data. If the user is an Administrator this should work,
# otherwise we will have to rely on the boot script to create this key on reboot.
If (!(Test-Path $RegistryPath))
{
    New-Item -Path $RegistryPath -Force
    $acl = Get-Acl HKLM:\SOFTWARE\MachineData
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\Authenticated Users","SetValue, CreateSubKey, CreateLink, Delete, ReadKey","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($rule)
    $acl |Set-Acl -Path HKLM:\SOFTWARE\MachineData
}
New-ItemProperty -Path $RegistryPath -Name "Horizontal" -Value $Horizontal -PropertyType DWORD -Force
New-ItemProperty -Path $RegistryPath -Name "Vertical" -Value $Vertical -PropertyType DWORD -Force
If ((($Horizontal -eq $null) -or ($Horizontal -eq 0)) -or (($Vertical -eq $null) -or ($Vertical -eq 0)))
{
    $Horizontal = [int]((Get-WmiObject -Class Win32_VideoController).CurrentHorizontalResolution)
    $Vertical = [int]((Get-WmiObject -Class Win32_VideoController).CurrentVerticalResolution)
    If ((($Horizontal -eq $null) -or ($Horizontal -eq 0)) -or (($Vertical -eq $null) -or ($Vertical -eq 0)))
    {
        For ($i=0; $i -lt (Get-WmiObject -Class Win32_VideoController).Count; $i++)
        {
            If (([int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentHorizontalResolution) -ne $null) -and `
               ([int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentHorizontalResolution) -ne 0) -and `
               ([int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentVerticalResolution) -ne $null) -and `
               ([int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentVerticalResolution) -ne 0))
            {
                $Horizontal = [int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentHorizontalResolution)
                $Vertical = [int]((Get-WmiObject -Class Win32_VideoController)[$i].CurrentVerticalResolution)
                $i = (Get-WmiObject -Class Win32_VideoController).Count
            }
        }
    }
}
If ($Horizontal -eq $null) {$Horizontal = [int]"1024"}
If ($Vertical -eq $null) {$Vertical = [int]"768"}

If ($Horizontal/$Vertical -le 1.4)
{
    $Ratio = "4x3"
}
Else
{
    $Ratio = "16x9"
}
$SourceDir = "$LocalSource\$Ratio"
If (!(Test-Path($SourceDir)))
{
    Write-Host "$SourceDir does not exist."
    Exit
}

# Select a random file as the source wallpaper.
$Files = (dir -Path $SourceDir\* -Recurse).FullName
$SourceFile = $Files | Get-Random

# If username does not start with Guest, look to see if the user has a personal wallpaper they wish to use instead.
If (!(($env:USERNAME) -like "Guest*"))
{
    If (Test-Path("$env:userprofile\Documents\Wallpaper\Wallpaper.jpg"))
    {
        $SourceFile = "$env:userprofile\Documents\Wallpaper\Wallpaper.jpg"
    }
    ElseIf (Test-Path("$env:homeshare\Wallpaper\Wallpaper.jpg"))
    {
        $SourceFile = "$env:homeshare\Wallpaper\Wallpaper.jpg"
    }
}

# If no source file exists, exit.
If (!(Test-Path($SourceFile)))
{
    Write-Host "$SourceFile does not exist."
    Exit
}
If ($? -eq $false)
{
    Write-Host "Null Source File."
    Exit
}

# Use .Net Framework to create a class to update and refresh the Wallpaper.
Add-Type @”
    using System;
    using System.Runtime.InteropServices;
    using Microsoft.Win32;

    namespace Wallpaper
    {
        public class UpdateImage
        {
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        
            private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);

            public static void Refresh(string path) 
            {
                SystemParametersInfo( 20, 0, path, 0x01 | 0x02 ); 
            }
        }
    }
“@

# Enable the creation of images.
Add-Type -AssemblyName System.Drawing

# Select a font, size and style.
$TextSizePixels=$TextSizePoint/0.75
$Font = New-Object System.Drawing.Font("Arial",$TextSizePixels,[Drawing.FontStyle]'Bold',"Pixel")

# Get source image from source file.
$SourceImage = [System.Drawing.Image]::FromFile($SourceFile)
 
# Create a new bitmap at the primary monitor resolution to construct an image.
$Bitmap = New-Object System.Drawing.Bitmap($Horizontal,$Vertical)

# Create image for editing.
$Image = [System.Drawing.Graphics]::FromImage($Bitmap)

# Ensure the image is clear.
$Image.Clear([System.Drawing.Color]::FromArgb(255,255,255,255))

# Set the ARGB values required for the text and text box.
$TextARGB = [System.Drawing.Color]::FromArgb(255,$TextRed,$TextGreen,$TextBlue)
$BoxARGB = [System.Drawing.Color]::FromArgb(255,$BoxRed,$BoxGreen,$BoxBlue)

# Set area for text placement.
$Rectangle = [System.Drawing.RectangleF]::FromLTRB(0, 0, $Horizontal, $Vertical)

# Set alignment format for the font.
$FormatFont = [System.Drawing.StringFormat]::GenericDefault
$FormatFont.Alignment = [System.Drawing.StringAlignment]::Far
$FormatFont.LineAlignment = [System.Drawing.StringAlignment]::Near

# Get text path Layout to work out text box co-ordinates.
$TextPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$TextPath.AddString($TextLabel,$Font.FontFamily,$Font.Style,$Font.Size,$Rectangle,$FormatFont)

# Get co-ordinates of beginning and end of text, and add padding for text box.
$StartX = $Horizontal
$StartY = $Vertical
$EndX = 0
$EndY = 0
ForEach ($PathPointRow in $TextPath.PathPoints)
{
    If ($PathPointRow.X -le $StartX){$StartX = $PathPointRow.X}
    If ($PathPointRow.Y -le $StartY){$StartY = $PathPointRow.Y}
    If ($PathPointRow.X -gt $EndX){$EndX = $PathPointRow.X}
    If ($PathPointRow.Y -gt $EndY){$EndY = $PathPointRow.Y}
}
$EndX = $EndX - $StartX + 5
$EndY = $EndY - $StartY + 10
$StartY = $StartY - 5
$StartX = $StartX

# Set up the brush colours for drawing text box and text string.
$BoxBrushColour = New-Object Drawing.SolidBrush $BoxARGB
$TextBrushColour = New-Object Drawing.SolidBrush $TextARGB

# Draw image.
$Image.DrawImage($SourceImage,0,0, $Horizontal, $Vertical)

# Draw box.
$Image.FillRectangle($BoxBrushColour,$StartX,$StartY,$EndX,$EndY)

# Draw text.
$Image.DrawString($TextLabel,$Font,$TextBrushColour,$Rectangle,$FormatFont)

# Save edited bitmap to file.
$Bitmap.Save($DestinationFile,[System.Drawing.Imaging.ImageFormat]::Jpeg)

# Clean up and remove objects.
$SourceImage.Dispose()
$Bitmap.Dispose()
$Image.Dispose()
$SourceDestinationFile

# Open saved file.
#Invoke-Item $DestinationFile

# Update wallpaper.
[Wallpaper.UpdateImage]::Refresh($DestinationFile)
