# Stacks Blockchain Miner

## Scripted install

`curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_stacks.sh | bash`

## Build and install stacks-blockchain from source

```bash
$ git clone --depth 1 --branch feat/check-pox-2-params https://github.com/stacks-network/stacks-blockchain.git $HOME/stacks-blockchain
$ cd $HOME/stacks-blockchain/testnet/stacks-node
$ cargo build --features monitoring_prom,slog_json --release --bin stacks-node
$ sudo cp -a $HOME/stacks-blockchain/target/release/stacks-node /usr/local/bin/stacks-node
```

### Generate stacks wallet keychain

(Follow instructions here)[./wallet.md]

## Create stacks-blockchain Config.toml

**replace `seed` with the `privateKey` value from the previous step**

```bash
$ sudo bash -c 'cat <<EOF> /etc/stacks-blockchain/Config.toml
[node]
working_dir = "/stacks-blockchain/data"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
seed = "<npx privateKey from wallet.md>"
miner = true
prometheus_bind = "0.0.0.0:9153"
mine_microblocks = true
wait_time_for_microblocks = 0
bootstrap_node = "027e929237cc4c12980b109bd3180ca591f3b72896b6e3716f5d1dce0a5bdd2dc4@next.stacks.org:20444"
name = "xenon-node-2.1"

[miner]
first_attempt_time_ms = 5000
subsequent_attempt_time_ms = 15000
microblock_attempt_time_ms = 5000

[burnchain]
chain = "bitcoin"
mode = "xenon"
peer_host = "127.0.0.1"
username = "btcuser" # bitcoin rpc username from bitcoin config
password = "btcpass" # bitcoin rpc password from bitcoin config
rpc_port = 18332      # bitcoin rpc port from bitcoin config
peer_port = 18333     # bitcoin p2p port from bitcoin config
burn_fee_cap = 10000
satoshis_per_byte = 10
rbf_fee_increment = 5
max_rbf = 150
magic_bytes = "21"

[[ustx_balance]]
address = "ST2QKZ4FKHAH1NQKYKYAYZPY440FEPK7GZ1R5HBP2"
amount = 10000000000000000

[[ustx_balance]]
address = "ST319CF5WV77KYR1H3GT0GZ7B8Q4AQPY42ETP1VPF"
amount = 10000000000000000

[[ustx_balance]]
address = "ST221Z6TDTC5E0BYR2V624Q2ST6R0Q71T78WTAX6H"
amount = 10000000000000000

[[ustx_balance]]
address = "ST2TFVBMRPS5SSNP98DQKQ5JNB2B6NZM91C4K3P7B"
amount = 10000000000000000
EOF'
```

## Add stacks user and configure dirs

```bash
$ sudo useradd stacks
$ sudo chown -R stacks:stacks /stacks-blockchain/
```

## Install stacks.service unit

```bash
$ sudo bash -c 'cat <<EOF> /etc/systemd/system/stacks.service
[Unit]
Description=Stacks Blockchain
Requires=bitcoin.service
After=bitcoin.service
ConditionFileIsExecutable=/usr/local/bin/stacks-node
ConditionPathExists=/stacks-blockchain/

[Service]
ExecStart=/bin/sh -c "/usr/local/bin/stacks-node start --config=/etc/stacks-blockchain/Config.toml >> /stacks-blockchain/miner.log 2>&1"
ExecStartPost=/bin/sh -c "umask 022; sleep 2 && pgrep -f \"/usr/local/bin/stacks-node start --config=/etc/stacks-blockchain/Config.toml\" > /run/stacks-blockchain/stacks.pid"
ExecStopPost=/bin/sh -c "if [ -f \"/run/stacks-blockchain/stacks.pid\" ]; then rm -f /run/stacks-blockchain/stacks.pid; fi"

# Process management
####################
Type=simple
PIDFile=/run/stacks-blockchain/stacks.pid
Restart=on-failure
TimeoutStopSec=600
KillSignal=SIGTERM

# Directory creation and permissions
####################################
# Run as bitcoin:bitcoin
User=stacks
Group=stacks
RuntimeDirectory=stacks-blockchain
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

## Enable service and start stacks

```
$ sudo systemctl daemon-reload
$ sudo systemctl enable stacks.service
$ sudo systemctl start stacks.service
```

Alternatively, you can use the [scripts/install_stacks.sh](./scripts/install_stacks.sh) to install and start stacks-blockchain:

```bash
$ curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_stacks.sh | bash`
```
