# Text for the wallpaper.
$TextLabel = "Establishment Address Here`r`nTelephone: Telephone Number Here`r`nComputer Name: "+((Get-Childitem env:ComputerName).Value)
$TextSizePoint = 18

# Text box colour.
$BoxRed = 22
$BoxGreen = 176
$BoxBlue = 221

# Text colour.
$TextRed = 255
$TextGreen = 255
$TextBlue = 255

# Wallpaper source folder.
$LocalSource = "$Env:ProgramFiles\Establishment\Wallpaper"

# Custom wallpaper override file.
$Override = "$LocalSource\Override.jpg"

# Completed wallpaper destination location.
$WinDir = (Get-Childitem env:WinDir).Value
$SystemBackgroundDir = "$WinDir\system32\oobe\info\backgrounds"
$DestinationFile = "$SystemBackgroundDir\backgroundDefault.jpg"

If (!(Test-Path($LocalSource)))
{
    Write-Host "$LocalSource does not exist."
    Exit
}

If (!(Test-Path("$SystemBackgroundDir")))
{
   New-Item -ItemType directory -Path "$SystemBackgroundDir"
}

# Find current screen resolution.
# Note: Interrogating [System.Windows.Forms.Screen] at boot returns false 1024x768.
#       Therefore, a separate login script stores this data on user login to a registry key.
#       After which the PC can check this key. If data does not exist, it will use
#       recommended supported resolution data for any detected monitors.
#       If this fails, it will default to 1024x768.
$RegistryPath = "HKLM:\Software\MachineData"
If ((Test-Path $RegistryPath))
{
    If (((Get-ItemProperty -Path $RegistryPath).Horizontal -ne $null) -and ((Get-ItemProperty -Path $RegistryPath).Vertical -ne $null))
    {
        $Horizontal = [int]((Get-ItemProperty -Path $RegistryPath).Horizontal)
        $Vertical = [int]((Get-ItemProperty -Path $RegistryPath).Vertical)
    }
}
Else
# If no data is found in the registry for the resolution, let's setup a HLKM entry where
# authenticated users can store this data.
{
    New-Item -Path $RegistryPath -Force
    $acl = Get-Acl HKLM:\SOFTWARE\MachineData
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\Authenticated Users","SetValue, CreateSubKey, CreateLink, Delete, ReadKey","ContainerInherit,ObjectInherit","None","Allow")
    $acl.SetAccessRule($rule)
    $acl |Set-Acl -Path HKLM:\SOFTWARE\MachineData
}
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

# If override wallpaper exists, change source file.
If ((Test-Path($Override)))
{
    $SourceFile = $Override
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
$FormatFont.Alignment = [System.Drawing.StringAlignment]::Center
$FormatFont.LineAlignment = [System.Drawing.StringAlignment]::Near

# Get text path Layout to work out text box co-ordinates.
$TextPath = New-Object System.Drawing.Drawing2D.GraphicsPath
$TextPath.AddString($TextLabel,$Font.FontFamily,$Font.Style,$Font.Size,$Rectangle,$FormatFont)

# Get co-ordinates of beginning and end of text.
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
$EndX = $EndX - $StartX
$EndY = $EndY - $StartY

# Set up the brush colours for drawing text box and text string.
$BoxBrushColour = New-Object Drawing.SolidBrush $BoxARGB
$TextBrushColour = New-Object Drawing.SolidBrush $TextARGB

# Draw image.
$Image.DrawImage($SourceImage,0,0, $Horizontal, $Vertical)

# Draw box.
$Image.FillRectangle($BoxBrushColour,$StartX,$StartY,$EndX,$EndY)

# Draw text.
$Image.DrawString($TextLabel,$Font,$TextBrushColour,$Rectangle,$FormatFont)

# Find last boot time to display on Wallpaper.
$TextLabel = "Last Boot: "+((Get-Date).DateTime)

# Select a font, size and style.
$TextSizePoint = 10
$TextSizePixels=$TextSizePoint/0.75
$Font = New-Object System.Drawing.Font("Arial",$TextSizePoint,[Drawing.FontStyle]'Bold',"Pixel")

# Set alignment format for the font.
$FormatFont = [System.Drawing.StringFormat]::GenericDefault
$FormatFont.Alignment = [System.Drawing.StringAlignment]::Near
$FormatFont.LineAlignment = [System.Drawing.StringAlignment]::Far

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
$EndX = $EndX - $StartX + 15
$EndY = $EndY - $StartY + 15
$StartY = $StartY - 5
$StartX = $StartX - 5

# Set up the brush colours for drawing text box and text string.
$BoxBrushColour = New-Object Drawing.SolidBrush $BoxARGB
$TextBrushColour = New-Object Drawing.SolidBrush $TextARGB

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
