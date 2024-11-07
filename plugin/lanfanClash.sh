#!/bin/bash
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
purple='\033[0;35m'
blue='\033[0;34m'

arch=$(uname -m)
if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
   arch="amd64"
elif [[ $arch == "i686" || $arch == "i386" ]]; then
   arch="386"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
   arch="arm64"
else
   arch="amd64"
   echo -e "${red}检测架构失败，将使用默认架构: ${arch}${plain}"
   read "回车以继续"
fi
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "${blue}请手动执行下面的命令来运行脚本（并直接输入密码后回车以继续脚本）：${plain}"
    echo "-------------------------------"
    echo -e "${purple}sudo ./lanfanClash.sh${plain}"
    echo "-------------------------------"
    exit 1
fi

pre_setup () {
    apt --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Using apt"
      tool="apt"
    fi
    dnf --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Using dnf"
      tool="dnf"
    fi
    yum --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Using yum"
      tool="yum"
    fi
    zypper --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Using zypper"
      tool="zypper"
    fi
    pacman --version > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "Using pacman"
      steamos-readonly disable
      tool="pacman"
    fi
    [ ! -n "$tool" ] && exit 1
    gzip --version > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "gzip is not installed. Installing..."
        $tool install gzip -y
    fi
    wget --version > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "wget is not installed. Installing..."
        $tool install wget -y
    fi
    mkdir -p /etc/clash
    touch /etc/clash/.sublink
    chmod 666 /etc/clash/.sublink
    modify_sublink
}

install_clash () {
  wget --no-check-certificate --no-proxy -O /usr/local/clash.gz https://download.lanfan.info/download/clash/clash-linux-${arch}-last.gz > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
     rm -rf /usr/local/clash.gz
     rm -rf /usr/local/clash
     echo -e "${red}下载 clash 失败，请检查你的网络状况，或稍后再试${plain}"
     exit 1
  fi
  wget --no-check-certificate --no-proxy -O /usr/local/dash.tar.gz https://download.lanfan.info/download/clash/dash.tar.gz > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
     rm -rf /usr/local/dash.tar.gz
     rm -rf /usr/local/dash
     echo -e "${red}下载 clash-dash 包 失败，请检查你的网络状况，或稍后再试${plain}"
     exit 1
  fi
  wget --no-check-certificate --no-proxy -O /usr/local/clash-dashboard.gz https://download.lanfan.info/download/clash/clash-dashboard-${arch}.gz > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
     rm -rf /usr/local/clash-dashboard.gz
     rm -rf /usr/local/clash-dashboard
     echo -e "${red}下载 clash-dash 失败，请检查你的网络状况，或稍后再试${plain}"
     exit 1
  fi
  gzip -d /usr/local/clash.gz -f
  gzip -d /usr/local/clash-dashboard.gz -f
  mkdir -p /usr/local/dash
  tar -xzf /usr/local/dash.tar.gz -C /usr/local
  chmod +x /usr/local/clash
  chmod +x /usr/local/clash-dashboard
}

download_mmdb () {
  wget --no-check-certificate --no-proxy -O /etc/clash/Country.mmdb "https://download.lanfan.info/download/clash/Country.mmdb" > /dev/null 2>&1
  if [[ $? -ne 0 ]]; then
     echo -e "${red}下载 Country.mmdb 失败，请检查你的网络状况，或稍后再试${plain}"
     exit 1
  fi
}

update_sublink () {
    sublink=`cat /etc/clash/.sublink`
    if [[ $? -ne 0 ]]; then
        echo -e "${red}订阅链接不存在，请重新导入订阅链接!${plain}"
        exit 1
    fi
    # shellcheck disable=SC2070
    if [ ! -n $sublink ]; then
        echo -e "${red}订阅链接不存在，请重新导入订阅链接!${plain}"
        exit 1
    fi
    wget --no-check-certificate --no-proxy --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" -O /etc/clash/config.yaml "$sublink&linux=1" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
       echo -e "${red}更新订阅失败，请检查你的网络状况，或稍后再试${plain}"
       exit 1
    fi

    secret_uuid=$(grep -oE "secret: '([^']+)'" /etc/clash/config.yaml | awk -F"'" '{print $2}')

    restart_clash
    echo -e "${blue}手动订阅更新成功！${plain}"
}

