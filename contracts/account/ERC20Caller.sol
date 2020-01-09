pragma solidity >=0.5.0 <0.7.0;

import "../token/ERC20Token.sol";

/**
 * @notice Enables the use of approve and call for contracts accepting an ERC20 token through approval.
 */
contract ERC20Caller {

    string internal constant ERR_BAD_TOKEN_ADDRESS = "Bad token address";
    string internal constant ERR_BAD_DESTINATION = "Bad destination";

    /**
     * @dev abstract contract
     */
    constructor() internal {

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
        require(_baseToken != address(0) && _baseToken != address(this), ERR_BAD_TOKEN_ADDRESS); //_baseToken should be something!
        require(_to != address(0) && _to != address(this), ERR_BAD_DESTINATION); //need valid destination
        ERC20Token(_baseToken).approve(_to, _value);
        (success, returndata) = _to.call(_data); //NO VALUE call
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
        require(_baseToken != address(0) && _baseToken != address(this), ERR_BAD_TOKEN_ADDRESS); //_baseToken should be something!
        require(_to != address(0) && _to != address(this), ERR_BAD_DESTINATION); //need valid destination
        ERC20Token(_baseToken).approve(_to, _value);
        (success, returndata) = _to.call.gas(_gas)(_data); //NO VALUE call
    }

}