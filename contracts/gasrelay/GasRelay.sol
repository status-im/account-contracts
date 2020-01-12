pragma solidity >=0.5.0 <0.7.0;

/**
 * @title GasRelay as EIP-1077
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice gas abstraction interface
 */
contract GasRelay {

    bytes4 internal constant MSG_EXECUTE_GASRELAY_PREFIX = bytes4(
        keccak256("executeGasRelay(uint256,bytes,uint256,uint256,address,address)")
    );

    constructor() internal {}

    /**
     * @notice executes `_execData` with current `nonce()` and pays `msg.sender` the gas used in specified `_gasToken`.
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

    function lastNonce() public view returns (uint nonce);
    
    /**
     * @notice gets ERC191 signing Hash of execute gas relay message
     * @param _nonce current account nonce
     * @param _execData execution data (anything)
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @param _gasRelayer beneficiary of gas refund
     * @return executeGasRelayERC191Hash the message to be signed
     */
    function executeGasRelayERC191Msg(
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
            toERC191SignedMessage(
                address(this),
                executeGasRelayMsg(
                    _nonce,
                    _execData,
                    _gasPrice,
                    _gasLimit,
                    _gasToken,
                    _gasRelayer
                )
            )
        );
    }

    /**
     * @notice get message for executeGasRelay function.
     * @param _nonce current account nonce
     * @param _execData execution data (anything)
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @param _gasRelayer beneficiary of gas refund
     * @return executeGasRelayMsg the appended message
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
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _getChainID(),
            MSG_EXECUTE_GASRELAY_PREFIX,
            _nonce,
            _execData,
            _gasPrice,
            _gasLimit,
            _gasToken,
            _gasRelayer
        );
    }

    /**
     * @notice get network identification where this contract is running
     */
    function _getChainID() internal pure returns (uint256) {
        uint256 id = 1;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns an ERC191 Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_signTypedData`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toERC191SignedMessage(address _validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(byte(0x19), byte(0x0), _validator, data));
    }

}
