# Wallet Generation

**NOTE**: the values in this sample keychain output are not valid and is used for this example only. Your output _will_ look different.

This method creates a new stacks address (with corresponding Bitcoin address).
It's also fine to use an already existing stacks/bitcoin address(es)

**values shown below are 100% fake and are for documentation purposes only**

## Scripted install

If using the **Scripted install** section of [stacks-blockchain.md](./stacks-blockchain.md), and you opted to let the script created the keychain (stored at `/root/keychain.json`) then the following steps aren't needed.

## Generate stacks-blockchain keychain

Note: Skip this step if you already have a keychain generated.

**Save this output in a safe place!**

```bash
$ cd $HOME && npm install @stacks/cli shx rimraf
$ npx @stacks/cli make_keychain 2>/dev/null | jq
{
  "mnemonic": "spare decade dog ghost luxury churn flat lizard inch nephew nut drop huge divert mother soccer father zebra resist later twin vocal slender detail",
  "keyInfo": {
    "privateKey": "ooxeemeitar4ahw0ca8anu4thae7aephahshae1pahtae5oocahthahho4ahn7eici",
    "address": "SPTXOG3AIHOHNAEH5AU6IEX9OOTOH8SEIWEI5IJ9",
    "btcAddress": "Ook6goo1Jee5ZuPualeiqu9RiN8wooshoo",
    "wif": "rohCie2ein2chaed9kaiyoo6zo1aeQu1yae4phooShov2oosh4ox",
    "index": 0
  }
}
```

## Create bitcoin wallet and import it into this instance

Note: Skip this step if you already have a keychain generated.

We'll be using the wallet values from the previous `npx` command, "btcAddress" and "wif"

_Import will only be successful after bitcoin has fully synced_

```bash
$ bitcoin-cli \
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
$ bitcoin-cli \
  -rpcconnect=127.0.0.1 \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
  importmulti '[{ "scriptPubKey": { "address": "<your btcAddress>" }, "timestamp":"now", "keys": [ "<your wif>" ]}]' '{"rescan": true}'
$ bitcoin-cli \
  -rpcconnect=127.0.0.1 \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
  getaddressinfo <your btcAddress>
```

Once imported, the wallet will need to be funded with some bitcoin.

## Import an existing address into this instance

We'll be using an existing "btcAddress" and "wif"

_Import will only be successful after bitcoin has fully synced_

```bash
$ bitcoin-cli \
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
$ bitcoin-cli \
  -rpcconnect=127.0.0.1 \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
  importprivkey "<your wif>"
$ bitcoin-cli \
  -rpcconnect=127.0.0.1 \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
  getaddressinfo <your btcAddress>
```

The `importprivkey` method will trigger a full wallet rescan, which may take a while. The wallet will need to be funded with some bitcoin if it wasn't previously.
