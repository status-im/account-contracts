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
  const merkleTreeSize = 4096;
  const leafsSize = 10;
  const fuzzyProofChecks = 10;
  const elements = Array.from({length: merkleTreeSize}, (v,k) => ""+k);
  const merkleTree = new MerkleTree(elements);
  const leafs = merkleTree.getElements(Array.from({length: leafsSize}, (v,k) => ""+k));

  describe('verifyMultiProof', function () {
    it('should return true for a valid Merkle proof', async function () {
      const proof = merkleTree.getMultiProof(leafs);
      const flags = merkleTree.getProofFlags(leafs, proof);
      await MerkleMultiProofWrapper.methods.assertMultiProof(
        merkleTree.getHexRoot(),
        leafs, 
        proof, 
        flags,
      ).send()
    });


    it('should return false for an invalid Merkle proof', async function () {
      const leafs2 = merkleTree.getElements(Array.from({length: leafsSize}, (v,k) => ""+k*2));;
      const proof2 = merkleTree.getMultiProof(leafs2);
      const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(
        merkleTree.getHexRoot(),
        leafs, 
        proof2, 
        merkleTree.getProofFlags(leafs2, proof2)
      ).call()
      assert(!result);
    });

    
    it('should return true for a valid Merkle proof (fuzzy)', async function () {
      for(let j = 0; j < fuzzyProofChecks; j++){
        const leafsFuzzy = merkleTree.getElements(Array.from({length: leafsSize}, () => elements[Math.floor(Math.random()*elements.length)] ).filter((value, index, self) => self.indexOf(value) === index));
        const proof = merkleTree.getMultiProof(leafsFuzzy);
        const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(
          merkleTree.getHexRoot(),
          leafsFuzzy, 
          proof, 
          merkleTree.getProofFlags(leafsFuzzy, proof)
        ).call();
        assert(result);
      }

    });
  });
});