modify_sublink () {
    echo -e "${purple}请在蓝帆首页左下方'订阅链接'栏内底部复制Clash的订阅链接并粘贴${plain}"
    read -p "请粘贴订阅链接: " sublink
    if [[ $sublink == *"lanfan"* ]]; then
      wget --no-check-certificate --no-proxy --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" -O /etc/clash/config.yaml "$sublink&linux=1" > /dev/null 2>&1
      if [ -d "/etc/clash/" ]; then
        mkdir -p /etc/clash
      fi
      if [[ $? -ne 0 ]]; then
        echo -e "${red}获取订阅失败，请检查你的网络状况，或稍后再试${plain}"
        exit 1
      fi
      secret_uuid=$(grep -oE "secret: '([^']+)'" /etc/clash/config.yaml | awk -F"'" '{print $2}')
      echo "$sublink" > /etc/clash/.sublink
      echo -e "${blue}成功获取订阅！${plain}"
    else
      echo -e "${red}错误的订阅链接，请重新导入！${plain}"
      exit 1
    fi
}

run_clash () {
    setsid /usr/local/clash -d /etc/clash >> /dev/null 2>&1 &
    setsid /usr/local/clash-dashboard >> /dev/null 2>&1 &
    sleep 2
    ps -ef | grep "clash -d" | grep -v grep >> /dev/null 2>&1
    ps -ef | grep "clash-dashboard" | grep -v grep >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${green}clash启动成功！${plain}"
    else
        echo -e "${red}clash主程序启动失败！${plain}"
    fi
    if [ $? -eq 0 ]; then
        echo -e "${green}clash-dash管理页面启动成功！请打开 http://127.0.0.1:9991/#/?host=127.0.0.1&port=9990&secret=$secret_uuid 进行节点选择${plain}"
    else
        echo -e "${red}clash-dash管理页面启动失败！${plain}"
    fi
}

status_clash () {
    status="${yellow}未运行${plain}"
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        status="${green}clash主程序运行中...${plain}"
    fi
}

status_clash_dash () {
    dash_status="${yellow}未运行${plain}"
    clash_dash_info=`ps -ef | grep "clash-dashboard" | grep -v grep`
    if [ $? -eq 0 ]; then
        dash_status="${green}clash管理页面运行中...${plain}"
    fi
}

stop_clash () {
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        pids=$(echo "$clash_info" | awk '{print $2}')
        # 循环遍历PID并终止进程
        for clash_pid in $pids; do
            kill -9 "$clash_pid"
            echo -e "${green}停止成功！${plain}"
        done
    fi
    clash_dash_info=`ps -ef | grep "clash-dashboard" | grep -v grep`
    if [ $? -eq 0 ]; then
        clash_dash_pid=`echo "$clash_dash_info" | tr -s " " | cut -d " " -f2`
        kill -9 "$clash_dash_pid"
    fi
    echo -e "${green}停止成功！${plain}"
}

restart_clash () {
    clash_info=`ps -ef | grep "clash -d" | grep -v grep`
    if [ $? -eq 0 ]; then
        pids=$(echo "$clash_info" | awk '{print $2}')
        # 循环遍历PID并终止进程
        for clash_pid in $pids; do
            kill -9 "$clash_pid"
            echo -e "${green}停止成功！${plain}"
        done
    fi
    clash_dash_info=`ps -ef | grep "clash-dashboard" | grep -v grep`
    if [ $? -eq 0 ]; then
        clash_dash_pid=`echo "$clash_dash_info" | tr -s " " | cut -d " " -f2`
        kill -9 "$clash_dash_pid"
    fi
    setsid /usr/local/clash -d /etc/clash >> /dev/null 2>&1 &
    ps -ef | grep "clash -d" | grep -v grep >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${green}重启成功！${plain}"
    else
        echo -e "${red}重启失败！${plain}"
    fi
    setsid /usr/local/clash-dashboard >> /dev/null 2>&1 &
    ps -ef | grep "clash-dashboard" | grep -v grep >> /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${green}clash-dash管理页面重启成功！请打开 http://127.0.0.1:9991/#/?host=127.0.0.1&port=9990&secret=$secret_uuid 进行节点选择${plain}"
    else
        echo -e "${red}clash-dash管理页面重启失败！${plain}"
    fi
}

