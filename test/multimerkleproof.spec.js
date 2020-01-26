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
    const proof = merkleTree.getMultiProof(leafs);
    var flags = merkleTree.getProofFlags(leafs, proof);
    it('deploy cost', async function () {
      await MerkleMultiProofWrapper.methods.foo().send()
    });

    it('cost of calldata (proofs + leafs + flags)', async function () {

      console.log("leafs length:", leafs.length)
      console.log("proofs length:", proof.length)
      console.log("flags length:", flags.length)
      console.log("flags:", flags.reduce((ret,v)=> ret+(v ? "1":"0"),""));
      await MerkleMultiProofWrapper.methods.assertMultiProofCost(
        merkleTree.getHexRoot(),
        leafs, 
        proof,
        flags
      ).send()
    });

    it('cost of calldata (flags)', async function () {
      await MerkleMultiProofWrapper.methods.assertMultiProofCost(
        flags
      ).send()
    });


    it('cost of verify', async function () {
      const proof = merkleTree.getMultiProof(leafs);

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
        const flags = merkleTree.getProofFlags(leafsFuzzy, proof);

        const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(
          merkleTree.getHexRoot(),
          leafsFuzzy, 
          proof, 
          flags
        ).call();
        assert(result);
      }

    });
  });
});
