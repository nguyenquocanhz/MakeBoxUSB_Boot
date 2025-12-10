<#
    .SYNOPSIS
    USB TOOL PRO - ALL IN ONE
    Cong cu ho tro dong goi (.bin) va trien khai ra USB/HDD.
    
    .DESCRIPTION
    Phien ban gop:
    1. Menu lua chon chuc nang.
    2. Tu dong tai 7-Zip Portable.
    3. Ho tro nen mat khau & ma hoa header.
    4. Ho tro Format USB ExFAT & Bung nen tu dong.
    5. Ho tro tao USB/HDD Boot 2 PHAN VUNG.
    6. Nap Bootloader GRUB4DOS tu dong.
    7. Cho phep chon HDD/SSD (Tru o cai Win).
    8. Fix loi duong dan co ky tu dac biet [].
    9. Auto Scan ISO & File Picker.
    10. [NEW] Bang xac nhan thong tin truoc khi Format.
#>

# --- 0. FIX LOI FONT TIENG VIET (UNICODE) ---
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
    # Bo qua loi neu chay trong moi truong khong co Console
}

# --- 1. KHOI TAO & CHECK QUYEN ---
$Host.UI.RawUI.WindowTitle = "USB TOOL PRO - FULLSTACK EDITION"

# Load thu vien GUI de dung File Dialog
Add-Type -AssemblyName System.Windows.Forms

function Check-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (!$principal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Warning "Vui long chay Script duoi quyen Administrator de Format USB va ghi file he thong!"
        Write-Warning "Dang thu khoi dong lai voi quyen Admin..."
        Start-Sleep -s 2
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
        Exit
    }
}

Check-Admin

# --- 2. CORE: QUAN LY TOOLS (7-ZIP & BOOTICE) ---
$ToolsDir = "$PSScriptRoot\Tools"
if (-not (Test-Path -LiteralPath $ToolsDir)) { New-Item -ItemType Directory -Force -Path $ToolsDir | Out-Null }

function Get-7ZipPath {
    $local7zExe = "$ToolsDir\7z.exe"
    
    # Check cai dat san
    $installedPaths = @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")
    foreach ($path in $installedPaths) { if (Test-Path -LiteralPath $path) { return $path } }

    # Check portable
    if (Test-Path -LiteralPath $local7zExe) { return $local7zExe }

    # Tai moi
    Write-Host "[SYSTEM] Dang tai module nen (7-Zip Core)..." -ForegroundColor Cyan
    $url = "https://www.7-zip.org/a/7z2408-x64.msi"
    $tempMsi = "$env:TEMP\7z_install.msi"
    $tempExtract = "$env:TEMP\7z_extract"

    try {
        Invoke-WebRequest -Uri $url -OutFile $tempMsi -UseBasicParsing
        $argList = "/a `"$tempMsi`" TARGETDIR=`"$tempExtract`" /qn"
        Start-Process -FilePath "msiexec.exe" -ArgumentList $argList -Wait
        
        $extractedExe = Get-ChildItem -Path $tempExtract -Filter "7z.exe" -Recurse | Select-Object -First 1
        if ($extractedExe) {
            Copy-Item "$($extractedExe.DirectoryName)\*" -Destination $ToolsDir -Recurse -Force
            Remove-Item $tempMsi -Force; Remove-Item $tempExtract -Recurse -Force
            return "$ToolsDir\7z.exe"
        }
    }
    catch { Write-Error "Loi tai 7-Zip: $_"; Read-Host "Nhan Enter thoat"; Exit }
}

function Get-BooticePath {
    $localBootice = "$ToolsDir\BOOTICE.exe"
    if (Test-Path -LiteralPath $localBootice) { return $localBootice }

    Write-Host "[SYSTEM] Dang tai BOOTICE (Cong cu nap MBR/PBR)..." -ForegroundColor Cyan
    # Link tai Bootice (Backup from GitHub Archive) - File nay nhe (400KB)
    $url = "https://github.com/tuannvm/Shell-Tools/raw/master/BOOTICE.exe" 
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $localBootice -UseBasicParsing
        if (Test-Path -LiteralPath $localBootice) { return $localBootice }
        else { throw "Khong tim thay file sau khi tai." }
    } catch {
        Write-Warning "Khong the tu tai BOOTICE. Vui long chep thu cong file BOOTICE.exe vao thu muc:"
        Write-Warning $ToolsDir
        Read-Host "Nhan Enter sau khi da chep file..."
        if (Test-Path -LiteralPath $localBootice) { return $localBootice } else { return $null }
    }
}

