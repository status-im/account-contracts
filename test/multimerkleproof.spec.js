const { MerkleTree } = require('../utils/merkleTree.js');
const MerkleMultiProofWrapper = require('Embark/contracts/MerkleMultiProofWrapper');

const merkleTreeSize = 4096;
const leafsSize = 10;
const fuzzyProofChecks = 10;

const elementsA = Array.from({length: merkleTreeSize}, (v,k) => ""+k);
const merkleTreeA = new MerkleTree(elementsA);
const leafsA = merkleTreeA.getElements(Array.from({length: leafsSize}, (v,k) => ""+k));
const proofA = merkleTreeA.getMultiProof(leafsA);
const flagsA = merkleTreeA.getProofFlags(leafsA, proofA);

const elementsB = Array.from({length: merkleTreeSize}, (v,k) => ""+k*2);
const merkleTreeB = new MerkleTree(elementsB);
const leafsB = merkleTreeB.getElements(Array.from({length: leafsSize}, (v,k) => ""+k*2))
const proofB = merkleTreeB.getMultiProof(leafsB);
const flagsB = merkleTreeB.getProofFlags(leafsB, proofB);

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
   
  describe('calculateMultiMerkleRoot', function () {
    it('display cost of deploy MerkleMultiProofWrapper', async function () {
      await MerkleMultiProofWrapper.methods.foo().send();
    });

    it('calculate merkle root from leafs, proofs and flags', async function () {
      const result = await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
        leafsA, 
        proofA, 
        flagsA
      ).call()
      const result2 = await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
        leafsB, 
        proofB, 
        flagsB
      ).call()
      assert(result == merkleTreeA.getHexRoot());
      assert(result2 == merkleTreeB.getHexRoot());
    });
    
    it('calculate wrong merkle root from wrong proofs and flags', async function () {
      var invalid = false;
      try {
        invalid = merkleTreeA.getHexRoot() != await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
          leafsA, 
          proofB, 
          flagsB
        ).call()
      } catch(e) {
        invalid = true;
      }
      assert(invalid);

      try {
        invalid = merkleTreeA.getHexRoot() != await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
          leafsA, 
          proofB, 
          flagsA
        ).call()
      } catch(e) {
        invalid = true;
      }
      assert(invalid);
      
      try {
        invalid = merkleTreeB.getHexRoot() != await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
          leafsB, 
          proofA, 
          flagsB
        ).call();
      } catch(e) {
        invalid = true;
      }

      assert(invalid);
      try {
        invalid = merkleTreeB.getHexRoot() != await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
          leafsB, 
          proofA, 
          flagsA
        ).call() 
      } catch(e) {
        invalid = true;
      }
      assert(invalid);
    });
  
    it(`cost of calculate Tree A root for ${leafsA.length} leafs using ${proofA.length} proofs and ${flagsA.length} flags`, async function () {
      await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
        leafsA, 
        proofA, 
        flagsA,
      ).send()
    });

    it(`cost of calculate Tree B root for ${leafsB.length} leafs using ${proofB.length} proofs and ${flagsB.length} flags`, async function () {
      await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
        leafsB, 
        proofB, 
        flagsB,
      ).send()
    });

    it(`calculate ${fuzzyProofChecks} merkle root from leafs, proofs and flags (fuzzy)`, async function () {
      this.timeout(500*fuzzyProofChecks);
      for(let j = 0; j < fuzzyProofChecks; j++){
        const leafsFuzzy = merkleTreeA.getElements(
          Array.from({length: leafsSize}, () => elementsA[Math.floor(Math.random()*elementsA.length)] ).filter((value, index, self) => self.indexOf(value) === index)
        );
        const proofFuzzy = merkleTreeA.getMultiProof(leafsFuzzy);
        const flagsFuzzy = merkleTreeA.getProofFlags(leafsFuzzy, proofFuzzy);
        const result = await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
          leafsFuzzy, 
          proofFuzzy, 
          flagsFuzzy
        ).call();
        assert(result == merkleTreeA.getHexRoot());
      }
    });

    it(`calculate ${fuzzyProofChecks} wrong merkle root from wrong proofs and flags (fuzzy)`, async function () {
      this.timeout(500*fuzzyProofChecks);
      for(let j = 0; j < fuzzyProofChecks; j++){
        const leafsFuzzy = merkleTreeB.getElements(
          Array.from({length: leafsSize}, () => elementsB[Math.floor(Math.random()*elementsB.length)] ).filter((value, index, self) => self.indexOf(value) === index)
        );
        const proofFuzzy = merkleTreeB.getMultiProof(leafsFuzzy);
        const flagsFuzzy = merkleTreeB.getProofFlags(leafsFuzzy, proofFuzzy);
        var invalid = false;
        try {
          invalid = merkleTreeA.getHexRoot() != await MerkleMultiProofWrapper.methods.calculateMultiMerkleRoot(
            leafsFuzzy, 
            proofFuzzy, 
            flagsFuzzy
          ).call();
        } catch(e) {
          invalid = true;
        }
        assert(invalid);
      }
    });
  });
});
