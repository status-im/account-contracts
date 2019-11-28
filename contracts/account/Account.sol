pragma solidity >=0.5.0 <0.6.0;

import "../token/ERC20Token.sol";

/**
 * @notice Abstract account logic. Tracks nonce for the internal functions of call, approveAndCall, create and create2. Default function is payable with no events/logic.
 */
contract Account {

    event Executed(uint256 nonce, bool success, bytes returndata);
    event Deployed(uint256 nonce, bool success, address returnaddress);
    string internal constant ERR_BAD_TOKEN_ADDRESS = "Bad token address";
    string internal constant ERR_BAD_DESTINATION = "Bad destination";

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
        (success,returndata) = _to.call.value(_value)(_data); //external call
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
        (success,returndata) = _to.call.gas(_gas).value(_value)(_data); //external call
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
        returns (bool, address payable)
    {
        bool failed;
        address payable createdContract;
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE deploy
        assembly {
            createdContract := create(_value, add(_code, 0x20), mload(_code)) //deploy
            failed := iszero(extcodesize(createdContract))
        }
        emit Deployed(_nonce, !failed, createdContract);
        return(!failed, createdContract);
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
        returns (bool, address payable)
    {
        bool failed;
        address payable createdContract;
        uint256 _nonce = nonce++; // Important: Must be incremented always BEFORE deploy
        assembly {
            createdContract := create2(_value, add(_code, 0x20), mload(_code), _salt) //deploy
            failed := iszero(extcodesize(createdContract))
        }
        emit Deployed(_nonce, !failed, createdContract);
        return(!failed, createdContract);
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
        require(_baseToken != address(0), ERR_BAD_TOKEN_ADDRESS); //_baseToken should be something!
        require(_to != address(0) && _to != address(this), ERR_BAD_DESTINATION); //need valid destination
        ERC20Token(_baseToken).approve(_to, _value); //external call
        (success, returndata) = _to.call(_data); //external NO VALUE call
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
        require(_baseToken != address(0), ERR_BAD_TOKEN_ADDRESS); //_baseToken should be something!
        require(_to != address(0) && _to != address(this), ERR_BAD_DESTINATION); //need valid destination
        ERC20Token(_baseToken).approve(_to, _value); //external call
        (success, returndata) = _to.call.gas(_gas)(_data); //external NO VALUE call
        emit Executed(_nonce, success, returndata);
    }

}