$7zPath = Get-7ZipPath

# --- HELPER: CHON FILE (SCAN HOAC BROWSE) ---
function Select-SourceFile {
    param([string]$Extension)
    
    # 1. Scan file trong thu muc hien tai
    $files = @(Get-ChildItem -Path $PSScriptRoot -Filter $Extension -File)
    
    $selectedPath = ""

    if ($files.Count -gt 0) {
        Write-Host "`n[DANH SACH FILE TIM THAY]" -ForegroundColor Yellow
        for ($i = 0; $i -lt $files.Count; $i++) {
            Write-Host " [$($i+1)] $($files[$i].Name)" -ForegroundColor Cyan
        }
        Write-Host " [0] Chon file khac (Browse)..." -ForegroundColor Gray
        
        $choice = Read-Host " > Nhap so thu tu (Enter de chon [1])"
        if ($choice -eq "") { $choice = 1 }

        if ($choice -eq "0") {
            # Mo cua so Browse
            $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $fileDialog.InitialDirectory = $PSScriptRoot
            $fileDialog.Filter = "Files ($Extension)|$Extension|All files (*.*)|*.*"
            if ($fileDialog.ShowDialog() -eq 'OK') {
                $selectedPath = $fileDialog.FileName
            }
        }
        elseif ($files[$choice-1]) {
            $selectedPath = $files[$choice-1].FullName
        }
    } else {
        # Khong tim thay file nao -> Mo Browse luon
        Write-Host "`n[INFO] Khong tim thay file $Extension canh Script." -ForegroundColor DarkGray
        Write-Host "Dang mo cua so chon file..." -ForegroundColor Cyan
        Start-Sleep -m 500
        $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $fileDialog.InitialDirectory = $PSScriptRoot
        $fileDialog.Filter = "Files ($Extension)|$Extension|All files (*.*)|*.*"
        if ($fileDialog.ShowDialog() -eq 'OK') {
            $selectedPath = $fileDialog.FileName
        }
    }
    return $selectedPath
}

# --- 3. FUNCTION: DONG GOI (PACK) ---
function Show-PackMenu {
    Clear-Host
    Write-Host "=== [1] DONG GOI FOLDER THANH FILE .BIN ===" -ForegroundColor Green
    Write-Host "-------------------------------------------"
    
    $SourceFolder = Read-Host " > Keo tha FOLDER nguon vao day"
    $SourceFolder = $SourceFolder.Trim('"')
    if (-not (Test-Path -LiteralPath $SourceFolder)) { Write-Warning "Folder khong ton tai!"; Start-Sleep 2; return }

    $defaultName = Split-Path $SourceFolder -Leaf
    $OutputFilePath = Read-Host " > Nhap noi luu file .BIN (Enter de luu Desktop\$defaultName.bin)"
    if ($OutputFilePath -eq "") {
        $OutputFilePath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "$defaultName.bin")
    }
    if (-not $OutputFilePath.EndsWith(".bin")) { $OutputFilePath += ".bin" }

    $Password = Read-Host " > Nhap mat khau bao ve (Enter de bo qua)"
    
    Write-Host "`n[START] Dang nen du lieu (Ultra Mode)..." -ForegroundColor Cyan
    $7zArgs = "a -t7z `"$OutputFilePath`" `"$SourceFolder\*`" -mx9 -mmt -bsp1"
    if ($Password -ne "") { $7zArgs += " -p`"$Password`" -mhe=on" }

    $process = Start-Process -FilePath $7zPath -ArgumentList $7zArgs -Wait -NoNewWindow -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "`n[SUCCESS] Da tao file: $OutputFilePath" -ForegroundColor Green
    } else {
        Write-Error "Loi nen file (Code: $($process.ExitCode))"
    }
    Read-Host "`nNhan Enter de quay lai Menu..."
}

