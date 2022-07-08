# Install Bitcoin

Choose either method, but bitcoin is required here. Building from source ensures you know what code you are running, but will a while to compile.

## Binary Install

```
$ sudo curl -L https://bitcoin.org/bin/bitcoin-core-22.0/bitcoin-22.0-x86_64-linux-gnu.tar.gz -o /tmp/bitcoin-22.0.tar.gz
$ sudo tar -xzvf /tmp/bitcoin-22.0.tar.gz -C /tmp
$ sudo cp /tmp/bitcoin-22.0/bin/* /usr/local/bin/
```

## Source Install

```
$ git clone --depth 1 --branch v22.0 https://github.com/bitcoin/bitcoin /tmp/bitcoin && cd /tmp/bitcoin
$ sh contrib/install_db4.sh .
$ ./autogen.sh
$ export BDB_PREFIX="/tmp/bitcoin/db4" && ./configure BDB_LIBS="-L${BDB_PREFIX}/lib -ldb_cxx-4.8" BDB_CFLAGS="-I${BDB_PREFIX}/include" \
  --disable-gui-tests \
  --enable-static \
  --without-miniupnpc \
  --with-pic \
  --enable-cxx \
  --with-boost-libdir=/usr/lib/x86_64-linux-gnu
$ make -j2
$ sudo make install
```

## Bitcoin Config

```
$ sudo bash -c 'cat <<EOF> /etc/bitcoin/bitcoin.conf
server=1
#disablewallet=1
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
```

## Add bitcoin user and configure dirs

```
$ sudo useradd bitcoin
$ sudo chown -R bitcoin:bitcoin /bitcoin/
```

## Install bitcoin.service unit

```
$ sudo bash -c 'cat <<EOF> /etc/systemd/system/bitcoin.service
[Unit]
Description=Bitcoin daemon
After=network.target

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
```

## Enable service and start bitcoin

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable bitcoin.service
$ sudo systemctl start bitcoin.service
```

**now we wait a few days until bitcoin syncs to chain tip**

```
$ sudo tail -f /bitcoin/debug.log
$ bitcoin-cli \
  -rpcconnect=localhost \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
getblockchaininfo | jq .blocks
```
