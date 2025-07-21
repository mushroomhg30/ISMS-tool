# 檢查使用者是否擁有系統管理員權限
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "需要系統管理員權限執行此腳本！"
    
    # 以系統管理員權限重新執行腳本
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    
    Exit
}

#Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned


# 初始化進度條
$totalSteps = 6
$currentStep = 0

# Step 1: 取得電腦名稱和基本資訊
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 收集電腦資訊..." -PercentComplete (($currentStep / $totalSteps) * 100)

$computerName = hostname
$computerDesc = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -Property Description
$osVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseId | Select-Object -ExpandProperty ReleaseId) + " (" + (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name DisplayVersion | Select-Object -ExpandProperty DisplayVersion) + ")"
$osName = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
$domainName = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property Domain
$currentUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property UserName

# Step 2: 讀取螢幕保護逾時設置
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 檢查螢幕保護設置..." -PercentComplete (($currentStep / $totalSteps) * 100)

$path = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop\" 
$Name = "ScreenSaveTimeOut"
$getscreenvalue = (Get-ItemProperty -Path $Path -Name $Name).$Name
$itemname = "螢幕保護裝置逾時設置"

# Step 3: 收集更新紀錄和防火牆狀態
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 檢查更新紀錄與防火牆狀態..." -PercentComplete (($currentStep / $totalSteps) * 100)

$lastQualityUpdate = Get-WmiObject -Class Win32_QuickFixEngineering | Where-Object {$_.HotFixID -like "KB*"} | Sort-Object InstalledOn -Descending | Select-Object -First 1 | Select-Object -Property InstalledOn
$firewallStatus = Get-NetFirewallProfile | Select-Object -Property Name, Enabled

# Step 4: 檢查 NTP 主機和網路芳鄰
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 獲取 NTP 主機與網路芳鄰資訊..." -PercentComplete (($currentStep / $totalSteps) * 100)

$ntpServer = w32tm /query /source
$netshares = net share

# Step 5: 檢查特定服務和使用者資訊
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 檢查服務與密碼設置..." -PercentComplete (($currentStep / $totalSteps) * 100)

$lastPasswordSet = net user $env:USERNAME /domain | Select-String "上次設定密碼" | ForEach-Object { $_.ToString().Trim().Split(" ")[-3] }


# Step 6: 分析已安裝程式
$currentStep++
Write-Progress -Activity "系統資訊收集" -Status "步驟 ${currentStep}/${totalSteps}: 分析已安裝程式..." -PercentComplete (($currentStep / $totalSteps) * 100)

$csvUrl = "[google_sheet_url]"
$csvData = Invoke-RestMethod -Uri $csvUrl
$filters = $csvData | ConvertFrom-Csv | ForEach-Object { [regex]::Escape($_.FilterColumn) }
$filterRegex = ($filters -join "|")

# 32-bit registry path
$apps32 = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -match $filterRegex } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

# 64-bit registry path
$apps64 = Get-ItemProperty HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object { $_.DisplayName -match $filterRegex } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate

$apps = $apps32 + $apps64

# 清除進度條
Write-Progress -Activity "系統資訊收集" -Status "完成！" -PercentComplete 100

# 輸出結果
Write-Host "※1.電腦描述: $($computerDesc.Description)"
Write-Host "※2.電腦名稱: $computerName"
Write-Host "※3.作業系統版本: $osName $osVersion"
Write-Host "※4.加入的網域名稱: $($domainName.Domain)"
Write-Host "※5.目前登入的使用者: $($currentUser.UserName)"
Write-Host "※6. $itemname ： $getscreenvalue 秒"
Write-Host "※7.防火牆狀態："
$firewallStatus | Format-Table -AutoSize
Write-Host "※8.NTP 主機：$ntpServer"
Write-Host "※9.網路芳鄰開啟狀態："
$netshares | Format-Table -AutoSize
Write-Host "※10.最後一次變更密碼的日期為: $lastPasswordSet"
Write-Host "※11.最近的Windows Update時間： $($lastQualityUpdate.InstalledOn)`n"
Write-Host "※須關注的程式版本： $($apps | Sort-Object DisplayName | Format-Table -AutoSize | Out-String)"




$0401_results +=           "※1.電腦描述: $($computerDesc.Description)`n" 
$0401_results +=           "※2.電腦名稱: $computerName `n" 
$0401_results +=           "※3.作業系統版本: $osName $osVersion `n" 
$0401_results +=           "※4.加入的網域名稱: $($domainName.Domain)`n" 
$0401_results +=           "※5.目前登入的使用者: $($currentUser.UserName) `n" 
$0401_results +=           "※6. $itemname ： $getscreenvalue `n" 
$0401_results +=           "※7. 防火牆設定：`n $($firewallStatus | Format-Table -AutoSize | Out-String)"
$0401_results +=           "※8.NTP 主機：$ntpServer`n"
$0401_results +=           "※9.網路芳鄰開啟狀態： `n"
$0401_results +=           $($netshares  | Format-Table -wrap | Out-String)
$0401_results +=           "※10.最後一次變更密碼的日期為: $lastPasswordSet`n" 
$0401_results +=           "※11.Windows Update時間： $lastQualityUpdate`n`n`n"
$0401_results +=           "`程式安裝情形：`n $($apps | Sort-Object DisplayName | Format-Table -AutoSize | Out-String)`n" 


$timestamp = Get-Date -Format "MMdd-hhmm"           
#$0401_results | Out-File -FilePath "$($env:USERPROFILE)\Desktop\$computerName-$timestamp.txt"
Add-Type -AssemblyName System.Windows.Forms
$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveFileDialog.FileName = "$computerName-$timestamp.txt"
$saveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
$saveFileDialog.Title = "Save Results"
$saveFileDialog.InitialDirectory = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments)
if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    # 使用者選擇了保存位置,將結果寫入檔案
    $0401_results | Out-File -FilePath $saveFileDialog.FileName
    Write-Host "Results saved to: $($saveFileDialog.FileName)"
} else {
    Write-Host "Save operation cancelled by user."
}

Start-Process "control.exe" -ArgumentList "appwiz.cpl"
Start-Process "ms-settings:windowsupdate-history"
Start-Process -FilePath "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL inetcpl.cpl,,1"
Start-Process -FilePath "control.exe" -ArgumentList "desk.cpl,,@screensaver"
start winver 
start sysdm.cpl
start compmgmt.msc

pause