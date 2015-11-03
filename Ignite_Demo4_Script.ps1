# 初始化演示环境设置设置Nano映像路径，构建BaseVHD路径以及Nano VHD路径
Set-Location $env:USERPROFILE\Work\Ignite2016
$BasePath = New-Item -ItemType Directory .\NanoServer -Force | Select-Object -ExpandProperty FullName 
$ImagePath = 'C:\Users\shzhai.FAREAST\Work\MVA TBD\Windows Server 2016 TP\10514.0.150808-1529.TH2_RELEASE_SERVER_OEMRET_X64FRE_EN-US.ISO'
if (!(Get-DiskImage -ImagePath $ImagePath | Get-Volume)){ Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -PassThru }
$MediaPath = "$((Get-DiskImage -ImagePath $ImagePath | Get-Volume).DriveLetter)" + ":\"
$NanoVMName = 'IgniteNanoVM'
$VMPath = "C:\Users\Public\Documents\Hyper-V\Virtual Hard Disks\$NanoVMName"
if ($CurrentVM = Get-VM -Name $NanoVMName -ErrorAction SilentlyContinue) {
    if ($CurrentVM.State -ne "Off") {
        Stop-VM -VM $CurrentVM -TurnOff -Force
    }
    Remove-VM -VM $CurrentVM -Force -Verbose
} 
Remove-Item -Path $VMPath -Recurse -Force -ErrorAction SilentlyContinue


# 准备打包Nano VHD的脚本及运行环境
Copy-Item $MediaPath\NanoServer\*.ps1 .\ -Force

. .\convert-windowsimage.ps1
. .\new-nanoserverimage.ps1

# 创建Nano VHD，后期可以客户化（无人值守应答，加入域或静态IP设置等），演示中用到了最简单设置
New-NanoServerImage -MediaPath $MediaPath -BasePath $BasePath -TargetPath $VMPath `
-GuestDrivers -ReverseForwarders -ComputerName $NanoVMName -Language 'en-us' `
-AdministratorPassword ("ignite2016" | ConvertTo-SecureString -AsPlainText -Force) 


# Check Nano Server log
ise 'C:\Users\SHZHAI~1.FAR\AppData\Local\Temp\New-NanoServerImage.log'

# 创建Nano虚拟机
$NanoVHD = "$VMPath"+"\"+"$NanoVMName"+".vhd"
$vSwitchName = (Get-VMSwitch).Name
New-VM -Name $NanoVMName -MemoryStartupBytes 1GB -Generation 1 -VHDPath $NanoVHD -SwitchName $vSwitchName | Start-VM -Passthru


