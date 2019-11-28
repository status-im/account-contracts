pragma solidity >=0.5.0 <0.6.0;

import "./UserAccountInterface.sol";
import "../common/Controlled.sol";
import "./Actor.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract ActorsAllowed is Actor, Controlled {

    address[] public actors;
    mapping(address => bool) public isActor;

    modifier onlyActors {
        require(isActor[msg.sender], "Unauthorized");
        _;
    }
    /**
     * @notice Adds a new actor that could arbitrarely call external contracts. If specific permission logic (e.g. ACL), it can be implemented in the actor's address contract logic.
     * @param newActor a new actor to be added.
     */
    function addActor(address newActor)
        external
        onlyController
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
        onlyController
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
        onlyActors
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = UserAccountInterface(controller).call(_to, _value, _data);
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
        onlyActors
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = UserAccountInterface(controller).approveAndCall(_baseToken, _to, _value, _data);
    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return creation success status and created contract address
     */
    function create(
        uint256 _value,
        bytes calldata _code
    )
        external
        onlyActors
        returns(address createdContract)
    {
        createdContract = UserAccountInterface(controller).create(_value, _code);
    }

}