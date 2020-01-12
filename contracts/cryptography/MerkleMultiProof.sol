pragma solidity >=0.5.0 <0.7.0;

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice based on https://github.com/ethereum/eth2.0-specs/blob/dev/ssz/merkle-proofs.md#merkle-multiproofs but without generalized indexes
 */
library MerkleMultiProof {

    /**
     * @notice Calculates a merkle root using multiple leafs at same time
     * @param leaves out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param indexes indexes that select the hashing pairs from calldata `leaves` and `proofs` and from memory `hashes`
     * @return merkle root of tree
     */
    function calculateMultiMerkleRoot(
        bytes32[] memory leaves,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        internal
        pure
        returns (bytes32 merkleRoot)
    {
        uint proofOffset = leaves.length;
        uint hashesOffset = proofOffset + proofs.length;
        uint indexesLen = indexes.length;
        require(hashesOffset < indexesLen, "Not enough indexes");

        bytes32[] memory hashes = new bytes32[](indexesLen-hashesOffset);
        uint256 pos = 0;

        for(uint256 i = 0; i < indexesLen; i += 2){
            hashes[hashesOffset+pos] = keccak256(
                abi.encodePacked(
                    getElementFromIndex(leaves, proofs, hashes, indexes[i], proofOffset, hashesOffset),
                    getElementFromIndex(leaves, proofs, hashes, indexes[i+1], proofOffset, hashesOffset)
                )
            );
            pos++;
        }
        return hashes[indexesLen-1];
    }

    /**
     * @notice reads a element from one of the arrays, based on the key and offsets.
     * @param leaves out of order seequence of leafs
     * @param proofs out of order seequence of proofs
     * @param index current index being read from `leaves`, `proofs` or `hashes`
     * @param proofOffset save gas of reading lenght every iteration
     * @param hashesOffset save gas of reading lenght every iteration
     * @return element from selected index
     */
    function getElementFromIndex(
        bytes32[] memory leaves,
        bytes32[] memory proofs,
        bytes32[] memory hashes,
        uint256 index,
        uint256 proofOffset,
        uint256 hashesOffset
    )
        private
        pure
        returns(bytes32 proofElement)
    {
        if (index >= hashesOffset){
            proofElement = hashes[index-hashesOffset];
        } else {
            if(index < proofOffset) {
                proofElement = leaves[index];
            } else {
                proofElement = proofs[index-proofOffset];
            }
        }
    }

    /**
     * @notice Check validity of multimerkle proof
     * @param root merkle root
     * @param leaves out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param indexes indexes that select the hashing pairs from calldata `leaves` and `proofs` and from memory `hashes`
     */
    function verifyMerkleMultiproof(
        bytes32 root,
        bytes32[] memory leaves,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        internal
        pure
        returns (bool)
    {
        return calculateMultiMerkleRoot(leaves, proofs, indexes) == root;
    }
}
