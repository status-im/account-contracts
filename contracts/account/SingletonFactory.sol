pragma solidity >=0.5.0 <0.7.0;

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice Singleton Factory (ERC-2470) deploys deterministic addresses based on it's initialization code.
 */
contract SingletonFactory {
    /**
     * @notice Deploys a deterministic address based on `_initCode`.
     * @param _initCode Initialization code.
     * @return Created contract address.
     */
    function deploy(bytes memory _initCode)
        public
        returns (address payable createdContract)
    {
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), 0)
        }
    }
    // IV is value needed to have a vanity address starting with '0x2470'.
    // IV: 0
}