update_sh(){
    wget --no-check-certificate --no-proxy -O lanfanClash.sh "https://download.lanfan.info/download/clash/lanfanClash.sh" && chmod +x lanfanClash.sh && ./lanfanClash.sh
}

setup_crontab () {
    crontab -l > /tmp/crontab.bak
    echo "0 3 * * * bash $PWD/$0 update_sublink" >> /tmp/crontab.bak
    crontab /tmp/crontab.bak
}

# 检查代理是否已开启
check_proxy() {
    if ! command -v gsettings > /dev/null 2>&1; then
        proxy_status="${green}非GNOME桌面环境${plain}"
    else
        mode=$(gsettings get org.gnome.system.proxy mode)
        if [ "$mode" = "'manual'" ]; then
            proxy_status="${green}当前用户的浏览器代理已开启${plain}"
        else
            proxy_status="${yellow}当前用户的浏览器代理未开启${plain}"
        fi
    fi
}

check_terminal_proxy() {
    if [ -n "$HTTP_PROXY" ] || [ -n "$http_proxy" ] || [ -n "$HTTPS_PROXY" ] || [ -n "$https_proxy" ] || [ -n "$all_proxy" ] || [ -n "$ALL_PROXY" ]; then
        terminal_proxy="${green}终端代理已开启。${plain}"
    else
        terminal_proxy="${yellow}终端代理未开启${plain}"
    fi
}

enable_terminal_proxy() {
    echo -e "${blue}请手动执行下面的命令在你需要的终端中，可使其http、https协议走代理（默认非全局模式！可在管理页修改）：${plain}"
    echo "-------------------------------"
    echo -e "${purple}export https_proxy=http://127.0.0.1:7890 http_proxy=http://127.0.0.1:7890 all_proxy=socks5://127.0.0.1:7890${plain}"
    echo "-------------------------------"
#    echo "export http_proxy=http://127.0.0.1:7890" > set_terminal_proxy.sh
#    echo "export https_proxy=http://127.0.0.1:7890" >> set_terminal_proxy.sh
#    echo "export all_proxy=socks5://127.0.0.1:7890" >> set_terminal_proxy.sh
#    source set_terminal_proxy.sh
#    rm set_terminal_proxy.sh
#    echo -e "${green}当前终端代理已开启。${plain}"
}

disable_terminal_proxy() {
    echo -e "${blue}请手动执行下面的命令来取消终端的代理：${plain}"
    echo "-------------------------------"
    echo -e "${purple}unset  http_proxy  https_proxy  all_proxy${plain}"
    echo "-------------------------------"
#    echo "unset http_proxy https_proxy all_proxy" > unset_terminal_proxy.sh
#    unset http_proxy https_proxy all_proxy
#    rm unset_terminal_proxy.sh
#    echo -e "${green}当前终端代理已关闭。${plain}"
}

# 关闭系统代理
disable_proxy() {
if command -v gsettings > /dev/null 2>&1; then
    echo -e "${blue}请手动执行下面的命令来关闭GNOME系统代理(浏览器代理)：${plain}"
    echo "-------------------------------"
    echo -e "${purple}gsettings set org.gnome.system.proxy mode 'none'${plain}"
    echo "-------------------------------"
else
    echo -e "${red}非GNOME桌面环境${plain}"
fi
}

