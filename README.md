# Account contracts
Smart contracts defining self sovereign accounts.  

## Features

- Management key: A simple multisig or single address with full control of Identity
- Action keys: List of addresses allowed to execute calls in behalf of Identity, i.e. allowance tool
- ERC725 v2: Management can publish data in own profile (e.g. avatar URI, signed claims, etc).
- Secret multisig recovery: A social recovery tool for secretly selecting other addresses and requesting some of them to recover the identity 
- ERC20 approve and call: optimizes approve and call operations to avoid race conditions and gas waste.
- Gas abstract: Management can execute calls paying with gas stored on the Identity or in the Management Key.
- Serverless: Uses Whisper for gas market and Status API for Social Recovery.

### Usage
 ```
 git clone https://github.com/status-im/account-contracts.git
 cd account-contracts
 npm install
 npm start
 ```

