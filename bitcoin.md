# Install Bitcoin Blockchain

**Note:** `btcuser` and `btcpass` are used for bitcoin RPC auth in this doc. Change as appropriate for your environment (be sure to update any configs etc used in these docs)

Either a source install or running a pre-compiled bitcoin binary is required to run a stacks miner. \
These instructions describe how to install v22.0 of the Bitcoin Blockchain - update the version number as new versions become available.

## Scripted install

`curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_bitcoin.sh | bash`

## Binary Install

Since we'll be importing a wallet into bitcoin, it's **highly recommended** that Bitcoin is compiled locally. \
That said, to run a pre-compiled binary of `bitcoind`, you can download and install the binary using these commands:

```
$ export BTC_VERSION=22.0
$ sudo curl -L https://bitcoin.org/bin/bitcoin-core-${BTC_VERSION}/bitcoin-${BTC_VERSION}-x86_64-linux-gnu.tar.gz -o /tmp/bitcoin-22.0.tar.gz
$ sudo tar -xzvf /tmp/bitcoin-${BTC_VERSION}.tar.gz -C /tmp
$ sudo cp /tmp/bitcoin-${BTC_VERSION}/bin/* /usr/local/bin/
```

## Source Install

```
$ export BTC_VERSION=22.0
$ git clone --depth 1 --branch v${BTC_VERSION} https://github.com/bitcoin/bitcoin /tmp/bitcoin && cd /tmp/bitcoin
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

**Note**: This sample config is open to the world for RPC. It can be restricted to localhost (`127.0.0.1`), **or** you can firewall the VM so it's only accessible from specific IP's.

```
$ sudo bash -c 'cat <<EOF> /etc/bitcoin/bitcoin.conf
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
```

## Add bitcoin user and set file ownership

```
$ sudo useradd bitcoin
$ sudo chown -R bitcoin:bitcoin /bitcoin/
```

## Install bitcoin systemd unit

```
$ sudo bash -c 'cat <<EOF> /etc/systemd/system/bitcoin.service
[Unit]
Description=Bitcoin daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/bitcoind -daemon \
 -pid=/run/bitcoind/bitcoind.pid \
 -conf=/etc/bitcoin/bitcoin.conf

## Process management
####################
Type=forking
PIDFile=/run/bitcoind/bitcoind.pid
Restart=on-failure
TimeoutStopSec=600

## User management
####################
User=bitcoin
Group=bitcoin
RuntimeDirectory=bitcoind
RuntimeDirectoryMode=0710

## Hardening measures
####################
## Provide a private /tmp and /var/tmp.
PrivateTmp=true

## Mount /usr, /boot/ and /etc read-only for the process.
ProtectSystem=full

## Deny access to /home, /root and /run/user
ProtectHome=true

## Disallow the process and all of its children to gain
## new privileges through execve().
NoNewPrivileges=true

## Use a new /dev namespace only populated with API pseudo devices
## such as /dev/null, /dev/zero and /dev/random.
PrivateDevices=true

[Install]
WantedBy=multi-user.target
EOF'
```

## Enable bitcoin service and start bitcoin

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable bitcoin.service
$ sudo systemctl start bitcoin.service
```

**now we wait a few days until bitcoin syncs to chain tip**

```
$ sudo tail -f /bitcoin/debug.log
2022-07-19T14:33:12Z UpdateTip: new best=00000000000000000003c9ed0f9961b984e40082faa35bb9244f47ba0d68d6f2 height=745635 version=0x27ffe004 log2_work=93.635332 tx=750040284 date='2022-07-19T14:32:43Z' progress=1.000000 cache=161.3MiB(1219743txo)
2022-07-19T14:33:25Z New outbound peer connected: version: 70015, blocks=745635, peer=118 (block-relay-only)
...

$ bitcoin-cli \
 -rpcconnect=localhost \
 -rpcport=8332 \
 -rpcuser=btcuser \
 -rpcpassword=btcpass \
getblockchaininfo | jq .blocks
745635
```

## Next Step(s)

[Installing Stacks Blockchain](./stacks-blockchain.md)
