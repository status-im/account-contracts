pragma solidity >=0.5.0 <0.7.0;
import "../cryptography/MerkleMultiProof.sol";
import "../cryptography/MerkleMultiProof2.sol";

contract MerkleMultiProofWrapper {

    function calculateMultiMerkleRoot(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        public
        pure
        returns (bytes32)
    {
        return MerkleMultiProof.calculateMultiMerkleRoot(leafs, proofs, indexes);
    }

    function calculateMultiMerkleRoot2(
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory useProof
    )
        public
        pure
        returns (bytes32)
    {
        return MerkleMultiProof.calculateMultiMerkleRoot(leafs, proofs, useProof);
    }

    function verifyMultiProof(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        public
        pure
        returns (bool)
    {
        return MerkleMultiProof.verifyMultiProof(root, leafs, proofs, indexes);
    }

    function verifyMultiProof2(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory useProof
    )
        public
        pure
        returns (bool)
    {
        return MerkleMultiProof.verifyMultiProof(root, leafs, proofs, useProof);
    }
}
