#!/bin/sh
set -e
PATH=/sbin:/bin:/usr/bin

CLEAN_FLAG=''
PORT=''
HOST=''
HOME="/home/minima"
CONNECTION_HOST=''
CONNECTION_PORT=''
SLEEP=''
RPC=''

print_usage() {
  printf "Usage: Setups a new minima service for the specified port, default 9121 \n \t -c REQUIRED connection host and port HOST:PORT \n \t -u flag Use unsecure p2p version with rpc ports active, ignored if -a isn't also set \n \t -x flag enable clean flag \n \t -p minima port to use eg. -p 9121 \n \t -h minima home directory eg -h /home/minima \n \t -a use the p2p alphas \n"
}

while getopts ':xsc::p:r:d:h:' flag; do
  case "${flag}" in
    s) SLEEP='true';;
    x) CLEAN_FLAG='true';;
    r) RPC="${OPTARG}";;
    c) CONNECTION_HOST=$(echo $OPTARG | cut -f1 -d:);
       CONNECTION_PORT=$(echo $OPTARG | cut -f2 -d:);;
    p) PORT="${OPTARG}";;
    d) HOME="${OPTARG}";;
    h) HOST="${OPTARG}";;
    *) print_usage
       exit 1 ;;
  esac
done

if [ $SLEEP ]; then
  #Random Pause up to 1 hr
  sleep "$(shuf -i1-3600 -n1)"
fi

if [ ! $(getent group minima2) ]; then
  echo "[+] Adding minima2 group"
  groupadd -g 13001 minima2
fi

if ! id -u 13001 > /dev/null 2>&1; then
  echo "[+] Adding minima2 user"
    useradd -r -u 13001 -g 13001 -d $HOME minima2
    mkdir $HOME
    chown minima2:minima2 $HOME
fi


if [ ! $PORT ]; then
    PORT='9001'
fi

DOWNLOAD_URL="https://github.com/minima-global/Minima/raw/master/jar/minima.jar"
MINIMA_JAR_NAME="minima2.jar"

echo "[+] Downloading minima from: $DOWNLOAD_URL"
wget -q -O $HOME"/"$MINIMA_JAR_NAME $DOWNLOAD_URL
chown minima2:minima2 $HOME"/"$MINIMA_JAR_NAME
chmod +x $HOME"/"$MINIMA_JAR_NAME

if [ ! -d "$HOME/.minima_$PORT" ]; then
  echo "[+] Creating data directory .minima_${PORT}..."
  mkdir $HOME/.minima_$PORT
  chown minima2:minima2 $HOME/.minima_$PORT
fi


is_service_exists() {
    local x=$1
    if systemctl status "${x}" 2> /dev/null | grep -Fq "Active:"; then
            return 0
    else
            return 1
    fi
}

if is_service_exists "minima_$PORT"; then
  echo "[!] Disabling minima service"
  systemctl stop minima_$PORT
  systemctl disable minima_$PORT
fi


echo "[+] Creating service minima_$PORT"

MINIMA_PARAMS="-daemon -rpcenable -port $PORT -data $HOME/.minima_102_$PORT"
if [ $CLEAN_FLAG ]; then
  MINIMA_PARAMS="$MINIMA_PARAMS -clean"
fi


if [ $CONNECTION_PORT ]; then
  MINIMA_PARAMS="$MINIMA_PARAMS -p2pnode $CONNECTION_HOST:$CONNECTION_PORT"
fi

if [ $HOST ]; then
  MINIMA_PARAMS="$MINIMA_PARAMS -host $HOST"
fi

tee <<EOF >/dev/null /etc/systemd/system/minima_$PORT.service
[Unit]
Description=minima_$PORT
[Service]
User=minima2
Type=simple
ExecStart=/usr/bin/java -Xmx1G -jar $HOME/$MINIMA_JAR_NAME $MINIMA_PARAMS
Restart=always
RestartSec=100
[Install]
WantedBy=multi-user.target

EOF


systemctl daemon-reload
systemctl enable minima_$PORT
systemctl start minima_$PORT