# 开启代理
enable_proxy() {
if command -v gsettings > /dev/null 2>&1; then
    echo -e "${blue}请手动执行下面的命令来开启GNOME系统代理(浏览器代理)：${plain}"
    echo "-------------------------------"
    echo -e "${purple}gsettings set org.gnome.system.proxy.http host '127.0.0.1' && gsettings set org.gnome.system.proxy.http port 7890 && gsettings set org.gnome.system.proxy.https host '127.0.0.1' && gsettings set org.gnome.system.proxy.https port 7890 && gsettings set org.gnome.system.proxy mode 'manual'${plain}"
    echo "-------------------------------"
else
    echo -e "${red}非GNOME桌面环境${plain}"
fi
}

tun_mode_on(){
sed -i '/tunmode/s/false/true/' "/etc/clash/config.yaml"
restart_clash
echo -e "${green}TUN模式已开启，请直接测试使用${plain}"
}

tun_mode_off(){
sed -i '/tunmode/s/true/false/' "/etc/clash/config.yaml"
restart_clash
echo -e "${yellow}TUN模式已关闭${plain}"
}

delete_sh () {
disable_proxy
disable_terminal_proxy
stop_clash
rm -rf /etc/clash
rm -rf /usr/local/clash.gz
rm -rf /usr/local/clash
rm -rf /usr/local/dash.tar.gz
rm -rf /usr/local/dash
rm -rf /usr/local/clash-dashboard.gz
rm -rf /usr/local/clash-dashboard
}

if [ $# -gt 0 ]; then
    case $1 in
	"update_sublink")
        update_sublink
        restart_clash
	exit 0
	;;
  "u")
        update_sh
	exit 0
	;;
        *)
        ;;
    esac
fi

while true
do

clear
echo -e "lanfanClash Linux版 Clash 管理脚本 ${green}v0.0.3${plain}"
echo "-------------------------------"
echo " 1、安装 Clash（首次执行）"
echo " 2、运行"
echo " 3、停止"
echo " 4、重启"
echo -e " t、${green}开启TUN模式(直接接管全局流量，无需配置下方5-9选项)${plain}"
echo -e "tf、${yellow}关闭TUN模式${plain}"
echo -e " 5、${green}命令行临时代理(当前终端&临时生效)${plain}"
echo " 6、取消命令行临时代理"
echo -e " 7、${green}开启GNOME系统代理(浏览器代理)${plain}"
echo " 8、关闭GNOME系统代理"
echo " 9、永久命令行代理"
echo "10、取消永久命令行代理"
echo -e "11、${green}更新订阅链接（建议时常更新）${plain}"
echo "12、修改订阅链接"
echo " 0、退出脚本"
echo -e " u、${green}更新脚本${plain}"
echo -e " d、${green}删除Clash${plain}"
echo "-------------------------------"
if [[ -e /usr/local/clash ]]; then
status_clash
status_clash_dash
#check_proxy
#check_terminal_proxy
echo -e "Clash主程序运行状态：$status"
echo -e "Clash管理页面状态：$dash_status"
#echo -e "GNOME系统代理状态：$proxy_status"
#echo -e "终端代理状态：$terminal_proxy"
else
echo -e "${purple}首次使用请按 1 回车${plain}"
fi
if [[ -e /etc/clash/config.yaml ]]; then
secret_uuid=$(grep -oE "secret: '([^']+)'" /etc/clash/config.yaml | awk -F"'" '{print $2}')
echo -e "Clash管理地址：${blue}http://127.0.0.1:9991/#/?host=127.0.0.1&port=9990&secret=$secret_uuid${plain}"
fi
echo "-------------------------------"

