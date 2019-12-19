pragma solidity >=0.5.0 <0.6.0;

/**
 * @title GasRelay
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice gas abstraction interface
 */
contract GasRelay {

    bytes4 internal constant MSG_EXECUTE_GASRELAY_PREFIX = bytes4(
        keccak256("executeGasRelay(bytes,uint256,uint256,address,address)")
    );

    constructor() internal {}

    /**
     * @notice execute something for this account and get paid the proportional gas in specified token.
     * @param _execData execution data (anything)
     * @param _gasPrice price in `_gasToken` paid back to `msg.sender` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `msg.sender`, if address(0), ether is used
     * @param _signature rsv concatenated ethereum signed message signatures required
     */
    function executeGasRelay(
        bytes calldata _execData,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken,
        bytes calldata _signature
    )
        external;

    /**
     * @notice get signing message for executeGasRelay function.
     * @param _nonce current account nonce
     * @param _execData execution data (anything)
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @param _gasRelayer beneficiary of gas refund
     * @return executeGasRelayMsg the message to be signed
     */
    function executeGasRelayMsg(
        uint256 _nonce,
        bytes memory _execData,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken,
        address _gasRelayer
    )
        public
        view
        returns (bytes memory)
    {
        return abi.encodePacked(
            address(this),
            _nonce,
            MSG_EXECUTE_GASRELAY_PREFIX,
            _execData,
            _gasPrice,
            _gasLimit,
            _gasToken,
            _gasRelayer
        );
    }
}
