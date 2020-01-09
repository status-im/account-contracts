pragma solidity >=0.5.0 <0.7.0;

/**
 * @notice wrapper for _call
 */
contract Caller {

    constructor() internal {

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
        (success, returndata) = _to.call(_data);
    }

    /**
     * @notice calls another contract with explicit value
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
        (success, returndata) = _to.call.value(_value)(_data);
    }

    /**
     * @notice calls another contract with explicit value and limited gas
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
        (success, returndata) = _to.call.gas(_gas).value(_value)(_data);
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
        (success, returndata) = _to.call.gas(_gas)(_data);
    }

}