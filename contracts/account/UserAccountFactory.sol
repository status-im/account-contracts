pragma solidity >=0.5.0 <0.7.0;

import "./Creator.sol";
import "./UserAccount.sol";
import "../cryptography/ECDSA.sol";

contract UserAccountFactory is Creator {

    constructor() public {

    }

    function create(uint256 _salt) external returns(address) {
        return newUserAccount(_salt, msg.sender);
    }

    function createSigned(uint256 _salt, bytes calldata _signature) external returns(address)  {
        return newUserAccount(_salt, ECDSA.recover(keccak256(abi.encodePacked(address(this), _salt, msg.sender)), _signature));
    }

    function predictUserAddress(uint256 _salt, address _owner) external view returns(address) {
        return _computeContractAddress(abi.encodePacked(type(UserAccount).creationCode, _owner, address(0), address(0)), bytes32(keccak256(abi.encodePacked(_owner, _salt))));
    }

    function newUserAccount(uint256 _salt, address _owner) internal returns(address) {
        return _create2(0, abi.encodePacked(type(UserAccount).creationCode, _owner, address(0), address(0)), bytes32(keccak256(abi.encodePacked(_owner, _salt))));
    }

}