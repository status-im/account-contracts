pragma solidity >=0.5.0 <0.7.0;
import "../cryptography/MerkleMultiProof.sol";

contract MerkleMultiProofWrapper {

    function foo() external {
        
    }

    function calculateMultiMerkleRoot(
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
        bool[] memory useProof
    )
        public
        pure
        returns (bool)
    {
        return MerkleMultiProof.verifyMultiProof(root, leafs, proofs, useProof);
    }

    function assertMultiProof(
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

    function assertMultiProofCost(
        bool[] memory useProof
    )
        public
        pure
    {

    }

    function assertMultiProofCost(
        bytes32 root,
        bytes32[] memory leafs,
        bytes32[] memory proofs

    )
        public
        pure
    {

    }
}
