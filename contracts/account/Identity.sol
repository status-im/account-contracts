pragma solidity >=0.5.0 <0.6.0;

import "./AccountGasAbstract.sol";
import "./ERC725.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice Defines an account which can be setup by a owner address (multisig contract), recovered by a recover address (a sort of secret multisig contract), and execute actions from a list of addresses (authorized contracts, extensions, etc)
 */
contract Identity is AccountGasAbstract, ERC725 {
    string internal constant ERR_BAD_PARAMETER = "Bad parameter";
    string internal constant ERR_UNAUTHORIZED = "Unauthorized";
    mapping(bytes32 => bytes) store;

    ERC1271 public owner;
    address public recoveryContract;
    bool public actorsEnabled;
    address[] public actors;
    mapping(address => bool) public isActor;

    /**
     * Allow only calls from itself or directly from owner
     */
    modifier management {
        require(msg.sender == address(owner) || msg.sender == address(this), ERR_UNAUTHORIZED);
        _;
    }

    /**
     * @dev Allow calls only from actors to external addresses, or any call from owner
     */
    modifier authorizedAction(address _to) {
        require(
            (
                actorsEnabled && //only when actors are enabled
                isActor[msg.sender] && //must be an actor
                _to != address(this)  //can only call external address
            ) || msg.sender == address(owner), //owner can anything
            ERR_UNAUTHORIZED);
        _;
    }

    /**
     * @notice Defines recoveryContract address.
     * @param _recovery address of recoveryContract contract
     */
    function setRecovery(address _recovery)
        external
        management
    {
        require(recoveryContract == address(0), ERR_UNAUTHORIZED);
        recoveryContract = _recovery;
    }

    /**
     * @notice Defines the new owner and disable actors. Can only be called by recovery.
     * @param newOwner an ERC1271 contract
     */
    function recoverAccount(ERC1271 newOwner)
        external
    {
        require(recoveryContract == msg.sender, ERR_UNAUTHORIZED);
        owner = newOwner;
        actorsEnabled = false;
    }

    /**
     * @notice Add public data to account. Can only be called by management. ERC725 interface.
     * @param _key identifier
     * @param _value data
     */
    function setData(bytes32 _key, bytes calldata _value)
        external
        management
    {
        store[_key] = _value;
        emit DataChanged(_key, _value);
    }

    /**
     * @notice Changes permission of actors from calling other contracts.
     * @param _actorsEnabled enable switch of actors
     */
    function setActorsEnabled(bool _actorsEnabled)
        external
        management
    {
        actorsEnabled = _actorsEnabled;
    }

    /**
     * @notice Adds a new actor that could arbitrarely call external contracts. If specific permission logic (e.g. ACL), it can be implemented in the actor's address contract logic.
     * @param newActor a new actor to be added.
     */
    function addActor(address newActor)
        external
        management
    {
        require(!isActor[newActor], "Already defined");
        actors.push(newActor);
        isActor[newActor] = true;
    }

    /**
     * @notice Removes an actor
     * @param index position of actor in the `actors()` array list.
     */
    function removeActor(uint256 index)
        external
        management
    {
        uint256 lastPos = actors.length-1;
        require(index <= lastPos, "Index out of bounds");
        address removing = actors[index];
        isActor[removing] = false;
        if(index != lastPos){
            actors[index] = actors[lastPos];
        }
        actors.length--;
    }

    /**
     * @notice Replace owner address.
     * @param newOwner address of ERC1271 contract controlling this account
     */
    function changeOwner(address newOwner)
        external
        management
    {
        require(address(newOwner) != address(0), ERR_BAD_PARAMETER);
        owner = ERC1271(newOwner);
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
        authorizedAction(_to)
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
        authorizedAction(_to)
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _approveAndCall(_baseToken, _to, _value, _data);
    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return creation success status and created contract address
     */
    function create(
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(address(0))
        returns(bool success, address createdContract)
    {
        (success, createdContract) = _create(_value, _data);
    }

    /**
     * @notice creates deterministic address contract using on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @param _salt changes the resulting address
     * @return creation success status and created contract address
     */
    function create2(
        uint256 _value,
        bytes calldata _data,
        bytes32 _salt
    )
        external
        authorizedAction(address(0))
        returns(bool success, address createdContract)
    {
        (success, createdContract) = _create2(_value, _data, _salt);
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
     * @notice checks if owner signed `_data`
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
        //TODO: check if owner address contains code, if not, ecrecover directly and compare against address, otherwise use ERC1271
        return owner.isValidSignature(_data, _signature);
    }


}