pragma solidity >=0.5.0 <0.6.0;

import "./Creator.sol";
import "./UserAccount.sol";
import "../crytography/ECDSA.sol";

contract UserAccountFactory is Creator {

    constructor() public {

    }

    function create(uint256 _salt) external {
        newUserAccount(msg.sender, _salt);
    }

    function createSigned(uint256 _salt, bytes calldata signature) external {
        newUserAccount(ECDSA.recover(keccak256(abi.encodePacked(address(this), _salt, msg.sender)), signature), _salt);
    }

    function newUserAccount(uint256 _salt, address owner) internal {
        _create2(0, abi.encodePacked(type(UserAccount).creationCode, owner, address(0), address(0)), bytes32(keccak256(abi.encodePacked(owner, _salt))));
    }

}