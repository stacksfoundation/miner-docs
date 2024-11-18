#!/bin/env bash


REQUIRED_DIRS=(
    /etc/stacks-blockchain
    /stacks-blockchain
)

for DIR in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "${DIR}" ]; then
        echo "[ install_stacks.sh  ] - Creating missing dir: $DIR"
        sudo mkdir -p "${DIR}"
    fi
done

echo "[ install_stacks.sh ] - Cloning stacks-blockchain from https://github.com/stacks-network/stacks-blockchain"
git clone --depth 1 --branch master https://github.com/stacks-network/stacks-blockchain "${HOME}/stacks-blockchain" && cd "${HOME}/stacks-blockchain/testnet/stacks-node" || exit 1

echo "[ install_stacks.sh ] - Build and install stacks-blockchain binary -> /usr/local/bin/stacks-node"
cargo build --features monitoring_prom,slog_json --release --bin stacks-node
sudo cp -a "${HOME}/stacks-blockchain/target/release/stacks-node" "/usr/local/bin/stacks-node"


echo "[ install_stacks.sh ] - Creating stacks user/group and setting filesytem permissions"
sudo useradd stacks
sudo chown -R stacks:stacks /stacks-blockchain/


PRIV_KEY="privateKey from npx keychain"
WIF="privateKey from npx keychain"
BTC_ADDRESS="btcAddress from npx keychain"
echo "[ install_stacks.sh ] - Installing required js modules"
cd "${HOME}" && npm install @stacks/cli shx rimraf

echo "[ install_stacks.sh ] - Generating keychain file?"
CMD="sudo ls /root/keychain.json  2> /dev/null 1>/dev/null"
eval "${CMD}"
CHECK_KEYCHAIN_FILE="${?}"
if [ ${CHECK_KEYCHAIN_FILE} != "0" ]; then
    echo "[ install_stacks.sh ] - Creating keychain file -> /root/keychain.json"
    sudo bash -c 'npx @stacks/cli make_keychain 2>/dev/null > /root/keychain.json'
    SCAN_TIME_EPOCH=$(($(date +%s) - 3600)) # scan from 1 hour ago
else
    echo "[ install_stacks.sh ] - Using existing keychain file -> /root/keychain.json"
    SCAN_TIME_EPOCH=$((1)) # scan from genesis
fi
PRIV_KEY=$(sudo cat  /root/keychain.json | jq .keyInfo.privateKey | tr -d '"')
WIF=$(sudo cat  /root/keychain.json | jq .keyInfo.wif | tr -d '"')
BTC_ADDRESS=$(sudo cat  /root/keychain.json | jq .keyInfo.btcAddress | tr -d '"')
STX_ADDRESS=$(sudo cat  /root/keychain.json | jq .keyInfo.address | tr -d '"')

if [ ! -f "/bitcoin/wallet.dat" ]; then
    echo "[ install_stacks.sh ] - Creating bitcoin wallet"
    bitcoin-cli \
        -rpcconnect=127.0.0.1 \
        -rpcport=8332 \
        -rpcuser=btcuser \
        -rpcpassword=btcpass \
        createwallet "miner" \
        false \
        false \
        "" \
        false \
        false \
        true

    echo "[ install_stacks.sh ] - Importing btc address ${BTC_ADDRESS}"
    bitcoin-cli \
        -rpcconnect=127.0.0.1 \
        -rpcport=8332 \
        -rpcuser=btcuser \
        -rpcpassword=btcpass \
        importmulti "[{ \"scriptPubKey\": { \"address\": \"${BTC_ADDRESS}\" }, \"timestamp\":${SCAN_TIME_EPOCH}, \"keys\": [ \"${WIF}\" ]}]" "{\"rescan\": true}"
fi
echo "[ install_stacks.sh ] - Bitcoin address info for ${BTC_ADDRESS}"
bitcoin-cli \
    -rpcconnect=127.0.0.1 \
    -rpcport=8332 \
    -rpcuser=btcuser \
    -rpcpassword=btcpass \
    getaddressinfo "${BTC_ADDRESS}"

