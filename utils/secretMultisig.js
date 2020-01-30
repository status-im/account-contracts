const { MerkleTree } = require('./merkleTree.js');
const { keccak256, bufferToHex, isValidAddress, setLengthLeft } = require('ethereumjs-util');
const namehash = require('eth-ens-namehash');

const MINIMUM_LIST_SIZE = 4096;
const THRESHOLD = 100 * 10**18;
const RECOVERY_ADDRESS = "0x2429242924292429242924292429242924292429";
const ERC2429 = require('Embark/contracts/MultisigRecovery');

export default class SecretMultisig {

    constructor(userAddress, privateHash, addressList) {
        if (addressList.length == 0){
            throw new Error("Invalid Address List")
        } 
        
        this.elements = addressList.map((v) => this.hashLeaf(v.address, v.weight));
        if(this.elements.length < MINIMUM_LIST_SIZE) {
            this.elements.push(... Array.from({length: MINIMUM_LIST_SIZE-this.elements.length}, (v,k) => hashFakeLeaf(privateHash, k)))
        }
        this.merkleTree = new MerkleTree(this.elements);
        this.executeHash = this.hashExecute(privateHash, userAddress);
        this.partialReveal = keccak256(this.executeHash);
        this.publicHash = keccak256(Buffer.concat(
            this.partialReveal, 
            keccak256(this.merkleTree.getRoot())
        ));
    }


    hashExecute = async (privateHash, userAddress) => keccak256(Buffer.concat(
        privateHash, 
        Buffer,from(ERC2429.address, 'hex'),
        setLengthLeft(Buffer.from(Number.toString(await ERC2429.methods.nonce(userAddress).call(), 16), 'hex'), 32)
    ));

    
    hashLeaf = (ethereumAddress, weight) => keccak256(Buffer.concat(
        this.hashAddress(ethereumAddress), 
        setLengthLeft(Buffer.from(Number.toString(weight, 16), 'hex'), 32)
    ));

    hashFakeLeaf = (privateHash, position) => keccak256(Buffer.concat(
        privateHash,
        setLengthLeft(Buffer.from(Number.toString(position, 16), 'hex'), 32)
    ));

    hashAddress = (ethereumAddress) => keccak256(
        isValidAddress(ethereumAddress) ? Buffer.concat(
            Buffer.from('0x00', 'hex'),
            setLengthLeft(Buffer.from(ethereumAddress, 'hex'), 32)
        ) : Buffer.concat(
            Buffer.from('0x01', 'hex'),
            namehash(ethereumAddress)
        )
    );

    hashApproval = (approver_address, calldest, calldata) => keccak256(Buffer.concat(
        this.hashAddress(approver_address),
        this.hashCall(calldest, calldata)
    ));


    hashCall = (calldest, calldata) => keccak256(Buffer.concat(
        this.partialReveal,
        Buffer.from(calldest, 'hex'),
        Buffer.from(calldata, 'hex')
    ));

}