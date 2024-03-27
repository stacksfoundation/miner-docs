#!/bin/env bash

BTC_VERSION=25.0

REQUIRED_DIRS=(
    /bitcoin
    /etc/bitcoin
)

for DIR in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "${DIR}" ]; then
        echo "[ install_bitcoin.sh  ] - Creating missing dir: $DIR"
        sudo mkdir -p "${DIR}"
    fi
done

echo "[ install_bitcoin.sh ] - Cloning bitcoin from https://github.com/bitcoin/bitcoin"
git clone --depth 1 --branch v${BTC_VERSION} https://github.com/bitcoin/bitcoin /tmp/bitcoin && cd /tmp/bitcoin || exit 1

echo "[ install_bitcoin.sh ] - Installing DB4"
make -C depends NO_BOOST=1 NO_LIBEVENT=1 NO_QT=1 NO_SQLITE=1 NO_NATPMP=1 NO_UPNP=1 NO_ZMQ=1 NO_USDT=1

echo "[ install_bitcoin.sh ] - Building Bitcoin"
./autogen.sh

export BDB_PREFIX="$(ls -d $(pwd)/depends/* | grep "linux-gnu")"
export CXXFLAGS="-O2"
./configure \
  CXX=clang++ \
  CC=clang \
  BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" \
  BDB_CFLAGS="-I${BDB_PREFIX}/include" \
    --disable-gui-tests \
    --disable-tests \
    --without-miniupnpc \
    --with-pic \
    --enable-cxx \
    --enable-static \
    --disable-shared \
    --prefix=/usr/local
make -j2

echo "[ install_bitcoin.sh ] - Installing bitcoin"
sudo make install

echo "[ install_bitcoin.sh ] - Creating bitcoin user/group and setting filesytem permissions"
sudo useradd bitcoin
sudo chown -R bitcoin:bitcoin /bitcoin/

echo "[ install_bitcoin.sh ] - Creating bitcoin conf -> /etc/bitcoin/bitcoin.conf"
sudo bash -c 'cat <<EOF> /etc/bitcoin/bitcoin.conf
server=1
disablewallet=0
datadir=/bitcoin
rpcuser=btcuser
rpcpassword=btcpass
rpcallowip=0.0.0.0/0
bind=0.0.0.0:8333
rpcbind=0.0.0.0:8332
dbcache=512
banscore=1
rpcthreads=256
rpcworkqueue=256
rpctimeout=100
txindex=1
EOF'


echo "[ install_bitcoin.sh ] - Creating systemd unit for bitcoin -> /etc/systemd/system/bitcoin.service"
sudo bash -c 'cat <<EOF> /etc/systemd/system/bitcoin.service
[Unit]
Description=Bitcoin daemon
After=network.target
ConditionFileIsExecutable=/usr/local/bin/bitcoind
ConditionPathExists=/bitcoin
ConditionFileNotEmpty=/etc/bitcoin/bitcoin.conf

[Service]
ExecStart=/usr/local/bin/bitcoind -daemon \
                            -pid=/run/bitcoind/bitcoind.pid \
                            -conf=/etc/bitcoin/bitcoin.conf

# Process management
####################
Type=forking
PIDFile=/run/bitcoind/bitcoind.pid
Restart=on-failure
TimeoutStopSec=600
# Directory creation and permissions
####################################
# Run as bitcoin:bitcoin
User=bitcoin
Group=bitcoin
RuntimeDirectory=bitcoind
RuntimeDirectoryMode=0710
# Hardening measures
####################
# Provide a private /tmp and /var/tmp.
PrivateTmp=true
# Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full
# Deny access to /home, /root and /run/user
ProtectHome=true
# Disallow the process and all of its children to gain
# new privileges through execve().
NoNewPrivileges=true
# Use a new /dev namespace only populated with API pseudo devices
# such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true

[Install]
WantedBy=multi-user.target

EOF'


echo "[ install_bitcoin.sh ] - Reloading systemd and starting bitcoin service"
sudo systemctl daemon-reload
sudo systemctl enable bitcoin.service
sudo systemctl start bitcoin.service

echo "[ install_bitcoin.sh ] - Done"
echo "[ install_bitcoin.sh ] - Tail the bitcoin log: sudo tail -f /bitcoin/debug.log" 
exit 0
