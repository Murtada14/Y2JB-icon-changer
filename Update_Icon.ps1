Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==========================================
# Y2JB icon/background changer
# ==========================================

$form = New-Object System.Windows.Forms.Form
$form.Text = "Y2JB icon/background changer"
$form.Size = New-Object System.Drawing.Size(460, 600)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Safe base directory lookup for temp files
$baseDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($baseDir)) {
    $baseDir = [System.AppDomain]::CurrentDomain.BaseDirectory
}

# Common Settings (IP & Port at the top)
$ipLabel = New-Object System.Windows.Forms.Label
$ipLabel.Location = New-Object System.Drawing.Point(20, 15)
$ipLabel.Size = New-Object System.Drawing.Size(190, 20)
$ipLabel.Text = "PS5 IP Address:"
$form.Controls.Add($ipLabel)

$ipBox = New-Object System.Windows.Forms.TextBox
$ipBox.Location = New-Object System.Drawing.Point(20, 38)
$ipBox.Size = New-Object System.Drawing.Size(190, 25)
$ipBox.Text = "192.168.1.80"
$form.Controls.Add($ipBox)

$portLabel = New-Object System.Windows.Forms.Label
$portLabel.Location = New-Object System.Drawing.Point(230, 15)
$portLabel.Size = New-Object System.Drawing.Size(190, 20)
$portLabel.Text = "FTP port number (e.g. 2121, 1337)"
$form.Controls.Add($portLabel)

$portBox = New-Object System.Windows.Forms.TextBox
$portBox.Location = New-Object System.Drawing.Point(230, 38)
$portBox.Size = New-Object System.Drawing.Size(185, 25)
$portBox.Text = "2121"
$form.Controls.Add($portBox)

# Tab Control for Icon vs Background
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(20, 80)
$tabControl.Size = New-Object System.Drawing.Size(395, 455)

# ==========================================
# TAB 1: ICON UPLOADER
# ==========================================
$tabIcon = New-Object System.Windows.Forms.TabPage
$tabIcon.Text = "Icon (icon0.png)"

# Region Dropdown (Icon)
$iconRegionLabel = New-Object System.Windows.Forms.Label
$iconRegionLabel.Location = New-Object System.Drawing.Point(15, 20)
$iconRegionLabel.Size = New-Object System.Drawing.Size(350, 20)
$iconRegionLabel.Text = "Select YouTube Region / Version:"
$tabIcon.Controls.Add($iconRegionLabel)

$iconRegionCombo = New-Object System.Windows.Forms.ComboBox
$iconRegionCombo.Location = New-Object System.Drawing.Point(15, 45)
$iconRegionCombo.Size = New-Object System.Drawing.Size(350, 25)
$iconRegionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$iconRegionCombo.Items.Add("US (PPSA01650)")
[void]$iconRegionCombo.Items.Add("EU (PPSA01651)")
[void]$iconRegionCombo.Items.Add("JP (PPSA01652)")
$iconRegionCombo.SelectedIndex = 0
$tabIcon.Controls.Add($iconRegionCombo)

# File Path (Icon)
$iconFileLabel = New-Object System.Windows.Forms.Label
$iconFileLabel.Location = New-Object System.Drawing.Point(15, 95)
$iconFileLabel.Size = New-Object System.Drawing.Size(350, 20)
$iconFileLabel.Text = "Icon File Path (icon0.png):"
$tabIcon.Controls.Add($iconFileLabel)

$iconFileBox = New-Object System.Windows.Forms.TextBox
$iconFileBox.Location = New-Object System.Drawing.Point(15, 120)
$iconFileBox.Size = New-Object System.Drawing.Size(290, 25)
$iconFileBox.Text = ""
$tabIcon.Controls.Add($iconFileBox)

