#!/bin/bash

# DNSPod API密钥信息
API_ID="123456"
API_TOKEN="**************"

# DNSPod主域名和子域名
DOMAIN="example.com"
SUB_DOMAIN="www"

# 记录信息
RECORD_TYPE="A"
RECORD_LINE="默认"

# 日志文件路径
LOG_FILE="/var/log/ddns/running.log"
IP_CHANGE_LOG="/var/log/ddns/ip-change.log"
DIR="/var/log/ddns"


if [ ! -d "$DIR" ]; then
    echo "Directory $DIR does not exist"
    mkdir $DIR
else
    echo "Directory $DIR exists"
fi


if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
fi

[ -f "$IP_CHANGE_LOG" ] || touch "$IP_CHANGE_LOG"


# 获取WAN口IP地址
IPADDR=$(ifconfig pppoe-wan | grep "inet addr:" | cut -d: -f2 | awk '{print $1}')

# 获取日志中最后一个IP地址记录
LAST_IP=$(tail -n 1 "$IP_CHANGE_LOG"|awk '{print $3}')

# 检查是否需要更新IP地址
if [ "$LAST_IP" != "$IPADDR" ]; then
	# 更新IP地址记录
	echo "$(date +%Y-%m-%d\ %H:%M:%S) $IPADDR" >> "$IP_CHANGE_LOG"
	echo "$(date +%Y-%m-%d\ %H:%M:%S) - IP地址变化为：$IPADDR" >> "$LOG_FILE"

	# 获取域名ID
	DOMAIN_ID=$(curl -k -X POST "https://dnsapi.cn/Domain.Info" \
	     -d "login_token=$API_ID,$API_TOKEN" \
	     -d "format=json" \
	     -d "domain=${DOMAIN}" | jq -r '.domain.id')

	# 获取记录ID
	RECORD_ID=$(curl -k -X POST "https://dnsapi.cn/Record.List" \
	     -d "login_token=$API_ID,$API_TOKEN" \
	     -d "format=json" \
	     -d "domain_id=${DOMAIN_ID}" \
	     | jq -r ".records[] | select(.name == \"${SUB_DOMAIN}\") | select(.type == \"${RECORD_TYPE}\") | .id")
	echo ${API_ID,API_TOKEN}

	# 更新记录值
	curl -k -X POST "https://dnsapi.cn/Record.Modify" \
	     -d "login_token=$API_ID,$API_TOKEN" \
	     -d "format=json" \
	     -d "domain_id=${DOMAIN_ID}" \
	     -d "record_id=${RECORD_ID}" \
	     -d "sub_domain=${SUB_DOMAIN}" \
	     -d "record_type=${RECORD_TYPE}" \
	     -d "record_line=${RECORD_LINE}" \
	     -d "value=${IPADDR}"
else
    echo "$(date +%Y-%m-%d\ %H:%M:%S) - IP地址未发生变化，无需更新" >> "$LOG_FILE"
fi