read -e -p "请输入要执行的操作前面的代号: " choise_num
case $choise_num in
    0)
    exit 0
    ;;
    1)
    echo -e "${red}使用架构: ${arch}${plain}"
    stop_clash
    pre_setup
    install_clash
    download_mmdb
    run_clash
    #enable_terminal_proxy
    #enable_proxy
    echo -e "${yellow}请用浏览器访问 http://127.0.0.1:9991/#/?host=127.0.0.1&port=9990&secret=$secret_uuid 管理网页来修改节点${plain}"
    read -p "回车退出 "
    continue
    ;;
    2)
    run_clash
    read -p "回车退出 "
    continue
    ;;
    3)
    stop_clash
    echo -e "${blue}请手动执行下面的命令来取消当前终端的临时代理：${plain}"
    echo "-------------------------------"
    echo -e "${purple}unset  http_proxy  https_proxy  all_proxy${plain}"
    echo "-------------------------------"
    continue
    ;;
    4)
    restart_clash
    read -p "回车退出 "
    continue
    ;;
    5)
    enable_terminal_proxy
    break
    ;;
    6)
    disable_terminal_proxy
    break
    ;;
    7)
    enable_proxy
    break
    ;;
    8)
    disable_proxy
    break
    ;;
    9)
    if [[ -f /etc/bash.bashrc ]]; then
      # Arch Linux
      echo "export http_proxy=http://127.0.0.1:7890" | tee -a /etc/bash.bashrc
      echo "export https_proxy=http://127.0.0.1:7890" | tee -a /etc/bash.bashrc
      echo "export all_proxy=socks5://127.0.0.1:7890" | tee -a /etc/bash.bashrc
      source /etc/bash.bashrc
    echo -e "${blue}请手动执行下面的命令来生效或重启生效：${plain}"
    echo "-------------------------------"
    echo -e "${purple}source /etc/bash.bashrc${plain}"
    echo "-------------------------------"
    elif [[ -f /etc/profile ]]; then
      # CentOS、Fedora 和其他基于 systemd 的发行版
      echo "export http_proxy=http://127.0.0.1:7890" | tee -a /etc/profile
      echo "export https_proxy=http://127.0.0.1:7890" | tee -a /etc/profile
      echo "export all_proxy=socks5://127.0.0.1:7890" | tee -a /etc/profile
      source /etc/profile
    echo -e "${blue}请手动执行下面的命令来生效或重启生效：${plain}"
    echo "-------------------------------"
    echo -e "${purple}source /etc/profile${plain}"
    echo "-------------------------------"
    elif [[ -f /etc/environment ]]; then
      # Ubuntu、Debian 和其他基于 systemd 的发行版
      echo "http_proxy=http://127.0.0.1:7890" | tee -a /etc/environment
      echo "https_proxy=http://127.0.0.1:7890" | tee -a /etc/environment
      echo "all_proxy=socks5://127.0.0.1:7890" | tee -a /etc/environment
      source /etc/environment
    echo -e "${blue}请手动执行下面的命令来生效或重启生效：${plain}"
    echo "-------------------------------"
    echo -e "${purple}source /etc/environment${plain}"
    echo "-------------------------------"
    else
      echo -e "${red}无法确定发行版或找到配置文件。请手动设置终端代理。${plain}"
      exit 1
    fi
    break
    ;;
    10)
    sed -i '/export http_proxy=/d' /etc/profile
    sed -i '/export https_proxy=/d' /etc/profile
    sed -i '/export all_proxy=/d' /etc/profile
    sed -i '/export http_proxy=/d' /etc/bash.bashrc
    sed -i '/export https_proxy=/d' /etc/bash.bashrc
    sed -i '/export all_proxy=/d' /etc/bash.bashrc
    sed -i '/http_proxy=/d' /etc/environment
    sed -i '/https_proxy=/d' /etc/environment
    sed -i '/all_proxy=/d' /etc/environment
    source /etc/profile
    source /etc/environment
    source /etc/bash.bashrc
    echo -e "${blue}请手动执行下面的命令来取消：${plain}"
    echo "-------------------------------"
    echo -e "${purple}source /etc/profile && source /etc/environment && source /etc/bash.bashrc && unset  http_proxy  https_proxy  all_proxy${plain}"
    echo "-------------------------------"
    break
    ;;
    11)
    update_sublink
    read -p "回车退出 "
    continue
    ;;
    12)
    modify_sublink
    restart_clash
    read -p "回车退出 "
    continue
    ;;
    u)
    update_sh
    exit 1
    ;;
    t)
    tun_mode_on
    exit 1
    ;;
    tf)
    tun_mode_off
    exit 1
    ;;
    d)
    delete_sh
    exit 1
    ;;
    *)
    exit 1
    ;;
esac
done