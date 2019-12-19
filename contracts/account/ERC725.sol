pragma solidity >=0.5.0 <0.6.0;

interface ERC725 {
    event DataChanged(bytes32 indexed key, bytes value);

    function execute(bytes calldata _execData) external returns (bool success, bytes memory returndata);
    function getData(bytes32 _key) external view returns (bytes memory _value);
    function setData(bytes32 _key, bytes calldata _value) external;
}