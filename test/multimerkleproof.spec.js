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
    it('should return true for a valid Merkle proof', async function () {
      const elements = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16'];
      const merkleTree = new MerkleTree(elements);

      const root = merkleTree.getHexRoot();
      const leafs_seed = [elements[15],elements[0],elements[8],elements[9],elements[7]];
      
      const leafs = merkleTree.getPairs(leafs_seed);
      console.log("leafs", merkleTree.bufArrToHex(leafs));

      const proof = merkleTree.getMultiProof(leafs)

      console.log("final Proof", merkleTree.bufArrToHex(proof))

      const ids = merkleTree.getProofIds(leafs, proof)
      console.log("ids", ids)
      const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(root, leafs, proof.map(bufferToHex), ids).call();
      console.log(result);

      const flags = merkleTree.getProofFlags(leafs, proof)
      console.log("flags", flags)
      const result2 = await MerkleMultiProofWrapper.methods.verifyMultiProof2(root, leafs, proof.map(bufferToHex), flags).call();
      console.log(result2);
      //assert(result);
    });

    xit('should return false for an invalid Merkle proof', async function () {
      const correctElements = ['a', 'b', 'c'];
      const correctMerkleTree = new MerkleTree(correctElements);

      const correctRoot = correctMerkleTree.getHexRoot();

      const correctLeaf = bufferToHex(keccak256(correctElements[0]));

      const badElements = ['d', 'e', 'f'];
      const badMerkleTree = new MerkleTree(badElements);

      const badProof = badMerkleTree.getHexProof(badElements[0]);

      const result = await MerkleMultiProofWrapper.methods.verifyMultiProof(badProof, correctRoot, correctLeaf).call();
      
      assert(!result);
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
