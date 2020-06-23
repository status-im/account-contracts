pragma solidity >=0.5.0 <0.7.0;

import "./Account.sol";
import "./ERC725.sol";
import "../cryptography/ECDSA.sol";
import "../common/Controlled.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice Defines an account which can be setup by a owner address (multisig contract), recovered by a recover address (a sort of secret multisig contract), and execute actions from a list of addresses (authorized contracts, extensions, etc)
 */
contract Identity is ERC725, Account, Controlled {
    string internal constant ERR_BAD_PARAMETER = "Bad parameter";
    string internal constant ERR_UNAUTHORIZED = "Unauthorized";


    mapping(bytes32 => bytes) store;

    constructor(address _controller) public Controlled(_controller) {

    }

    /**
     * @notice Add public data to account. Can only be called by management. ERC725 interface.
     * @param _key identifier
     * @param _value data
     */
    function setData(bytes32 _key, bytes calldata _value)
        external
        onlyController
    {
        store[_key] = _value;
        emit DataChanged(_key, _value);
    }

    /**
     * @notice ERC725 universal execute interface
     * @param _execData data to be executed in this contract
     * @return success status and return data
     */
    function execute(
        bytes calldata _execData
    )
        external
        onlyController
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = address(this).delegatecall(_execData);
    }

    /**
     * @notice calls another contract
     * @param _to destination of call
     * @param _value call ether value (in wei)
     * @param _data call data
     * @return internal transaction status and returned data
     */
    function call(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyController
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _call(_to, _value, _data);
    }

    /**
     * @notice Approves `_to` spending ERC20 `_baseToken` a total of `_value` and calls `_to` with `_data`. Useful for a better UX on ERC20 token use, and avoid race conditions.
     * @param _baseToken ERC20 token being approved to spend
     * @param _to Destination of contract accepting this ERC20 token payments through approve
     * @param _value amount of ERC20 being approved
     * @param _data abi encoded calldata to be executed in `_to` after approval.
     * @return internal transaction status and returned data
     */
    function approveAndCall(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyController
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _approveAndCall(_baseToken, _to, _value, _data);
    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return created contract address
     */
    function create(
        uint256 _value,
        bytes calldata _code
    )
        external
        onlyController
        returns(address createdContract)
    {
        (createdContract) = _create(_value, _code);
        require(isContract(createdContract), ERR_CREATE_FAILED);
    }

    /**
     * @notice creates deterministic address contract using on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @param _salt changes the resulting address
     * @return created contract address
     */
    function create2(
        uint256 _value,
        bytes calldata _code,
        bytes32 _salt
    )
        external
        onlyController
        returns(address createdContract)
    {
        (createdContract) = _create2(_value, _code, _salt);
    }

    /**
     * @notice Reads data set in this account. ERC725 interface.
     * @param _key identifier
     * @return data
     */
    function getData(bytes32 _key)
        external
        view
        returns (bytes memory _value)
    {
        return store[_key];
    }

    /**
     * @notice checks if owner signed `_data`. ERC1271 interface.
     * @param _data Data signed
     * @param _signature owner's signature(s) of data
     */
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature
    )
        public
        view
        returns (bytes4 magicValue)
    {
        if(isContract(controller)){
            return Signer(controller).isValidSignature(_data, _signature);
        } else {
            return controller == ECDSA.recover(ECDSA.toERC191SignedMessage(address(this), _data), _signature) ? MAGICVALUE : bytes4(0xffffffff);
        }
    }
}