#!/bin/env bash

REQUIRED_DIRS=(
    /bitcoin
    /stacks-blockchain
    /etc/bitcoin
    /etc/stacks-blockchain
)
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d $dir ]; then
        echo "Creating missing dir: $dir"
        sudo mkdir -p $dir
    fi
done

echo "*** Installing nodejs v16 apt repository"
curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -


echo "*** Installing required system packages"
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

echo "*** Installing Rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

echo "*** Installing Stacks CLI"
sudo npm install -g @stacks/cli rimraf shx

echo
echo "*** Done."
echo "*** Be sure to update \$PATH by running: `source \$HOME/.cargo/env`"
echo
exit 0