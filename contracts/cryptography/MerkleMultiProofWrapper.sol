pragma solidity >=0.5.0 <0.7.0;
import "../cryptography/MerkleMultiProof.sol";

contract MerkleMultiProofWrapper {

    function calculateMultiMerkleRootIds(
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

    function calculateMultiMerkleRootFlags(
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

    function verifyMultiProofIds(
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

    function verifyMultiProofFlags(
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


    function assertMultiProofIds(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        uint256[] memory indexes
    )
        public
        pure
    {
        assert(MerkleMultiProof.verifyMultiProof(root, leafs, proofs, indexes));
    }

    function assertMultiProofFlags(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs,
        bool[] memory useProof
    )
        public
        pure
    {
        assert(MerkleMultiProof.verifyMultiProof(root, leafs, proofs, useProof));
    }
}
