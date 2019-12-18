pragma solidity >=0.5.0 <0.6.0;

import "./Caller.sol";
import "./ERC20Caller.sol";
import "./Creator.sol";
import "./Signer.sol";

/**
 * @notice Abstract account logic. Tracks nonce and fire events for the internal functions of call, approveAndCall, create and create2. Default function is payable with no events/logic.
 */
contract Account is Caller, ERC20Caller, Creator, Signer {

    event Executed(uint256 nonce, bool success, bytes returndata);
    event Deployed(uint256 nonce, bool success, address returnaddress);

    uint256 public nonce;

    /**
     * @dev Does nothing, only to mark as abstract (internal)
     */
    constructor() internal {

    }

    /**
     * @dev Does nothing, accepts ETH value (payable)
     */
    function() external payable {

    }

    /**
     * @notice calls another contract
     * @param _to destination of call
     * @param _data call data
     * @return internal transaction status and returned data
     */
    function _call(
        address _to,
        bytes memory _data
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._call(_to, _data); //external call
        emit Executed(_nonce, success, returndata);
    }


    /**
     * @notice calls another contract
     * @param _to destination of call
     * @param _value call ether value (in wei)
     * @param _data call data
     * @return internal transaction status and returned data
     */
    function _call(
        address _to,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._call(_to, _value, _data); //external call
        emit Executed(_nonce, success, returndata);
    }

    /**
     * @notice calls another contract with limited gas
     * @param _to destination of call
     * @param _value call ether value (in wei)
     * @param _data call data
     * @param _gas gas to limit the internal transaction
     * @return internal transaction status and returned data
     */
    function _call(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _gas
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._call(_to, _value, _data, _gas); //external call
        emit Executed(_nonce, success, returndata);
    }

    /**
     * @notice calls another contract with limited gas
     * @param _to destination of call
     * @param _data call data
     * @param _gas gas to limit the internal transaction
     * @return internal transaction status and returned data
     */
    function _call(
        address _to,
        bytes memory _data,
        uint256 _gas
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._call(_to, _data, _gas); //external call
        emit Executed(_nonce, success, returndata);
    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return creation success status and created contract address
     */
    function _create(
        uint _value,
        bytes memory _code
    )
        internal
        returns (address payable createdContract)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE deploy
        createdContract = super._create(_value, _code);
        bool success = isContract(createdContract);
        emit Deployed(_nonce, success, createdContract);
    }

    /**
     * @notice creates deterministic address contract using on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @param _salt changes the resulting address
     * @return creation success status and created contract address
     */
    function _create2(
        uint _value,
        bytes memory _code,
        bytes32 _salt
    )
        internal
        returns (address payable createdContract)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE deploy
        createdContract = super._create2(_value, _code, _salt);
        bool success = isContract(createdContract);
        emit Deployed(_nonce, success, createdContract);
    }

    /**
     * @notice Approves `_to` spending ERC20 `_baseToken` a total of `_value` and calls `_to` with `_data`. Useful for a better UX on ERC20 token use, and avoid race conditions.
     * @param _baseToken ERC20 token being approved to spend
     * @param _to Destination of contract accepting this ERC20 token payments through approve
     * @param _value amount of ERC20 being approved
     * @param _data abi encoded calldata to be executed in `_to` after approval.
     * @return internal transaction status and returned data
     */
    function _approveAndCall(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes memory _data
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._approveAndCall(_baseToken, _to, _value, _data);
        emit Executed(_nonce, success, returndata);
    }

    /**
     * @notice Approves `_to` spending ERC20 `_baseToken` a total of `_value` and calls `_to` with `_data`. Useful for a better UX on ERC20 token use, and avoid race conditions.
     * @param _baseToken ERC20 token being approved to spend
     * @param _to Destination of contract accepting this ERC20 token payments through approve
     * @param _value amount of ERC20 being approved
     * @param _data abi encoded calldata to be executed in `_to` after approval.
     * @param _gas gas to limit the internal transaction
     * @return internal transaction status and returned data
     */
    function _approveAndCall(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _gas
    )
        internal
        returns (bool success, bytes memory returndata)
    {
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE external call
        (success, returndata) = super._approveAndCall(_baseToken, _to, _value, _data, _gas);
        emit Executed(_nonce, success, returndata);
    }

    /**
     * @dev Internal function to determine if an address is a contract
     * @param _target The address being queried
     * @return True if `_addr` is a contract
     */
    function isContract(address _target) internal view returns(bool result) {
        assembly {
            result := gt(extcodesize(_target), 0)
        }
    }
}