$iconBrowseBtn = New-Object System.Windows.Forms.Button
$iconBrowseBtn.Location = New-Object System.Drawing.Point(310, 119)
$iconBrowseBtn.Size = New-Object System.Drawing.Size(55, 27)
$iconBrowseBtn.Text = "..."
$tabIcon.Controls.Add($iconBrowseBtn)

$iconBrowseBtn.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PNG Image Files (*.png)|*.png|All Files (*.*)|*.*"
    $ofd.Title = "Select icon0.png"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $iconFileBox.Text = $ofd.FileName
    }
})

# Upload Button (Icon)
$iconUploadBtn = New-Object System.Windows.Forms.Button
$iconUploadBtn.Location = New-Object System.Drawing.Point(15, 185)
$iconUploadBtn.Size = New-Object System.Drawing.Size(350, 45)
$iconUploadBtn.Text = "Upload Icon"
$iconUploadBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$iconUploadBtn.ForeColor = [System.Drawing.Color]::White
$iconUploadBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$iconUploadBtn.Add_Click({
    $PS5_IP = $ipBox.Text.Trim()
    $FTP_PORT = $portBox.Text.Trim()
    $LOCAL_FILE = $iconFileBox.Text.Trim()
    
    $choice = $iconRegionCombo.SelectedItem.ToString()
    if ($choice -like "US*") { $APP_ID = "PPSA01650"; $REGION = "US" }
    elseif ($choice -like "EU*") { $APP_ID = "PPSA01651"; $REGION = "EU" }
    else { $APP_ID = "PPSA01652"; $REGION = "JP" }

    $REMOTE_PATH = "/user/appmeta/${APP_ID}/icon0.png"

    if ([string]::IsNullOrWhiteSpace($PS5_IP)) { [System.Windows.Forms.MessageBox]::Show("IP cannot be empty!", "Error", 'OK', 'Error'); return }
    if ([string]::IsNullOrWhiteSpace($LOCAL_FILE)) { [System.Windows.Forms.MessageBox]::Show("Please choose an icon file!", "Error", 'OK', 'Error'); return }
    if (-not (Test-Path $LOCAL_FILE)) { [System.Windows.Forms.MessageBox]::Show("File not found at:`n$LOCAL_FILE", "Error", 'OK', 'Error'); return }

    try {
        $tempBase = if ($baseDir) { $baseDir } else { $env:TEMP }
        
        # Unlock
        $uCmd = "open $PS5_IP $FTP_PORT`nuser anonymous ""`nquote SITE CHMOD 777 $REMOTE_PATH`nbye"
        $uFile = Join-Path $tempBase "unlock_i.txt"
        $uCmd | Out-File -FilePath $uFile -Encoding ASCII
        & ftp.exe -s:$uFile | Out-Null
        Remove-Item $uFile -ErrorAction SilentlyContinue

        # Upload
        $webReq = [System.Net.FtpWebRequest]::Create("ftp://${PS5_IP}:${FTP_PORT}${REMOTE_PATH}")
        $webReq.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
        $bytes = [System.IO.File]::ReadAllBytes($LOCAL_FILE)
        $webReq.ContentLength = $bytes.Length
        $s = $webReq.GetRequestStream()
        $s.Write($bytes, 0, $bytes.Length)
        $s.Close()

        # Relock
        $lCmd = "open $PS5_IP $FTP_PORT`nuser anonymous ""`nquote SITE CHMOD 444 $REMOTE_PATH`nbye"
        $lFile = Join-Path $tempBase "lock_i.txt"
        $lCmd | Out-File -FilePath $lFile -Encoding ASCII
        & ftp.exe -s:$lFile | Out-Null
        Remove-Item $lFile -ErrorAction SilentlyContinue

        [System.Windows.Forms.MessageBox]::Show("Icon updated successfully for YouTube $REGION ($APP_ID)!", "Success", 'OK', 'Information')
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("FTP Error: " + $_.Exception.Message, "Error", 'OK', 'Error')
    }
})
$tabIcon.Controls.Add($iconUploadBtn)


