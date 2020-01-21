pragma solidity >=0.5.0 <0.7.0;

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice based on https://github.com/ethereum/eth2.0-specs/blob/dev/ssz/merkle-proofs.md#merkle-multiproofs but without generalized indexes
 */
library MerkleMultiProof {

    /**
     * @notice Calculates a merkle root using multiple leafs at same time
     * @param leafs out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param indexes indexes that select the hashing pairs from calldata `leafs` and `proofs` and from memory `hashes`
     * @return merkle root of tree
     */
    function calculateMultiMerkleRoot(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        internal
        pure
        returns (bytes32 merkleRoot)
    {
        uint256 leafsLen = leafs.length;
        uint256 proofsLen = proofs.length;
        uint256 indexesLen = indexes.length;
        uint256 totalHashes = (indexesLen/2) + (leafsLen/2);

        //TODO: assert indexesLen is correct size, if possible

        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 pos = 0;

        //calculate fixed hashing pairs
        for(uint256 i = 0; i < leafsLen; i += 2){
            hashes[pos] = keccak256(
                abi.encodePacked(
                    leafs[i],
                    leafs[i+1]
                )
            );
            pos++;
        }

        //calculate dynamic hashing pairs
        for(uint256 i = 0; i < indexesLen; i += 2){
            uint256 index1 = indexes[i];
            uint256 index2 = indexes[i+1];
            hashes[pos] = keccak256(
                abi.encodePacked(
                    index1 < proofsLen ? proofs[index1] : hashes[index1-proofsLen],
                    index2 < proofsLen ? proofs[index2] : hashes[index2-proofsLen]
                )
            );
            pos++;
        }
        return hashes[totalHashes-1];
    }

/**

        //totalHashes = proofsLen + (leafsLen/2) + 1
        //I have no idea where this formula came from, I just typed it out of intuition. Bruteforce programming?
      

        r
    h-------h
  h---p   p---h 
 l-w ?-? ?-? l-w


proofsLen = 2
leafsLen = 4



        r         
    5-------6     
  3---1   2---4   
 l-w ?-? ?-? l-w  
 [3, 1, 2, 4, 5, 6]

totalHashes = 2 + 4/2 + 1 = 5
indexesLen = 6




|                r                |
|        h---------------h        |
|    h-------h       h-------h    |
|  h---p   p---h   h---p   p---h  |
| l-w ?-? ?-? l-w l-w ?-? ?-? l-w |


proofsLen = 4
leafsLen = 8


|                r                |
|        13-------------14        |
|    9-------10      11-----12    |
|  5---1   2---6   7---3   4---8  |
| l-w ?-? ?-? l-w l-w ?-? ?-? l-w |



indexesLen = 14
totalHashes = 4 + 8/2 = 9 // 11




 */

    /**
     * @notice reads a element from one of the arrays, based on the key and offsets.
     * @param proofs out of order seequence of proofs
     * @param index current index being read from  `proofs` or `hashes`
     * @param proofsLen save gas of reading lenght every iteration
     * @return element from selected index
     */
    function getElementFromIndex(
        bytes32[] memory proofs,
        bytes32[] memory hashes,
        uint256 index,
        uint256 proofsLen
    )
        private
        pure
        returns(bytes32)
    {
        return index < proofsLen ? proofs[index] : hashes[index-proofsLen];
    }

    /**
     * @notice Check validity of multimerkle proof
     * @param root merkle root
     * @param leafs out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param indexes indexes that select the hashing pairs from calldata `leafs` and `proofs` and from memory `hashes`
     */
    function verifyMerkleMultiproof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        internal
        pure
        returns (bool)
    {
        return calculateMultiMerkleRoot(leafs, proofs, indexes) == root;
    }
}