echo "[ install_stacks.sh ] - Creating stacks config -> /etc/stacks-blockchain/Config.toml"
sudo bash -c 'cat <<EOF> /etc/stacks-blockchain/Config.toml
[node]
working_dir = "/stacks-blockchain"
rpc_bind = "0.0.0.0:20443" # to prevent external access, change to 127.0.0.1
p2p_bind = "0.0.0.0:20444" # to prevent external access, change to 127.0.0.1
bootstrap_node = "02196f005965cebe6ddc3901b7b1cc1aa7a88f305bb8c5893456b8f9a605923893@seed.mainnet.hiro.so:20444,02539449ad94e6e6392d8c1deb2b4e61f80ae2a18964349bc14336d8b903c46a8c@cet.stacksnodes.org:20444,02ececc8ce79b8adf813f13a0255f8ae58d4357309ba0cedd523d9f1a306fcfb79@sgt.stacksnodes.org:20444,0303144ba518fe7a0fb56a8a7d488f950307a4330f146e1e1458fc63fb33defe96@est.stacksnodes.org:20444"
seed = "PRIV_KEY"
local_peer_seed = "PRIV_KEY"
miner = true
mine_microblocks = false

[burnchain]
wallet_name = "miner"
chain = "bitcoin"
mode = "mainnet"
peer_host = "127.0.0.1"
username = "btcuser" # bitcoin rpc username from bitcoin config
password = "btcpass" # bitcoin rpc password from bitcoin config
rpc_port = 8332      # bitcoin rpc port from bitcoin config
peer_port = 8333     # bitcoin p2p port from bitcoin config
satoshis_per_byte = 100
burn_fee_cap = 450000

[miner]
mining_key = "PRIV_KEY"
activated_vrf_key_path = "/stacks-blockchain/saved_vrf_key.json"

[connection_options]
private_neighbors = false

EOF'

echo "[ install_stacks.sh ] - Updating /etc/stacks-blockchain/Config.toml with privateKey"
sudo sed -i -e  "s|seed = \"PRIV_KEY\"|seed = \"${PRIV_KEY}\"|"  /etc/stacks-blockchain/Config.toml
sudo sed -i -e  "s|local_peer_seed = \"PRIV_KEY\"|local_peer_seed = \"${PRIV_KEY}\"|"  /etc/stacks-blockchain/Config.toml

echo "[ install_stacks.sh ] - Creating systemd unit for stacks -> /etc/systemd/system/stacks.service"
sudo bash -c 'cat <<EOF> /etc/systemd/system/stacks.service
[Unit]
Description=Stacks Blockchain
Requires=bitcoin.service
After=bitcoin.service
ConditionFileIsExecutable=/usr/local/bin/stacks-node
ConditionPathExists=/stacks-blockchain/
ConditionFileNotEmpty=/etc/stacks-blockchain/Config.toml

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
# Run as stacks:stacks
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


echo "[ install_stacks.sh ] - Reloading systemd and starting stacks-blockchain service"
sudo systemctl daemon-reload
sudo systemctl enable stacks.service
sudo systemctl start stacks.service
echo "[ install_stacks.sh ] - Stacks Address: ${STX_ADDRESS}"
echo "[ install_stacks.sh ] - Bitcoin Address: ${BTC_ADDRESS}"
echo 
echo "[ install_stacks.sh ] - *******************************************************************************"
echo "[ install_stacks.sh ] - **    Keychain file is stored at /root/keychain.json                         **"
echo "[ install_stacks.sh ] - **    Highly recommend that it be copied off the host to a secure location   **"
echo "[ install_stacks.sh ] - *******************************************************************************"
echo
echo "[ install_stacks.sh ] - Tail the stacks-blockchain log: sudo tail -f /stacks-blockchain/miner.log" 
exit 0

