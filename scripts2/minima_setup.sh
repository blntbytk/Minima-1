#!/bin/sh
set -e

CLEAN_FLAG=''
PORT=''
HOST=''
HOME="/home/minima2"
CONNECTION_HOST=''
CONNECTION_PORT=''
SLEEP=''
RPC=''

print_usage() {
  printf "Usage: Setups a new minima service for the specified port"
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

apt update
apt install openjdk-11-jre-headless curl jq -y

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

wget -q -O $HOME"/minima2_service.sh" "https://github.com/blntbytk/Minima-1/raw/master/scripts/minima_service.sh"
chown minima2:minima2 $HOME"/minima2_service.sh"
chmod +x $HOME"/minima2_service.sh"

CMD="$HOME/minima2_service.sh -s $@"
CRONSTRING="#!/bin/sh
$CMD"

echo "$CRONSTRING" > /etc/cron.daily/minima_$PORT
chmod a+x /etc/cron.daily/minima_$PORT

CMD="$HOME/minima2_service.sh $@"
/bin/sh -c "$CMD"

echo "Install complete - showing logs now -  Ctrl-C to exit logs, minima will keep running"
journalctl -fn 10 -u minima_$PORT