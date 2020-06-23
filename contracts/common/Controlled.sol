pragma solidity >=0.5.0 <0.7.0;

contract Controlled {
    string internal constant ERR_BAD_PARAMETER = "Bad parameter";
    string internal constant ERR_UNAUTHORIZED = "Unauthorized";
    event NewController(address controller);
    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
        require(msg.sender == controller, "Unauthorized");
        _;
    }

    address payable public controller;

    constructor(address payable _initController) internal {
        require(_initController != address(0), ERR_BAD_PARAMETER);
        controller = _initController;
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address payable _newController) public onlyController {
        controller = _newController;
        emit NewController(_newController);
    }
}