# --- 4. FUNCTION: TRIEN KHAI DATA (DEPLOY SOFT) ---
function Show-DeployMenu {
    Clear-Host
    Write-Host "=== [2] CHEP PHAN MEM .BIN RA USB/HDD (FORMAT ExFAT) ===" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------"

    # Auto Scan .BIN/.ISO
    $BinFilePath = Select-SourceFile "*.bin"
    if ($BinFilePath -eq "") { Write-Warning "Chua chon file nguon!"; Start-Sleep 1; return }
    Write-Host "Da chon: $BinFilePath" -ForegroundColor Green

    # Loc bo o C: (System Drive) khoi danh sach
    $sysDrive = $env:SystemDrive.Substring(0,1)
    
    Write-Host "`nDanh sach o dia (DA LOAI TRU O CHUA WINDOWS):"
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Name -ne $sysDrive }
    
    if ($drives) {
        $drives | Select-Object Name, @{N="Size(GB)";E={"{0:N2}" -f ($_.Used + $_.Free)/1GB}}, Root
    } else {
        Write-Warning "Khong tim thay USB hay o dia phu nao!"
        Read-Host; return
    }
    
    $UsbDriveLetter = Read-Host "`n > Nhap KY TU o dia dich (Vi du: E)"
    $UsbDriveLetter = $UsbDriveLetter.Substring(0,1).ToUpper()
    
    if ($UsbDriveLetter -eq $sysDrive) {
        Write-Warning "KHONG DUOC CHON O CHUA HE DIEU HANH (C:)!"
        Start-Sleep 2; return
    }

    $TargetDrive = "$($UsbDriveLetter):\"
    if (-not (Test-Path $TargetDrive)) { Write-Warning "O dia khong ton tai!"; Start-Sleep 2; return }

    # --- BANG XAC NHAN ---
    Write-Host "`n=== XAC NHAN THONG TIN TRIEN KHAI ===" -ForegroundColor Yellow
    Write-Host " 1. Nguon du lieu : $BinFilePath"
    Write-Host " 2. O dia dich    : $TargetDrive (Se bi FORMAT)"
    Write-Host " 3. Hanh dong     : Format ExFAT -> Bung nen du lieu"
    Write-Host "======================================="

    Write-Host "`n[CANH BAO] Toan bo du lieu tren o $TargetDrive se bi XOA SACH!" -ForegroundColor Red
    $confirm = Read-Host " > Go 'YES' de xac nhan thuc hien (hoac Enter de huy)"
    if ($confirm -ne 'YES') { Write-Host "Da huy tac vu."; return }

    # Format ExFAT
    Write-Host "`n[STEP 1] Dang Format o dia (ExFAT)..." -ForegroundColor Cyan
    try {
        Format-Volume -DriveLetter $UsbDriveLetter -FileSystem ExFAT -NewFileSystemLabel "SOFTWARE_DATA" -Confirm:$false | Out-Null
    } catch { Write-Error "Loi Format: $_"; Start-Sleep 3; return }

    # Extract
    Write-Host "[STEP 2] Dang bung nen du lieu..." -ForegroundColor Cyan
    $process = Start-Process -FilePath $7zPath -ArgumentList "x `"$BinFilePath`" -o`"$TargetDrive`" -y -bsp1" -Wait -NoNewWindow -PassThru

    if ($process.ExitCode -eq 0) {
        Write-Host "`n[SUCCESS] O dia da san sang!" -ForegroundColor Green
        Invoke-Item $TargetDrive
    } else {
        Write-Error "Loi bung file (Code: $($process.ExitCode))."
    }
    Read-Host "`nNhan Enter de quay lai Menu..."
}

