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
     * @param proofFlag flags for using or not proofs while hashing against hashes.
     * @return merkle root of tree
     */
    function calculateMultiMerkleRoot(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    )
        internal
        pure
        returns (bytes32 merkleRoot)
    {
        uint256 leafsLen = leafs.length;
        uint256 proofsLen = proofs.length;

        uint256 totalHashes = proofsLen + leafsLen - 1;
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint leafPos = 0;
        uint hashPos = 0;
        uint proofPos = 0;
        for(uint256 i = 0; i < totalHashes; i++){
            hashes[i] = hashPair(
                proofPos < proofsLen && proofFlag[i] ? proofs[proofPos++] : leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++],
                leafPos < leafsLen ? leafs[leafPos++] : hashes[hashPos++]
            );
        }

        return hashes[totalHashes-1];
    }

    function hashPair(bytes32 a, bytes32 b) private pure returns(bytes32){
        return keccak256(a < b ? abi.encodePacked(a, b) : abi.encodePacked(b, a));
    }

    /**
     * @notice Check validity of multimerkle proof
     * @param root merkle root
     * @param leafs out of order sequence of leafs and it's siblings
     * @param proofs out of order sequence of parent proofs
     * @param proofFlag flags for using or not proofs while hashing against hashes.
     */
    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory proofFlag
    )
        internal
        pure
        returns (bool)
    {
        return calculateMultiMerkleRoot(leafs, proofs, proofFlag) == root;
    }

}
