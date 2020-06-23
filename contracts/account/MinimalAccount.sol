pragma solidity >=0.5.0 <0.7.0;

contract MinimalAccount {
    event DataChanged(bytes32 indexed key, bytes value);
    event OwnerChanged(address indexed ownerAddress);
    address public owner;
    mapping(bytes32 => bytes) store;

    modifier onlyOwner {
        require(msg.sender == address(owner), "403");
        _;
    }

    modifier self {
        require(msg.sender == address(this), "403");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function execute(
        bytes calldata _execData
    )
        external
        onlyOwner
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = address(this).call(_execData);
        require(success);
    }

    function call(
        address _to,
        bytes calldata _data
    )
        external
        self
        returns (bool success, bytes memory returndata)
    {
        (success, returndata) = _to.call(_data);
    }
    
    function setData(bytes32 _key, bytes calldata _value)
        external
        self
    {
        store[_key] = _value;
        emit DataChanged(_key, _value);
    }

    function changeOwner(address newOwner)
        external
        self
    {
        require(newOwner != address(0), "Bad parameter");
        owner = newOwner;
        emit OwnerChanged(newOwner);
    }

    function getData(bytes32 _key)
        external
        view
        returns (bytes memory _value)
    {
        return store[_key];
    }
}