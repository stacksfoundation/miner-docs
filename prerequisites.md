# Prerequisites

## VM setup

The VM will not need a lot of resources to run a miner - the most resources will be consumed during blockchain sync.

For this example, we'll be assuming a Debian host with x86_64 architecture (commands may also work on any Debian derived distribution).

**Note: `btcuser` and `btcpass` are used for bitcoin RPC auth in this doc. Change as appropriate**

A single CPU system with at least 4GB of memory should be more than sufficient - as well as roughly 1TB of total disk space

### VM Specs

- Minimum CPU of: `1 vCPU`
- Minimum Memory of: `4GB Memory`
- _highly_ Recommended Storage of: `1TB Disk` to allow for chainstate growth
  - as of July 8th 2022:
    - Bitcoin chainstate is roughly `415GB`
    - Stacks chainstate is roughly `44GB`

#### Disk Configuration

1. Separate disks for chainstate and OS:
   - mount a dedicated disk for bitcoin at `/bitcoin` of 1TB
   - mount a dedicated disk for stacks-blockchain at `/stacks-blockchain` of at least 100GB
   - root volume `/` of at least 25GB
2. Combined Disk for all data:
   - root volume `/` of at least 1TB

Create the required directories:

```bash
$ sudo mkdir -p /bitcoin
$ sudo mkdir -p /stacks-blockchain
$ sudo mkdir -p /etc/bitcoin
$ sudo mkdir -p /etc/stacks-blockchain
```

**If using mounted disks**: mount the disks to each filesystem created above - edit `/etc/fstab` to automount these disks at boot.

```
/dev/xvdb1 /bitcoin xfs rw,relatime,attr2,inode64,noquota
/dev/xvdc1 /stacks-blockchain xfs rw,relatime,attr2,inode64,noquota
```

Mount the disks `sudo mount -a`

## Install required packages

The following packages are required, and used by the rest of these docs

```bash
$ curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
$ sudo apt-get update -y && sudo apt-get install -y build-essential jq netcat nodejs git autoconf libboost-system-dev libboost-filesystem-dev libboost-thread-dev libboost-chrono-dev libevent-dev libzmq5 libtool m4 automake pkg-config libtool libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev libboost-iostreams-dev
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh && source $HOME/.cargo/env
$ sudo npm install -g @stacks/cli rimraf shx
```

Alternatively, you can use the [scripts/install-prerequisites.sh](./scripts/install-packages.sh) to install everything: `curl commaand | bash`
