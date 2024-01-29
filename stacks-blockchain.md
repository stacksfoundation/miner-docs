# Stacks Blockchain Miner

## Scripted install

You can use the [scripts/install_stacks.sh](./scripts/install_stacks.sh) to install and start the stacks blockchain

```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_stacks.sh | bash
```

## Build and install stacks-blockchain from source

```bash
$ git clone --depth 1 --branch master https://github.com/stacks-network/stacks-blockchain.git $HOME/stacks-blockchain
$ cd $HOME/stacks-blockchain/testnet/stacks-node
$ cargo build --features monitoring_prom,slog_json --release --bin stacks-node
$ sudo cp -a $HOME/stacks-blockchain/target/release/stacks-node /usr/local/bin/stacks-node
```

### Generate stacks wallet keychain

[Follow instructions here](./wallet.md)

## Create stacks-blockchain Config.toml

**replace `seed` and `local_peer_seed` with the `privateKey` value from the previous step**

```bash
$ sudo bash -c 'cat <<EOF> /etc/stacks-blockchain/Config.toml
[node]
working_dir = "/stacks-blockchain"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
bootstrap_node = "02196f005965cebe6ddc3901b7b1cc1aa7a88f305bb8c5893456b8f9a605923893@seed.mainnet.hiro.so:20444"
seed = "<npx privateKey from wallet.md>"
# local_peer_seed = "" ## this value isn't required and is only used in peer networking
miner = true
mine_microblocks = true
wait_time_for_microblocks = 10000

[burnchain]
chain = "bitcoin"
mode = "mainnet"
peer_host = "127.0.0.1"
username = "btcuser" # bitcoin rpc username from bitcoin config
password = "btcpass" # bitcoin rpc password from bitcoin config
rpc_port = 8332      # bitcoin rpc port from bitcoin config
peer_port = 8333     # bitcoin p2p port from bitcoin config
satoshis_per_byte = 100
#burn_fee_cap = 20000
burn_fee_cap = 450000

[miner]
first_attempt_time_ms = 5000
subsequent_attempt_time_ms = 180000
microblock_attempt_time_ms = 30000

[fee_estimation]
cost_estimator = "naive_pessimistic"
fee_estimator = "scalar_fee_rate"
cost_metric = "proportion_dot_product"
log_error = true
enabled = true
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
ExecStart=/bin/sh -c "/usr/local/bin/stacks-node start --config /etc/stacks-blockchain/Config.toml >> /stacks-blockchain/miner.log 2>&1"
ExecStartPost=/bin/sh -c "umask 022; sleep 2 && pgrep -f \"/usr/local/bin/stacks-node start --config /etc/stacks-blockchain/Config.toml\" > /run/stacks-blockchain/stacks.pid"
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
