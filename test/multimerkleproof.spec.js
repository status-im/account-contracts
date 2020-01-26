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

    it('should return true for a valid Merkle proof ids 4', async function () {
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

    it('should return true for a valid Merkle proof (fuzzy)', async function () {
      const fullChecks = 1;
      const proofChecks = 10;
      const maxTreeSizePow = 8;
      const maxLeafsSize = 100;

      for(let i = 0; i < fullChecks; i++){
       
        const elements = Array.from({length: Math.pow(2,(4+Math.floor(Math.random()*maxTreeSizePow)))}, () => Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15));
        const merkleTree = new MerkleTree(elements);
        for(let j = 0; j < proofChecks; j++){
          const leafs = merkleTree.getPairs(Array.from({length: maxLeafsSize}, () => elements[Math.floor(Math.random()*elements.length)] ).filter((value, index, self) => self.indexOf(value) === index));
          const proof = merkleTree.getMultiProof(leafs);
          const result = await MerkleMultiProofWrapper.methods.verifyMultiProof2(
            merkleTree.getHexRoot(),
            leafs, 
            proof.map(bufferToHex), 
            merkleTree.getProofFlags(leafs, proof)
          ).call();
          
          const resultIds = await MerkleMultiProofWrapper.methods.verifyMultiProof(
            merkleTree.getHexRoot(), 
            leafs, 
            proof.map(bufferToHex), 
            merkleTree.getProofIds(leafs, proof)
          ).call();

          if(!result || !resultIds) {
            console.log("fullchecks", i, "proofChecks", j , "bools", result, "ids", resultIds)
            console.log("els", merkleTree.bufArrToHex(merkleTree.elements));
            console.log("leafs", merkleTree.bufArrToHex(leafs));
            console.log("proof", merkleTree.bufArrToHex(proof));

            if(result){
              console.log("bools", merkleTree.getProofFlags(leafs, proof, true))
            } else {
              console.log("ids", merkleTree.getProofIds(leafs, proof, true))
            }
          }
          assert(
            result && resultIds
          );
        }
      }
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
