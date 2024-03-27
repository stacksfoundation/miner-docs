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
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -


echo "[ prerequisites.sh ] - Installing required system packages"
sudo apt-get update -y && sudo apt-get install -y \
    autoconf \
    automake \
    autotools-dev \
    build-essential \
    clang \
    curl \
    git \
    jq \
    libboost-chrono-dev \
    libboost-dev \
    libboost-filesystem-dev \
    libboost-iostreams-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libczmq-dev \
    libevent-dev \
    libnatpmp-dev \
    libminiupnpc-dev \
    libssl-dev \
    libsqlite3-dev \
    libtool \
    libzmq5 \
    m4 \
    ncat \
    nodejs \
    pkg-config \
    python3 \
    wget

echo "[ prerequisites.sh ] - Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "[ prerequisites.sh ] - Installing Stacks CLI"
sudo npm install -g @stacks/cli rimraf shx

echo
echo "[ prerequisites.sh ] - Done."
echo "[ prerequisites.sh ] - Be sure to update \$PATH by running: source \$HOME/.cargo/env"
echo
exit 0