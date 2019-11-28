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

    modifier management {
        require(msg.sender == address(owner) || msg.sender == address(this), ERR_UNAUTHORIZED);
        _;
    }

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

    function setRecovery(address _recovery)
        external
        management
    {
        require(recoveryContract == address(0), ERR_UNAUTHORIZED);
        recoveryContract = _recovery;
    }

    function recoverAccount(ERC1271 newOwner)
        external
    {
        require(recoveryContract == msg.sender, ERR_UNAUTHORIZED);
        owner = newOwner;
        actorsEnabled = false;
    }

    function setData(bytes32 _key, bytes calldata _value)
        external
        management
    {
        store[_key] = _value;
        emit DataChanged(_key, _value);
    }

    function setActorsEnabled(bool _actorsEnabled)
        external
        management
    {
        actorsEnabled = _actorsEnabled;
    }

    function addActor(address newActor)
        external
        management
    {
        require(!isActor[newActor], "Already defined");
        actors.push(newActor);
        isActor[newActor] = true;
    }

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

    function changeOwner(address newOwner)
        external
        management
    {
        require(address(newOwner) != address(0), ERR_BAD_PARAMETER);
        owner = ERC1271(newOwner);
    }

    function call(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(_to)
        returns(bool, bytes memory)
    {
        _call(_to, _value, _data);
    }

    function approveAndCall(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(_to)
        returns(bool, bytes memory)
    {
        _approveAndCall(_baseToken, _to, _value, _data);
    }

    function create(
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(address(0))
        returns(bool, address)
    {
        _create(_value, _data);
    }

    function create2(
        uint256 _value,
        bytes calldata _data,
        bytes32 _salt
    )
        external
        authorizedAction(address(0))
        returns(bool, address)
    {
        _create2(_value, _data, _salt);
    }

    function getData(bytes32 _key)
        external
        view
        returns (bytes memory _value)
    {
        return store[_key];
    }

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