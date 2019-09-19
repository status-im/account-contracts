pragma solidity >=0.5.0 <0.6.0;

import "../token/ERC20Token.sol";

/**
 * @title GasRelay
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice abstract gas abstraction
 */
contract GasRelay {

    bytes4 internal constant MSG_CALL_GASRELAY_PREFIX = bytes4(
        keccak256("callGasRelay(address,uint256,bytes,uint256,address,uint256,uint256,address)")
    );
    bytes4 internal constant MSG_DEPLOY_GASRELAY_PREFIX = bytes4(
        keccak256("deployGasRelay(uint256,bytes,uint256,address,uint256,uint256,address)")
    );

    bytes4 internal constant MSG_APPROVEANDCALL_GASRELAY_PREFIX = bytes4(
        keccak256("approveAndCallGasRelay(address,address,uint256,bytes,uint256,address,uint256,uint256)")
    );

    string internal constant ERR_BAD_START_GAS = "Bad start gas";
    string internal constant ERR_BAD_NONCE = "Bad nonce";
    string internal constant ERR_BAD_SIGNER = "Bad signer";
    string internal constant ERR_GAS_LIMIT_EXCEEDED = "Gas limit exceeded";
    string internal constant ERR_BAD_TOKEN_ADDRESS = "Bad token address";
    string internal constant ERR_BAD_DESTINATION = "Bad destination";

    constructor() internal {}

    /**
     * @notice include ethereum signed callHash in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
     *         allows account of being controlled without requiring ether in key balace
     * @param _to destination of call
     * @param _value call value (ether)
     * @param _data call data
     * @param _gasPrice price in `_gasToken` paid back to `msg.sender` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `msg.sender`
     * @param _signature rsv concatenated ethereum signed message signatures required
     */
    function callGasRelay(
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        bytes calldata _signature
    )
        external;

    /**
     * @notice deploys contract in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
     *         allows account of being controlled without requiring ether in key balace
     * @param _value call value (ether) to be sent to newly created contract
     * @param _data contract code data
     * @param _gasPrice price in `_gasToken` paid back to `msg.sender` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `msg.sender`
     * @param _signature rsv concatenated ethereum signed message signatures required
     */
    function deployGasRelay(
        uint256 _value,
        bytes calldata _data,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        bytes calldata _signature
    )
        external;

   /**
     * @notice include ethereum signed approve ERC20 and call hash
     *         (`ERC20Token(baseToken).approve(_to, _value)` + `_to.call(_data)`).
     *         in return of gas proportional amount multiplied by `_gasPrice` of `_baseToken`
     *         fixes race condition in double transaction for ERC20.
     * @param _baseToken token approved for `_to` and token being used for paying `msg.sender`
     * @param _to destination of call
     * @param _value call value (in `_baseToken`)
     * @param _data call data
     * @param _gasPrice price in `_gasToken` paid back to `msg.sender` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _signature rsv concatenated ethereum signed message signatures required
     */
    function approveAndCallGasRelay(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes calldata _data,
        uint _gasPrice,
        uint _gasLimit,
        bytes calldata _signature
    )
        external;

    /**
     * @notice get callHash
     * @param _to destination of call
     * @param _value call value (ether)
     * @param _data call data
     * @param _nonce current account nonce
     * @param _gasRelayer beneficiary of gas refund
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @return callGasRelayHash the hash to be signed by wallet
     */
    function callGasRelayHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        address _gasRelayer,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                MSG_CALL_GASRELAY_PREFIX,
                _to,
                _value,
                _data,
                _nonce,
                _gasRelayer,
                _gasPrice,
                _gasLimit,
                _gasToken
            )
        );
    }

    function getNonce() external view returns(uint256);

    /**
     * @notice get deployGasRelayHash
     * @param _value value (ETH) sent together in deplpy
     * @param _data contract data
     * @param _nonce current account nonce
     * @param _gasRelayer beneficiary of gas refund
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @return deployGasRelayHash the hash to be signed by wallet
     */
    function deployGasRelayHash(
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        address _gasRelayer,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                MSG_DEPLOY_GASRELAY_PREFIX,
                _value,
                _data,
                _nonce,
                _gasRelayer,
                _gasPrice,
                _gasLimit,
                _gasToken
            )
        );
    }

    /**
     * @notice return approveAndCall Relay Hash
     * @param _baseToken token approved for `_to` and token being used for paying `_gasRelayer`
     * @param _to call destination
     * @param _value call value (in `_baseToken`)
     * @param _data call data
     * @param _nonce current account nonce
     * @param _gasRelayer beneficiary of gas refund
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transaction
     * @return approveAndCallHash the hash to be signed by wallet
     */
    function approveAndCallGasRelayHash(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _nonce,
        address _gasRelayer,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                address(this),
                MSG_APPROVEANDCALL_GASRELAY_PREFIX,
                _baseToken,
                _to,
                _value,
                _data,
                _nonce,
                _gasRelayer,
                _gasPrice,
                _gasLimit,
                _gasRelayer
            )
        );
    }

    /**
     * @notice check gas limit and pays gas to relayer
     * @param _startGas gasleft on call start
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasLimit maximum gas of this transacton
     * @param _gasToken token being used for paying `_gasRelayer`
     * @param _gasRelayer beneficiary of the payout
     */
    function payGasRelayer(
        uint256 _startGas,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        address payable _gasRelayer
    )
        internal
    {
        uint256 _amount = 21000 + (_startGas - gasleft());
        require(_gasLimit == 0 ||_amount <= _gasLimit, ERR_GAS_LIMIT_EXCEEDED);
        if (_gasPrice > 0) {
            _amount = _amount * _gasPrice;
            if (_gasToken == address(0)) {
                (_gasRelayer == address(0) ? block.coinbase : _gasRelayer).transfer(_amount);
            } else {
                ERC20Token(_gasToken).transfer(_gasRelayer == address(0) ? block.coinbase : _gasRelayer, _amount);
            }
        }
    }

}