# ==========================================
# TAB 2: BACKGROUND UPLOADER (Dual Upload)
# ==========================================
$tabBg = New-Object System.Windows.Forms.TabPage
$tabBg.Text = "Background (pic0)"

# Region Dropdown (Background)
$bgRegionLabel = New-Object System.Windows.Forms.Label
$bgRegionLabel.Location = New-Object System.Drawing.Point(15, 15)
$bgRegionLabel.Size = New-Object System.Drawing.Size(350, 20)
$bgRegionLabel.Text = "Select YouTube Region / Version:"
$tabBg.Controls.Add($bgRegionLabel)

$bgRegionCombo = New-Object System.Windows.Forms.ComboBox
$bgRegionCombo.Location = New-Object System.Drawing.Point(15, 38)
$bgRegionCombo.Size = New-Object System.Drawing.Size(350, 25)
$bgRegionCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$bgRegionCombo.Items.Add("US (PPSA01650)")
[void]$bgRegionCombo.Items.Add("EU (PPSA01651)")
[void]$bgRegionCombo.Items.Add("JP (PPSA01652)")
$bgRegionCombo.SelectedIndex = 0
$tabBg.Controls.Add($bgRegionCombo)

# PNG File Path (Background)
$bgPngLabel = New-Object System.Windows.Forms.Label
$bgPngLabel.Location = New-Object System.Drawing.Point(15, 80)
$bgPngLabel.Size = New-Object System.Drawing.Size(350, 20)
$bgPngLabel.Text = "Background PNG Path (pic0.png):"
$tabBg.Controls.Add($bgPngLabel)

$bgPngBox = New-Object System.Windows.Forms.TextBox
$bgPngBox.Location = New-Object System.Drawing.Point(15, 103)
$bgPngBox.Size = New-Object System.Drawing.Size(290, 25)
$bgPngBox.Text = ""
$tabBg.Controls.Add($bgPngBox)

$bgPngBrowse = New-Object System.Windows.Forms.Button
$bgPngBrowse.Location = New-Object System.Drawing.Point(310, 102)
$bgPngBrowse.Size = New-Object System.Drawing.Size(55, 27)
$bgPngBrowse.Text = "..."
$tabBg.Controls.Add($bgPngBrowse)

$bgPngBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "PNG Files (*.png)|*.png|All Files (*.*)|*.*"
    $ofd.Title = "Select pic0.png"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $bgPngBox.Text = $ofd.FileName
    }
})

# DDS File Path (Background)
$bgDdsLabel = New-Object System.Windows.Forms.Label
$bgDdsLabel.Location = New-Object System.Drawing.Point(15, 145)
$bgDdsLabel.Size = New-Object System.Drawing.Size(350, 20)
$bgDdsLabel.Text = "Background DDS Path (pic0.dds):"
$tabBg.Controls.Add($bgDdsLabel)

$bgDdsBox = New-Object System.Windows.Forms.TextBox
$bgDdsBox.Location = New-Object System.Drawing.Point(15, 168)
$bgDdsBox.Size = New-Object System.Drawing.Size(290, 25)
$bgDdsBox.Text = ""
$tabBg.Controls.Add($bgDdsBox)

$bgDdsBrowse = New-Object System.Windows.Forms.Button
$bgDdsBrowse.Location = New-Object System.Drawing.Point(310, 167)
$bgDdsBrowse.Size = New-Object System.Drawing.Size(55, 27)
$bgDdsBrowse.Text = "..."
$tabBg.Controls.Add($bgDdsBrowse)

$bgDdsBrowse.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "DDS Files (*.dds)|*.dds|All Files (*.*)|*.*"
    $ofd.Title = "Select pic0.dds"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $bgDdsBox.Text = $ofd.FileName
    }
})

