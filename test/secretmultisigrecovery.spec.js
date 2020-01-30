const { SecretMultisig } = require('../utils/secretMultisig.js');
const EmbarkJS = require('Embark/EmbarkJS');
const MultisigRecovery = require('Embark/contracts/MultisigRecovery')

let accounts;
let ms; 

config({
  blockchain: {
    accounts: [
      {
        mnemonic: "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat",
        addressIndex: "0",
        numAddresses: "102",
        balance: "5 ether"
      }
    ]
  },
  namesystem: {
    enabled: true,
    register: {
      rootDomain: "eth",
      subdomains: {
        'test': '0x627306090abaB3A6e1400e9345bC60c78a8BEf57'
      }
    }
  },
  contracts: {
    deploy: {
      "MultisigRecovery": {
        args: [ "$ENSRegistry" ]
      }
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;
  ms = new SecretMultisig(accounts[0], "0x0011223344556677889900112233445566778899001122334455667788990011", accounts.slice(1));
});


contract('SecretMultisigRecovery', function () {

  describe('setup', function () {
    it('first time activates immediately', async function () {
      
    });

    it('pending setup', async function () {

    });

  });

  describe('activate', function () {
    it('does not activate during delay time', async function () {

    });

    it('activates a pending setup', async function () {

    });
  });

  describe('cancelSetup', function () {
    it('cancels when not reached', async function () {

    });

    it('does not cancel when reached', async function () {

    });
  });

  describe('approve', function () {
    it('using address', async function () {

    });
    it('using ENS', async function () {
      let address = await EmbarkJS.Names.resolve('test.eth')
      console.log('ENS address', address);
    });
  });

  describe('approvePreSigned', function () {
    it('using address', async function () {

    });
    it('using ENS', async function () {
      let address = await EmbarkJS.Names.resolve('test.eth')
      console.log('ENS address', address);
    });
  });

  describe('execute', function () {
    it('executes approved', async function () {

    });

    it('cant execute with low threshold', async function () {

    });

    it('cant execute with different calldest', async function () {

    });

    it('cant execute with different calldata', async function () {

    });

  });

});