# --- 5. FUNCTION: MAKE BOOTABLE USB/HDD (2 PARTITIONS + BOOTICE) ---
function Show-BootMenu {
    Clear-Host
    Write-Host "=== [3] TAO USB/HDD BOOT 2 PHAN VUNG CHUYEN NGHIEP ===" -ForegroundColor Magenta
    Write-Host " - Phan vung 1 (BOOT): FAT32, Set Active, GRUB4DOS"
    Write-Host " - Phan vung 2 (DATA): NTFS (Chua du lieu)"
    Write-Host "----------------------------------------------------"

    # [NEW] Auto Scan ISO
    $IsoFilePath = Select-SourceFile "*.iso"
    
    # Neu user an Cancel o cua so Browse
    if ($IsoFilePath -eq "") {
        $skipIso = Read-Host " > Ban khong chon file ISO. Tao USB Boot trang? (Y/N)"
        if ($skipIso -ne 'Y') { return }
        $IsoInfo = "Tao USB Boot trang (Khong co file ISO)"
    } else {
        Write-Host "Da chon ISO: $IsoFilePath" -ForegroundColor Green
        $IsoInfo = $IsoFilePath
    }
    
    # 1. Xac dinh Disk Number cua o chua Win de loai tru
    $sysDriveLetter = $env:SystemDrive.Substring(0,1)
    try {
        $sysDiskNumber = (Get-Partition -DriveLetter $sysDriveLetter).DiskNumber
    } catch { $sysDiskNumber = -1 }

    # 2. Liet ke toan bo Disk vat ly (Tru o Win)
    Write-Host "`nDanh sach O CUNG va USB kha dung (DA LOAI TRU O CHUA WINDOWS):" -ForegroundColor Yellow
    $disks = Get-Disk | Where-Object { $_.Number -ne $sysDiskNumber -and $_.OperationalStatus -eq 'Online' }
    
    if ($disks) {
        $disks | Format-Table -Property Number, FriendlyName, @{N="Size(GB)";E={"{0:N2}" -f ($_.Size/1GB)}}, BusType -AutoSize
    } else {
        Write-Warning "Khong tim thay o dia nao khac ngoai o cai Win!"
        Read-Host; return
    }

    $targetDiskNum = Read-Host "`n > Nhap DISK NUMBER (So o cot Number, Vi du: 1)"
    
    if ($targetDiskNum -eq $sysDiskNumber) {
        Write-Warning "KHONG DUOC CHON DISK CHUA HE DIEU HANH!"
        Start-Sleep 2; return
    }
    
    $diskInfo = $disks | Where-Object { $_.Number -eq $targetDiskNum }
    if (!$diskInfo) { Write-Warning "Disk Number khong hop le!"; Start-Sleep 2; return }

    Write-Host "`n[THIET LAP KICH THUOC PHAN VUNG BOOT]" -ForegroundColor Yellow
    $BootSizeMB = Read-Host " > Nhap dung luong phan vung BOOT (MB) [Mac dinh: 4024]"
    if ([string]::IsNullOrWhiteSpace($BootSizeMB)) { $BootSizeMB = 4024 }
    
    # --- HOI VE GRUB4DOS TRUOC ---
    $installGrub = Read-Host " > Ban co muon nap GRUB4DOS Bootloader khong? (Y/N)"
    
    # --- BANG XAC NHAN ---
    Write-Host "`n=== XAC NHAN QUY TRINH TAO BOOT ===" -ForegroundColor Yellow
    Write-Host " 1. File Nguon    : $IsoInfo"
    Write-Host " 2. O dia dich    : Disk $targetDiskNum - $($diskInfo.FriendlyName) ($("{0:N2}" -f ($diskInfo.Size/1GB)) GB)"
    Write-Host " 3. Cau truc      : 2 Phan vung (BOOT: ${BootSizeMB}MB FAT32 + DATA: NTFS)"
    Write-Host " 4. Bootloader    : $(if($installGrub -eq 'Y'){'Co (GRUB4DOS)'}else{'Khong'})"
    Write-Host " 5. Cac buoc      : Clean Disk -> Init MBR -> Chia Partition -> Bung ISO -> Nap MBR/PBR"
    Write-Host "==================================="

    Write-Host "`n[CANH BAO] O cung '$($diskInfo.FriendlyName)' se bi XOA SACH moi du lieu!" -ForegroundColor Red
    $confirm = Read-Host " > Go 'YES' de xac nhan thuc hien (hoac Enter de huy)"
    if ($confirm -ne 'YES') { Write-Host "Da huy tac vu."; return }

    # --- STEP 1: CLEAN & INIT ---
    Write-Host "`n[STEP 1] Khoi tao Disk (MBR)..." -ForegroundColor Magenta
    try {
        Clear-Disk -Number $targetDiskNum -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 3 
        
        $currentDisk = Get-Disk -Number $targetDiskNum
        if ($currentDisk.PartitionStyle -eq 'Raw') {
             Initialize-Disk -Number $targetDiskNum -PartitionStyle MBR -ErrorAction Stop
        } elseif ($currentDisk.PartitionStyle -eq 'GPT') {
             Set-Disk -Number $targetDiskNum -PartitionStyle MBR -ErrorAction Stop
        }
    } catch { 
        Write-Warning "Co loi nho khi khoi tao (Co the bo qua neu Disk da MBR): $_" 
    }

    # --- STEP 2: CREATE BOOT PARTITION ---
    Write-Host "[STEP 2] Tao phan vung BOOT (FAT32, Active)..." -ForegroundColor Magenta
    try {
        [uint64]$SizeInBytes = [uint64]$BootSizeMB * 1MB
        $bootPart = New-Partition -DiskNumber $targetDiskNum -Size $SizeInBytes -IsActive -AssignDriveLetter -ErrorAction Stop
        Format-Volume -Partition $bootPart -FileSystem FAT32 -NewFileSystemLabel "BOOT_PART" -Confirm:$false | Out-Null
        $bootLetter = ($bootPart | Get-Volume).DriveLetter + ":" 
    } catch { Write-Error "Loi tao Partition Boot: $_"; Start-Sleep 3; return }

    # --- STEP 3: CREATE DATA PARTITION ---
    Write-Host "[STEP 3] Tao phan vung DATA (NTFS)..." -ForegroundColor Magenta
    try {
        $dataPart = New-Partition -DiskNumber $targetDiskNum -UseMaximumSize -AssignDriveLetter
        Format-Volume -Partition $dataPart -FileSystem NTFS -NewFileSystemLabel "DATA_PART" -Confirm:$false | Out-Null
        $dataLetter = ($dataPart | Get-Volume).DriveLetter + ":"
    } catch { Write-Warning "Khong the tao DATA partition (Co the o dia day)." }

    # --- STEP 4: EXTRACT ISO ---
    if ($IsoFilePath -ne "" -and (Test-Path -LiteralPath $IsoFilePath)) {
        Write-Host "[STEP 4] Dang BUNG NEN (Extract) file ISO vao o BOOT ($bootLetter)..." -ForegroundColor Magenta
        Start-Process -FilePath $7zPath -ArgumentList "x `"$IsoFilePath`" -o`"$bootLetter\`" -y -bsp1" -Wait -NoNewWindow
    }

    # --- STEP 5: INSTALL GRUB4DOS ---
    if ($installGrub -eq 'Y') {
        $booticePath = Get-BooticePath
        if ($booticePath) {
            Write-Host "[STEP 5] Dang nap GRUB4DOS..." -ForegroundColor Cyan
            Write-Host " -> Writing MBR..."
            Start-Process -FilePath $booticePath -ArgumentList "/DISK=$targetDiskNum /mbr /install /type=GRUB4DOS /auto /quiet" -Wait -NoNewWindow
            Write-Host " -> Writing PBR..."
            Start-Process -FilePath $booticePath -ArgumentList "/DEVICE=$bootLetter /pbr /install /type=GRUB4DOS /auto /quiet" -Wait -NoNewWindow
            Write-Host " -> DONE!" -ForegroundColor Green
        }
    }

    Write-Host "`n[SUCCESS] Da hoan tat!" -ForegroundColor Green
    Write-Host " - BOOT: $bootLetter"
    if ($dataLetter) { Write-Host " - DATA: $dataLetter" }
    
    Read-Host "`nNhan Enter de quay lai Menu..."
}

# --- 6. MAIN MENU LOOP ---
do {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "    USB TOOL PRO - FULLSTACK EDITION    " -ForegroundColor Cyan
    Write-Host "========================================"
    Write-Host "Path Tools: $ToolsDir" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host " [1] Dong goi Folder -> File .BIN (Backup Soft)"
    Write-Host " [2] Chep File .BIN  -> USB/HDD Data (ExFAT)"
    Write-Host " [3] Tao USB/HDD Boot -> 2 Partition + GRUB4DOS"
    Write-Host " [4] Thoat (Exit)"
    Write-Host ""
    $choice = Read-Host " > Lua chon cua ban (1-4)"

    switch ($choice) {
        '1' { Show-PackMenu }
        '2' { Show-DeployMenu }
        '3' { Show-BootMenu }
        '4' { Write-Host "Goodbye!"; exit }
        default { Write-Warning "Lua chon khong hop le!" ; Start-Sleep 1 }
    }
} while ($true)