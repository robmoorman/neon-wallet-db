# Light Wallet Database API

This code runs a database that mirrors the NEO blockchain and serves several APIs that don't exist anywhere else (for example, an API to get the full transaction history associated with an address). This project will likely be a temporary measure as more public resources are built into [Neoscan](https://github.com/CityOfZion/neo-scan).

### STATUS: MainNet and TestNet are both fully synced and auto-updating.

## How does this work?

This API and a MongoDB mirror of the Neo blockchain live on Heroku. The public API definition is in `api/api.py`. Code that manages keeping the database in sync with public nodes is in `clock.py` and `api/blockchain.py`.

[APScheduler](http://apscheduler.readthedocs.io/en/latest/) polls the blockchain every 5 seconds (to keep blocks up to date) and executes a repair process (for any potential missing blocks) every 5 minutes. The polling and repair logic are both executed by seperate worker processes under the Python [rq](http://python-rq.org) library to avoid overloading the API. Both the number of wep api servers and the number of workers processing incoming transaction data can be scaled arbitrarily.

## Overview of API

All APIs work on both MainNet (https://neo.herokuapp.com) and TestNet (https://neo-testnet.herokuapp.com).

### Balance data

Given an address, return the current balance of NEO and GAS, as well as a list of transaction ids and amounts for unspent assets: `https://neo.herokuapp.com/balance/{address}`. Knowing these unspent transaction ids is important for light wallets because [wallets need them to send assets](/docs/Overview.md)!

For example:

    curl http://neo-testnet.herokuapp.com/balance/AdWDaCmhPmxgksr2iTVuGcLcncSouV6XGv

This will produce:

```json
{
  "GAS": 64,
  "NEO": 54,
  "unspent": [
    {
      "asset": "GAS",
      "txid": "4a38a701099bc61ec38bca03477a2e88d9077267a66062d675105df32ef9924c",
      "value": 10
    },
    {
      "asset": "NEO",
      "txid": "9d3658842eb6e61f0913f28689f7977d48e931005c92fde4664dcdde8ea5a745",
      "value": 7
    },
    ...
  ]
}
```

### Transaction data

Get detailed information about a transaction: `http://neo-testnet.herokuapp.com/get_transaction/{txid}`. This is identical to the structure returned by the Node CLI except that `ContractTransactions` have been augmented by `vin_verbose` with extra information about input transactions.  

For example:

    curl http://neo-testnet.herokuapp.com/get_transaction/ec4dc0092d5adf8cdf30eadf5116dbb6f138b2e35ca2f1a26d992d69388e0b95

This produces:

```json
{
  "_id": {
    "$oid": "59700381048252991e506558"
  },
  "attributes": [],
  "block_index": 285873,
  "net_fee": "0",
  "scripts": [
    {
      "invocation": "40bcd8a5787e1027cda3cf03e9d1797bed93363ed3c3ff3b6162c0863ed1b5ad50b932a6cea6bd7ae01b6440dc3b509422614742891f0699454988c1b459c84330",
      "verification": "2102028a99826edc0c97d18e22b6932373d908d323aa7f92656a77ec26e8861699efac"
    }
  ],
  "size": 262,
  "sys_fee": "0",
  "txid": "ec4dc0092d5adf8cdf30eadf5116dbb6f138b2e35ca2f1a26d992d69388e0b95",
  "type": "ContractTransaction",
  "version": 0,
  "vin": [
    {
      "txid": "f584373e6a98a88a13b3a61423550063425b6ae2a95dc6b87b2e1e3f49fb3b98",
      "vout": 1
    }
  ],
  "vin_verbose": [
    {
      "address": "ALq7AWrhAueN6mJNqk6FHJjnsEoPRytLdW",
      "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
      "n": 1,
      "txid": "f584373e6a98a88a13b3a61423550063425b6ae2a95dc6b87b2e1e3f49fb3b98",
      "value": "9746"
    }
  ],
  "vout": [
    {
      "address": "ALpwWoxKLwbfCTkRpK2iXrXpaMHgWGcrDV",
      "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
      "n": 0,
      "value": "900"
    },
    {
      "address": "ALq7AWrhAueN6mJNqk6FHJjnsEoPRytLdW",
      "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
      "n": 1,
      "value": "8846"
    }
  ]
}
```

### Claiming GAS

Current block explorers do not provide a list of the available claims for an address. The light wallet API supports this through: `http://localhost:5000/get_claim/{address}`

For example:

    curl http://neo-testnet.herokuapp.com/get_claim/ANrL4vPnQCCi5Mro4fqKK1rxrkxEHqmp2E

This produces a json object where `claims` provides a list of available GAS claims and `total_claim` provides the total amount of GAS available to claim. These claims are denominated in units of `GAS * 100000000` to support the format required by the network protocol. So you can divide these numbers by `100000000` to get the number of GAS the account would actually receive.

```json
{
  "claims": [
    {
      "claim": 235456,
      "end": 306327,
      "index": 0,
      "start": 276895,
      "txid": "67a18d71c04772ac3ab92dbc7936fa0a3422fda8631ecae4e4a3d5cc1f108e8e",
      "value": 1
    },
    {
      "claim": 235352,
      "end": 306327,
      "index": 0,
      "start": 276908,
      "txid": "da3d195562dc7e131c4653c323c3368fdb6d41bab038e7d8546be7235aa69ec3",
      "value": 1
    },
    {
      "claim": 234976,
      "end": 306327,
      "index": 0,
      "start": 276955,
      "txid": "48f8241f41a1dabf55c8b367193bd770703595ef78b5a29d78d962c8a1638d1e",
      "value": 1
    },
    {
      "claim": 234952,
      "end": 306327,
      "index": 0,
      "start": 276958,
      "txid": "2190525f51297cf0fe2c92bd820ac9b663d6b59265b12c001263dd329abc555b",
      "value": 1
    },
    {
      "claim": 234856,
      "end": 306327,
      "index": 0,
      "start": 276970,
      "txid": "fe950deef57bc7e32b213e125fdc175a0d0c8a9b1761d43afb9adaa0e6808c48",
      "value": 1
    }
  ],
  "total_claim": 1175592
}
```

### Transaction History

Current block explorers such as [antchain.org](http://antchain.org) and the current Node APIs only provide information about *unspent transactions* associated with an address. To claim GAS, light wallets need access to more than just unspent transactions!

Use `https://neo.herokuapp.com/transaction_history/{address}` to get full transaction history for an address:

    curl https://neo.herokuapp.com/transaction_history/AU2CRdjozCr1LKmAAs32BVdyyM7RWcQQTA

This produces a json object with two main keys: `"receiver"` holds all transactions that result in assets being received by the address in question (i.e., where that address appears in `"vout"`), and `"sender"` holds all transactions where an asset was sent by the address in question (i.e., where the transaction id and index pair in `"vin"` corresponds to that address). For more details see the [documentation](/docs/Overview.md).

```json
{
  "address": "AU2CRdjozCr1LKmAAs32BVdyyM7RWcQQTA",
  "name": "transaction_history",
  "receiver": [
    {
      "_id": {
        "$oid": "596f06cff769b427dcff23b4"
      },
      "attributes": [],
      "block_index": 1147002,
      "net_fee": "0",
      "scripts": [
        {
          "invocation": "40c7f767e6190bb333c9f26991110516a19bc540081b8bf69d01129f6289a8650bca02f60a5fb00cd949524955aa29300a45c6a74721ee4f5c79c9cdb73bc692ff",
          "verification": "2103b98c67fa12e293ef004f8e191a656a0fafce28f7ba50667dc2d3a6e6dddb1061ac"
        }
      ],
      "size": 262,
      "sys_fee": "0",
      "txid": "d94440d6fca3c9e1120d103618b0ec638bf34edaa30b0d3e1ac2af8a80bffb56",
      "type": "ContractTransaction",
      "version": 0,
      "vin": [
        {
          "txid": "fa38ee2e95fca05cc2e37572ce21d8117169b6233358ad0d3b8955a79cd2fa39",
          "vout": 1
        }
      ],
      "vin_verbose": [
        {
          "address": "ANrL4vPnQCCi5Mro4fqKK1rxrkxEHqmp2E",
          "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
          "n": 1,
          "txid": "fa38ee2e95fca05cc2e37572ce21d8117169b6233358ad0d3b8955a79cd2fa39",
          "value": "650"
        }
      ],
      "vout": [
        {
          "address": "AU2CRdjozCr1LKmAAs32BVdyyM7RWcQQTA",
          "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
          "n": 0,
          "txid": "d94440d6fca3c9e1120d103618b0ec638bf34edaa30b0d3e1ac2af8a80bffb56",
          "value": "1"
        },
        {
          "address": "ANrL4vPnQCCi5Mro4fqKK1rxrkxEHqmp2E",
          "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
          "n": 1,
          "txid": "d94440d6fca3c9e1120d103618b0ec638bf34edaa30b0d3e1ac2af8a80bffb56",
          "value": "649"
        }
      ]
    },
    ...
  ],
  "sender": [
    {
      "_id": {
        "$oid": "596f06cff769b427dcff23bf"
      },
      "attributes": [],
      "block_index": 1147005,
      "net_fee": "0",
      "scripts": [
        {
          "invocation": "404b70f6787ab1fdcbcc3fd6c9f7f2a088aa84bcafd42b3b6fc453a50b3d3aa1f502ca87cba81826dd1f58d95719b2fdb3b3b642c66685b1836192e6f594d16a6a",
          "verification": "21021d9d8206e15aa8a1e911283b28ad6d902c6d99790417e79449282fa4c2beb10eac"
        }
      ],
      "size": 202,
      "sys_fee": "0",
      "txid": "ba6d8dd9e849d1a280ff9c1c559ba77716139cb3246ca05d6452dc05d54cf62c",
      "type": "ContractTransaction",
      "version": 0,
      "vin": [
        {
          "txid": "d94440d6fca3c9e1120d103618b0ec638bf34edaa30b0d3e1ac2af8a80bffb56",
          "vout": 0
        }
      ],
      "vin_verbose": [
        {
          "address": "AU2CRdjozCr1LKmAAs32BVdyyM7RWcQQTA",
          "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
          "n": 0,
          "txid": "d94440d6fca3c9e1120d103618b0ec638bf34edaa30b0d3e1ac2af8a80bffb56",
          "value": "1"
        }
      ],
      "vout": [
        {
          "address": "ANrL4vPnQCCi5Mro4fqKK1rxrkxEHqmp2E",
          "asset": "c56f33fc6ecfcd0c225c4ab356fee59390af8560be0e930faebe74a6daff7c9b",
          "n": 0,
          "txid": "ba6d8dd9e849d1a280ff9c1c559ba77716139cb3246ca05d6452dc05d54cf62c",
          "value": "1"
        }
      ]
    },
    ...
  ]
}
```
