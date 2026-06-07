Add-Type -AssemblyName System.Windows.Forms
$rtfBox = New-Object System.Windows.Forms.RichTextBox
$rtfBox.Rtf = [System.IO.File]::ReadAllText("requirements.rtf")
[System.IO.File]::WriteAllText("requirements.txt", $rtfBox.Text)