# Upload Button (Background)
$bgUploadBtn = New-Object System.Windows.Forms.Button
$bgUploadBtn.Location = New-Object System.Drawing.Point(15, 225)
$bgUploadBtn.Size = New-Object System.Drawing.Size(350, 45)
$bgUploadBtn.Text = "Upload Background(s)"
$bgUploadBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 122, 204)
$bgUploadBtn.ForeColor = [System.Drawing.Color]::White
$bgUploadBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

$bgUploadBtn.Add_Click({
    $PS5_IP = $ipBox.Text.Trim()
    $FTP_PORT = $portBox.Text.Trim()
    
    $pngFile = $bgPngBox.Text.Trim()
    $ddsFile = $bgDdsBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($PS5_IP)) { 
        [System.Windows.Forms.MessageBox]::Show("IP cannot be empty!", "Error", 'OK', 'Error'); return 
    }

    if ([string]::IsNullOrWhiteSpace($pngFile) -and [string]::IsNullOrWhiteSpace($ddsFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please choose at least one background file (PNG or DDS)!", "Error", 'OK', 'Error')
        return
    }
    
    $choice = $bgRegionCombo.SelectedItem.ToString()
    if ($choice -like "US*") { $APP_ID = "PPSA01650"; $REGION = "US" }
    elseif ($choice -like "EU*") { $APP_ID = "PPSA01651"; $REGION = "EU" }
    else { $APP_ID = "PPSA01652"; $REGION = "JP" }

    $tempBase = if ($baseDir) { $baseDir } else { $env:TEMP }
    $uploadedCount = 0

    try {
        $uploadTask = {
            param($localPath, $remoteName)
            if (-not (Test-Path $localPath)) { throw "File not found: $localPath" }
            $remotePath = "/user/appmeta/${APP_ID}/${remoteName}"

            # 1. Unlock
            $uCmd = "open $PS5_IP $FTP_PORT`nuser anonymous ""`nquote SITE CHMOD 777 $remotePath`nbye"
            $uFile = Join-Path $tempBase "unlock_b.txt"
            $uCmd | Out-File -FilePath $uFile -Encoding ASCII
            & ftp.exe -s:$uFile | Out-Null
            Remove-Item $uFile -ErrorAction SilentlyContinue

            # 2. Upload
            $webReq = [System.Net.FtpWebRequest]::Create("ftp://${PS5_IP}:${FTP_PORT}${remotePath}")
            $webReq.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $webReq.ContentLength = $bytes.Length
            $s = $webReq.GetRequestStream()
            $s.Write($bytes, 0, $bytes.Length)
            $s.Close()

            # 3. Relock
            $lCmd = "open $PS5_IP $FTP_PORT`nuser anonymous ""`nquote SITE CHMOD 444 $remotePath`nbye"
            $lFile = Join-Path $tempBase "lock_b.txt"
            $lCmd | Out-File -FilePath $lFile -Encoding ASCII
            & ftp.exe -s:$lFile | Out-Null
            Remove-Item $lFile -ErrorAction SilentlyContinue
        }

        # Upload PNG if provided
        if (-not [string]::IsNullOrWhiteSpace($pngFile)) {
            & $uploadTask $pngFile "pic0.png"
            $uploadedCount++
        }

        # Upload DDS if provided
        if (-not [string]::IsNullOrWhiteSpace($ddsFile)) {
            & $uploadTask $ddsFile "pic0.dds"
            $uploadedCount++
        }

        [System.Windows.Forms.MessageBox]::Show("$uploadedCount background file(s) updated successfully for YouTube $REGION ($APP_ID)!", "Success", 'OK', 'Information')
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("FTP Error: " + $_.Exception.Message, "Error", 'OK', 'Error')
    }
})
$tabBg.Controls.Add($bgUploadBtn)


# Add tabs to form
[void]$tabControl.TabPages.Add($tabIcon)
[void]$tabControl.TabPages.Add($tabBg)
$form.Controls.Add($tabControl)

[void]$form.ShowDialog()