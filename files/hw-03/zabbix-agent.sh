# repo override
#kz
sed -i 's/us.archive.ubuntu.com/mirror.hoster.kz/g' /etc/apt/sources.list
#ru
#sed -i 's/us.archive.ubuntu.com/mirror.linux-ia64.org/g' /etc/apt/sources.list

useradd $1 -s /bin/bash -d /home/test
mkdir /home/test
chown -R test:test /home/test
echo ''$1'    ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

usermod --password $(openssl passwd -6 $2) root
usermod --password $(openssl passwd -6 $2) $1

if [ $3 == "true" ]; then apt upgrade -y; else echo '$3'=$3; fi

rm -Rf /etc/hosts

echo "127.0.0.1	localhost.localdomain	localhost" >> /etc/hosts
echo "$5	$4.localdomain	$4" >> /etc/hosts

echo "*******************************************************************************"
echo "************************** INSTALLING ZABBIX-AGENT ****************************"
echo "*******************************************************************************"
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu24.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu24.04_all.deb
apt update 
apt install zabbix-agent -y
sed -i "s/Server=127.0.0.1/Server=$6/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/ServerActive=127.0.0.1/# ServerActive=127.0.0.1/g" /etc/zabbix/zabbix_agentd.conf


if [[ ! -e /etc/zabbix/zabbix_agentd.d/custome_parametrs.conf ]];
then
cat > /etc/zabbix/zabbix_agentd.d/custome_parametrs.conf << 'EOF'
UserParameter=name_date[*], bash /etc/zabbix/zabbix_agentd.d/name_date.sh $1 $2
UserParameter=ping_py[*], python3 /etc/zabbix/zabbix_agentd.d/py_script.py -ping $1
UserParameter=simple_print_py[*], python3 /etc/zabbix/zabbix_agentd.d/py_script.py -simple_print $1
UserParameter=fio_or_date_print_py[*], python3 /etc/zabbix/zabbix_agentd.d/py_script.py $1
EOF
fi 

if [[ ! -e /etc/zabbix/zabbix_agentd.d/name_date.sh ]];
then
cat > /etc/zabbix/zabbix_agentd.d/name_date.sh << 'EOF'
#!/bin/bash
VALID_ARG=(1 2)

is_valid_args(){
	local arg="$1"
	for v in "${VALID_ARG[@]}"; do
		if [[ "$v" == "$arg" ]]; then
			return 0
		fi
	done
	return 1
}

custom_parameters(){
    local is_first=true

    for arg in "$@"; do

        if [[ "$is_first" == false ]]; then
            echo -n " "
        fi

        case "$arg" in
            ("1") echo -n "Сидоров Борис Сергеевич";;
            ("2") echo -n "$(date "+%Y-%m-%d %H:%M:%S")";;
        esac

        is_first=false
    done 
    echo           
}

all_valid=true
for arg in "$@"; do
    if ! is_valid_args "$arg"; then
        echo "Invalid argument: $arg"
        all_valid=false
    fi
done

if [[ "$#" -gt 0 && "$#" -lt 3 && "$all_valid" == true ]]; then
    if is_valid_args "$1"; then
        custom_parameters "$@"
    else echo "Invalid argument: $1"
    fi
else echo "Usage: <1|2>"
fi
EOF
fi

if [[ ! -e /etc/zabbix/zabbix_agentd.d/py_script.py ]];
then
cat > /etc/zabbix/zabbix_agentd.d/py_script.py << 'EOF'
import sys
import os
import re
import datetime
match sys.argv[1]:
	case "-ping":
		result=os.popen("ping -c 1 " + sys.argv[2]).read() # Делаем пинг по заданному адресу
		result=re.findall(r"time=(.*) ms", result) # Выдёргиваем из результата время
		print(result[0]) # Выводим результат в консоль
	
	case "-simple_print":
		print(sys.argv[2]) # Выводим в консоль содержимое sys.arvg[2]

	case "1":
		print("Сидоров Борис Сергеевич") # Выводить в консоль ФИО

	case "2":
		current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
		print(current_time) # Выводить в консоль дату и время

	case _: # Во всех остальных случаях
		print(f"unknown input: {sys.argv[1]}") # Выводим непонятый запрос в консоль
EOF
fi

systemctl restart zabbix-agent
systemctl enable zabbix-agent

echo "*******************************************************************************"
echo "********************************* END *****************************************"
echo "*******************************************************************************"