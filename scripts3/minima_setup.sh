#!/bin/sh
set -e

CLEAN_FLAG=''
PORT=''
HOST=''
HOME="/home/minima3"
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

if [ ! $(getent group minima3) ]; then
  echo "[+] Adding minima3 group"
  groupadd -g 14001 minima3
fi

if ! id -u 14001 > /dev/null 2>&1; then
  echo "[+] Adding minima3 user"
    useradd -r -u 14001 -g 14001 -d $HOME minima3
    mkdir $HOME
    chown minima3:minima3 $HOME
fi

wget -q -O $HOME"/minima3_service.sh" "https://github.com/blntbytk/Minima-1/raw/master/scripts3/minima_service.sh"
chown minima3:minima3 $HOME"/minima3_service.sh"
chmod +x $HOME"/minima3_service.sh"

CMD="$HOME/minima3_service.sh -s $@"
CRONSTRING="#!/bin/sh
$CMD"

echo "$CRONSTRING" > /etc/cron.daily/minima_$PORT
chmod a+x /etc/cron.daily/minima_$PORT

CMD="$HOME/minima3_service.sh $@"
/bin/sh -c "$CMD"

echo "Install complete - showing logs now -  Ctrl-C to exit logs, minima will keep running"
journalctl -fn 10 -u minima_$PORT