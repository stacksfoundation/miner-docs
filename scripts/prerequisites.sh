#!/bin/env bash

REQUIRED_DIRS=(
    /bitcoin
    /etc/bitcoin
    /etc/stacks-blockchain
    /stacks-blockchain
)

for DIR in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "${DIR}" ]; then
        echo "[ prerequisites.sh  ] - Creating missing dir: ${DIR}"
        sudo mkdir -p "${DIR}"
    fi
done

echo "[ prerequisites.sh ] - Installing nodejs v16 apt repository"
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -


echo "[ prerequisites.sh ] - Installing required system packages"
sudo apt-get update -y && sudo apt-get install -y \
    build-essential \
    jq \
    netcat \
    nodejs \
    git \
    autoconf \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-thread-dev \
    libboost-chrono-dev \
    libevent-dev \
    libzmq5 \
    libtool \
    m4 \
    automake \
    pkg-config \
    libtool \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-chrono-dev \
    libboost-program-options-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libboost-iostreams-dev

echo "[ prerequisites.sh ] - Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "[ prerequisites.sh ] - Installing Stacks CLI"
sudo npm install -g @stacks/cli rimraf shx

echo
echo "[ prerequisites.sh ] - Done."
echo "[ prerequisites.sh ] - Be sure to update \$PATH by running: source \$HOME/.cargo/env"
echo
exit 0
