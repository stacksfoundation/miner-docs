# Stacks Blockchain Miner

## Build and install stacks-blockchain from source

```bash
$ git clone https://github.com/stacks-network/stacks-blockchain.git $HOME/stacks-blockchain
$ cd $HOME/stacks-blockchain/testnet/stacks-node
$ cargo build --features monitoring_prom,slog_json --release --bin stacks-node
$ sudo cp -a $HOME/stacks-blockchain/target/release/stacks-node /usr/local/bin/stacks-node
```

```bash
$ sudo bash -c 'cat <<EOF> /etc/stacks-blockchain/follower.toml
[node]
working_dir = "/stacks-blockchain"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
bootstrap_node = "02da7a464ac770ae8337a343670778b93410f2f3fef6bea98dd1c3e9224459d36b@seed-0.mainnet.stacks.co:20444,02afeae522aab5f8c99a00ddf75fbcb4a641e052dd48836408d9cf437344b63516@seed-1.mainnet.stacks.co:20444,03652212ea76be0ed4cd83a25c06e57819993029a7b9999f7d63c36340b34a4e62@seed-2.mainnet.stacks.co:20444"

[burnchain]
chain = "bitcoin"
mode = "mainnet"
peer_host = "127.0.0.1"
username = "btcuser"
password = "btcpass"
rpc_port = 8332
peer_port = 8333
EOF'
```

**replace `seed` and `local_peer_seed` with the `privateKey` value from the previous `npx` command**

```bash
$ sudo bash -c 'cat <<EOF> /etc/stacks-blockchain/miner.toml
[node]
working_dir = "/stacks-blockchain"
rpc_bind = "0.0.0.0:20443"
p2p_bind = "0.0.0.0:20444"
bootstrap_node = "02da7a464ac770ae8337a343670778b93410f2f3fef6bea98dd1c3e9224459d36b@seed-0.mainnet.stacks.co:20444,02afeae522aab5f8c99a00ddf75fbcb4a641e052dd48836408d9cf437344b63516@seed-1.mainnet.stacks.co:20444,03652212ea76be0ed4cd83a25c06e57819993029a7b9999f7d63c36340b34a4e62@seed-2.mainnet.stacks.co:20444"
seed = "<npx privateKey>"
local_peer_seed = "<npx privateKey>"
miner = true
mine_microblocks = true
wait_time_for_microblocks = 10000

[burnchain]
chain = "bitcoin"
mode = "mainnet"
peer_host = "127.0.0.1"
username = "btcuser"
password = "btcpass"
rpc_port = 8332
peer_port = 8333
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
ExecStart=/bin/sh -c "/usr/local/bin/stacks-node start --config=/etc/stacks-blockchain/follower.toml >> /stacks-blockchain/follower.log 2>&1"
ExecStartPost=/bin/sh -c "umask 022; sleep 2 && pgrep -f \"/usr/local/bin/stacks-node start --config=/etc/stacks-blockchain/follower.toml\" > /run/stacks-blockchain/stacks.pid"
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