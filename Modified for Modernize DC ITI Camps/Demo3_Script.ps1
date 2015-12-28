# ��ʾͨ��Dockerfile������������Nginx���񲢷��ʵĹ���
# ��������New-ContainerHost.ps1����ʱ���û��ָ��-SkipDocker flag����ô�ͻ������������м���docker 1.9.0-dev��
docker version
docker images # �鿴��ǰ��ӳ���ļ���ɾ���ոմ����Ĳ���image

# Ŀǰֱ����PS Session��Ӧ��cmd���������tty���⣬����Ҫ���
# docker run -it --name ignitedockerdemo windowsservercore cmd 

# ���ز���Nginx����������Demo���������Ŀ¼
New-Item -ItemType Directory c:\build\nginx\source -Force
wget -uri 'http://nginx.org/download/nginx-1.9.3.zip' -OutFile "c:\nginx-1.9.3.zip"
# �����ʾ���������ٶ�̫�������ñ����ļ�������ʽ
# Exit-PSSession
# Copy-Item -ToSession $s -Path .\nginx-1.9.3.zip -Destination c:\
# Enter-PSSession -Session $s
Expand-Archive -Path C:\nginx-1.9.3.zip -DestinationPath C:\build\nginx\source -Force

# ����Dockerfile����������ʾnginxӳ��
New-Item -Type File c:\build\nginx\dockerfile -Force
Set-Location -Path C:\build\nginx

@"
FROM windowsservercore
LABEL Description="nginx For Windows" Vendor="nginx" Version="1.9.3"
ADD source /nginx
WORKDIR /nginx/nginx-1.9.3
ENTRYPOINT ["cmd.exe","/k","nginx.exe"]
"@ | Out-File .\dockerfile -Encoding ASCII

# ͨ��dockerfile����ӳ��
docker build -t nginx_windows .

# �����ǰû�д����򴴽�����ǽ���ʹ�����������80�˿ڷ��������
if (!(Get-NetFirewallRule | where {$_.Name -eq "TCP80"})) {
    New-NetFirewallRule -Name "TCP80" -DisplayName "HTTP on TCP/80" -Protocol tcp -LocalPort 80 -Action Allow -Enabled True
}

# ͨ��ӳ������nginx����
docker run -t -d --name nginx_webcontainer -p 80:80 nginx_windows

# ��֤��ҳ����
Exit-PSSession 
curl -Uri $DemoVMIP

Enter-PSSession -Session $s

docker stop $(docker ps -qa)

docker rm $(docker ps -qa)

docker rmi nginx_windows

Exit-PSSession