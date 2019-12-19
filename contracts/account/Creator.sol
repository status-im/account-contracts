pragma solidity >=0.5.0 <0.6.0;

/**
 * @notice wrapper for _create and _create2
 */
contract Creator {

    /**
     * @dev abstract contract
     */
    constructor() internal {

    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return created contract address
     */
    function _create(
        uint _value,
        bytes memory _code
    )
        internal
        returns (address payable createdContract)
    {
        assembly {
            createdContract := create(_value, add(_code, 0x20), mload(_code))
        }
    }

    /**
     * @notice creates deterministic address with salt `_salt` contract using on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @param _salt changes the resulting address
     * @return created contract address
     */
    function _create2(
        uint _value,
        bytes memory _code,
        bytes32 _salt
    )
        internal
        returns (address payable createdContract)
    {
        assembly {
            createdContract := create2(_value, add(_code, 0x20), mload(_code), _salt)
        }
    }

    function _computeContractAddress(bytes memory _code, bytes32 _salt) internal view returns (address _contractAddress) {
        bytes32 _data = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                _salt,
                _code
            )
        );

        _contractAddress = address(bytes20(_data << 96));
    }

}