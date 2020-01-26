const { MerkleTree } = require('../utils/merkleTree.js');
const { keccak256, bufferToHex } = require('ethereumjs-util');

const MerkleMultiProofWrapper = require('Embark/contracts/MerkleMultiProofWrapper');
config({
  contracts: {
    deploy: {
      "MerkleMultiProofWrapper": {
      
      }
    }
  }
}, (_err, web3_accounts) => {
  accounts = web3_accounts;
});

contract('MultiMerkleProof', function () {
  const merkleTreeSize = 1024;
  const leafsSize = 25;
  const fuzzyProofChecks = 10;
  const elements = Array.from({length: merkleTreeSize}, (v,k) => ""+k);
  const merkleTree = new MerkleTree(elements);
  const leafs = merkleTree.getPairs(Array.from({length: leafsSize}, (v,k) => ""+k));
  const proof = merkleTree.getMultiProof(leafs);
  describe('verifyMultiProofIds', function () {
    it('should return true for a valid Merkle proof', async function () {
      await MerkleMultiProofWrapper.methods.assertMultiProofIds(
        merkleTree.getHexRoot(), 
        leafs, 
        proof, 
        merkleTree.getProofIds(leafs, proof)
      ).send()
    });

    it('should return true for a valid Merkle proof (fuzzy)', async function () {
      for(let j = 0; j < fuzzyProofChecks; j++){
        const leafs = merkleTree.getPairs(Array.from({length: leafsSize}, () => elements[Math.floor(Math.random()*elements.length)] ).filter((value, index, self) => self.indexOf(value) === index));
        const proof = merkleTree.getMultiProof(leafs);
        
        const result = await MerkleMultiProofWrapper.methods.verifyMultiProofIds(
          merkleTree.getHexRoot(), 
          leafs, 
          proof, 
          merkleTree.getProofIds(leafs, proof)
        ).call();

        if(!result) {
          console.log("proofChecks", j)
          console.log("leafs", merkleTree.bufArrToHex(leafs));
          console.log("ids", merkleTree.getProofIds(leafs, proof, true))
        }
        assert(result);
      }

    });
  });
  
  describe('verifyMultiProofFlags', function () {
    it('should return true for a valid Merkle proof', async function () {
      await MerkleMultiProofWrapper.methods.assertMultiProofFlags(
        merkleTree.getHexRoot(),
        leafs, 
        proof, 
        merkleTree.getProofFlags(leafs, proof)
      ).send()
    });

    
    it('should return true for a valid Merkle proof (fuzzy)', async function () {
     
      for(let j = 0; j < fuzzyProofChecks; j++){
        const leafs = merkleTree.getPairs(Array.from({length: leafsSize}, () => elements[Math.floor(Math.random()*elements.length)] ).filter((value, index, self) => self.indexOf(value) === index));
        const proof = merkleTree.getMultiProof(leafs);
        const result = await MerkleMultiProofWrapper.methods.verifyMultiProofFlags(
          merkleTree.getHexRoot(),
          leafs, 
          proof, 
          merkleTree.getProofFlags(leafs, proof)
        ).call();
        
        if(!result) {
          console.log("proofChecks", j)
          console.log("els", merkleTree.bufArrToHex(merkleTree.elements));
          console.log("leafs", merkleTree.bufArrToHex(leafs));
          console.log("flags", merkleTree.getProofFlags(leafs, proof, true))
        }
        assert(result);
      }

    });
  });
});
