# 回顾Demo1中创建整个TP3演示环境的脚本New-ContainerHost.ps1内容，确认在当前已经下载影像并加载临时制作的vhd的情况下，无需再次下载和加载文件的部分

# 下面第一个演示创建容器的速度和容器环境与外部的隔离主机和其他容器的隔离性
# 通过PowerShell进行基本的容器操作和管理
# 通过 Ctrl+R 用于全屏交互展示 （Result View)

# 当前版本PowerShell容器模块支持的Cmdlets
Get-Command -Module Containers

# 获取本机的基础映像
Get-ContainerImage | Format-Table -AutoSize 

# 获取当前虚拟机的虚拟交换机对象
$DemoVMSwitch = Get-VMSwitch

# 通过现有的Windows Server Core映像创建测试容器
$baseimg = (Get-ContainerImage)[0]
foreach ($i in 1..2) { New-Container -Name IginiteDemoContainer-$i -ContainerImage $baseimg -Verbose -Confirm:$false | Start-Container }
$containers = Get-Container | Sort-Object 

# 连接第一个容器进行破坏性操作
Enter-PSSession -ContainerId $containers[0].ContainerId -RunAsAdministrator

.\systeminfo.exe
.\reg.exe DELETE HKLM\Software /f
.\systeminfo.exe
.\help.exe
.\reg.exe

# 连接本机，连接另一个容器检查
Exit-PSSession
Enter-PSSession -ContainerId $containers[1].ContainerId -RunAsAdministrator
systeminfo.exe

# 在新的容器中添加一个文本文件
Get-WmiObject -Class Win32_OperatingSystem  > c:\sysinfo.txt
type c:\sysinfo.txt
Exit-PSSession


# 通过新的容器产生一个新的映像，并加入本地映像库中
Stop-Container -Container $containers[1]
New-ContainerImage -Container $containers[1] -Name IgniteDemoImage -Publisher IgniteDemo -Version 1.0.0.0

# 通过新的映像创建容器
New-Container -Name "IgniteDemoContainer-$($i+1)" -ContainerImageName IgniteDemoImage -SwitchName $DemoVMSwitch.Name | Start-Container

# 访问新的容器，检查之前映像中写入的sysinfo文件
$containers = Get-Container | Sort-Object
Enter-PSSession -ContainerId $containers[-1].ContainerId -RunAsAdministrator
type c:\sysinfo.txt
Exit-PSSession

# 删除所有测试容器
Get-Container | Stop-Container -TurnOff -Passthru 
Get-Container | Remove-Container -Force

# 删除测试容器映像
Remove-ContainerImage -Name IgniteDemoImage -Force
 




