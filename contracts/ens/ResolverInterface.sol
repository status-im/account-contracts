pragma solidity >=0.5.0 <0.7.0;

contract ResolverInterface {
    function PublicResolver(address ensAddr) public;
    function setAddr(bytes32 node, address addr) public;
    function setHash(bytes32 node, bytes32 hash) public;
    function addr(bytes32 node) public view returns (address);
    function hash(bytes32 node) public view returns (bytes32);
    function supportsInterface(bytes4 interfaceID) public pure returns (bool);
}
