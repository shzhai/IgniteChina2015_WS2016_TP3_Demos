# 演示通过Dockerfile创建容器并打开Nginx服务并访问的过程
# 首先在在New-ContainerHost.ps1创建时如果没有指定-SkipDocker flag，那么就会在虚拟机打包中加入docker 1.9.0-dev版
docker version
docker images # 查看当前的映像文件，删除刚刚创建的测试image

# 目前直接在PS Session中应用cmd交互会出现tty问题，还需要检查
# docker run -it --name ignitedockerdemo windowsservercore cmd 

# 下载并打开Nginx服务器包到Demo虚拟机本地目录
New-Item -ItemType Directory c:\build\nginx\source
wget -uri 'http://nginx.org/download/nginx-1.9.3.zip' -OutFile "c:\nginx-1.9.3.zip"
# 如果演示环境下载速度太慢，改用本地文件拷贝方式
# Exit-PSSession
# Copy-Item -ToSession $s -Path .\nginx-1.9.3.zip -Destination c:\
# Enter-PSSession -Session $s
Expand-Archive -Path C:\nginx-1.9.3.zip -DestinationPath C:\build\nginx\source -Force

# 创建Dockerfile用于生成演示nginx映像
New-Item -Type File c:\build\nginx\dockerfile
Set-Location -Path C:\build\nginx

@"
FROM windowsservercore
LABEL Description="nginx For Windows" Vendor="nginx" Version="1.9.3"
ADD source /nginx
WORKDIR /nginx/nginx-1.9.3
ENTRYPOINT ["cmd.exe","/k","nginx.exe"]
"@ | Out-File .\dockerfile -Encoding ASCII

# 通过dockerfile创建映像
docker build -t nginx_windows .

# 如果当前没有创建则创建防火墙访问规则允许外网80端口访问虚拟机
if (!(Get-NetFirewallRule | where {$_.Name -eq "TCP80"})) {
    New-NetFirewallRule -Name "TCP80" -DisplayName "HTTP on TCP/80" -Protocol tcp -LocalPort 80 -Action Allow -Enabled True
}

# 通过映像运行nginx容器
docker run -t -d --name nginx_webcontainer -p 80:80 nginx_windows

# 验证网页访问
Exit-PSSession 
curl -Uri $DemoVMIP

