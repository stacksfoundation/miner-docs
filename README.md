# Stacks Blockchain Miner setup

Simple docs/scripts for setting up a miner on a Debian x86_64 based VM.

## Manual Setup

- [prerequisites.md](./prerequisites.md)
- [bitcoin.md](./bitcoin.md)
- [stacks-blockchain.md](./stacks-blockchain.md)
  - **Note**: Will link to some required steps in [wallet.md](./wallet.md)


## Scripted Setup

Check the VM requirements first in [prerequisites.md](./prerequisites.md) to ensure you have a compatible VM for mining. \
_Note that `sudo` is required_

1. Initial package setup: 
```bash 
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/prerequisites.sh | bash
```
- _if using a separate disks for chainstate, mount them now_ i.e. `sudo mount /dev/xvdf1 /bitcoin`
2. Install Bitcoin: 
```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_bitcoin.sh | bash
```
  **Once Bitcoin has fully synced from genesis, the final script can be run**
  
  
3. Install Stacks Blockchain: 
```bash
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/stacksfoundation/miner-docs/main/scripts/install_stacks.sh | bash
```
