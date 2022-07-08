# Wallet Generation

Note: this method creates a new stacks address (with corresponding Bitcoin address).
It's also fine to use an already existing stacks/bitcoin address(es)

**values shown below are 100% fake and are for documentation purposes only**

## Generate stacks-blockchain keychain

**save this output in a safe place!**

```bash
$ cd $HOME && npm install @stacks/cli shx rimraf
$ npx @stacks/cli make_keychain 2>/dev/null | jq
{
  "mnemonic": "spare decade dog ghost luxury churn flat lizard inch nephew nut drop huge divert mother soccer father zebra resist later twin vocal slender detail",
  "keyInfo": {
    "privateKey": "ooxeemeitar4ahw0ca8anu4thae7aephahshae1pahtae5oocahthahho4ahn7eici",
    "address": "STTXOG3AIHOHNAEH5AU6IEX9OOTOH8SEIWEI5IJ9",
    "btcAddress": "Ook6goo1Jee5ZuPualeiqu9RiN8wooshoo",
    "wif": "rohCie2ein2chaed9kaiyoo6zo1aeQu1yae4phooShov2oosh4ox",
    "index": 0
  }
}
```

## Create bitcoin wallet and import it into this instance

We'll be using the wallet values from the previous `npx` command, "btcAddress" and "wif"

```bash
$ bitcoin-cli \
  -rpcconnect=localhost \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
createwallet "miner"
$ sudo systemctl restart bitcoin
$ bitcoin-cli \
  -rpcconnect=localhost \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
importmulti '[{ "scriptPubKey": { "address": "<npx btcAddress>" }, "timestamp":"now", "keys": [ "<npx wif>" ]}]' '{"rescan": true}'
$ bitcoin-cli \
  -rpcconnect=localhost \
  -rpcport=8332 \
  -rpcuser=btcuser \
  -rpcpassword=btcpass \
getaddressinfo <npx btcAddress>
```

Once imported, the wallet will need to be funded with some bitcoin.