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

  describe('verifyMultiProof', function () {

    it('should return true for a valid Merkle proof ids (small tree)', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8'];
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[1],elements[6],elements[7]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof(
          merkleTree.getHexRoot(), 
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofIds(leafs, proof)
        ).call()
      );
    });
    it('should return true for a valid Merkle proof bools (small tree)', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8'];
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[1],elements[6],elements[7]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof2(
          merkleTree.getHexRoot(),
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofFlags(leafs, proof)
        ).call()
      );
    });

    it('should return true for a valid Merkle proof ids 2', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16']; 
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[1],elements[6],elements[7]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof(
          merkleTree.getHexRoot(), 
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofIds(leafs, proof)
        ).call()
      );
    });

    it('should return true for a valid Merkle proof bools 2', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16']; 
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[1],elements[6],elements[7]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof2(
          merkleTree.getHexRoot(),
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofFlags(leafs, proof)
        ).call()
      );
    });


    it('should return true for a valid Merkle proof ids 3', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16']; 
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[3],elements[4],elements[15]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof(
          merkleTree.getHexRoot(), 
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofIds(leafs, proof)
        ).call()
      );
    });

    it('should return true for a valid Merkle proof bools 3', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16']; 
      const merkleTree = new MerkleTree(elements);
      const leafs = merkleTree.getPairs([elements[0],elements[3],elements[4],elements[15]]);
      const proof = merkleTree.getMultiProof(leafs);
      assert(
        await MerkleMultiProofWrapper.methods.verifyMultiProof2(
          merkleTree.getHexRoot(),
          leafs, 
          proof.map(bufferToHex), 
          merkleTree.getProofFlags(leafs, proof)
        ).call()
      );
    });


    xit('should return false for a Merkle proof of invalid length', async function () {
      const elements = ['a', 'b', 'c'];
      const merkleTree = new MerkleTree(elements);

      const root = merkleTree.getHexRoot();

      const proof = merkleTree.getHexProof(elements[0]);
      const badProof = proof.slice(0, proof.length - 5);

      const leaf = bufferToHex(keccak256(elements[0]));

      const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(badProof, root, leaf).call()
      
      assert(!result);
    });
  });
});
