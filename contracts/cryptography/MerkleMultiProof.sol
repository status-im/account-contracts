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
        //`totalHashes == (totalIndexes/2) + (leafsLen/2) == leafsLen + proofsLen - 1`
        uint256 leafsLen = leafs.length;
        uint256 proofsLen = proofs.length;

        uint256 totalHashes = proofsLen + leafsLen - 1;
        uint256 totalIndexes = totalHashes + proofsLen - 1;


        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 pos = 0;

        //calculate fixed hashing pairs
        for(uint256 i = 0; i < leafsLen; i += 2){
            hashes[pos] = keccak256(abi.encodePacked(leafs[i],leafs[i+1]));
            pos++;
        }
        uint256 indexesLen = indexes.length;
        //calculate dynamic hashing pairs
        for(uint256 i = 0; i < totalIndexes; i += 2){
            uint256 index1 = i < indexesLen ? indexes[i] : i;
            uint256 index2 = i+1 < indexesLen? indexes[i+1] : i+1;
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


|                                                                                                                                ?                                                                                                                                |
|                                                                ?-------------------------------------------------------------------------------------------------------------------------------?                                                                |
|                                ?---------------------------------------------------------------?                                                               ?---------------------------------------------------------------?                                |
|                ?-------------------------------?                               ?-------------------------------?                               ?-------------------------------?                               ?-------------------------------?                |
|        ?---------------?               ?---------------?               ?---------------?               ?---------------?               ?---------------?               ?---------------?               ?---------------?               ?---------------?        |
|    ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?    |
|  ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?  |
| ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? |



`                                                                r                                                                |
|                                17-------------------------------------------------------------18                                |
|                15------------------------------7                               8-------------------------------16               |
|        13--------------5               ?---------------?               ?---------------?               6---------------14       |
|    11------3       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       ?-------?       4------12    |
|  9---1   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   ?---?   2--10  |
| l-l ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? ?-? l-l |


 */

    /**
     * @notice Check validity of multimerkle proof
     * @param root merkle root
     * @param leafs out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param indexes indexes that select the hashing pairs from calldata `leafs` and `proofs` and from memory `hashes`
     */
    function verifyMultiProof(
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
