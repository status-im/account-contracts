pragma solidity >=0.5.0 <0.6.0;

import "../gasrelay/GasRelay.sol";
import "./Actor.sol";
import "../common/Controlled.sol";


contract GasAbstractActor is Controlled, GasRelay {
    Actor public actor;
    uint256 public nonce;

    modifier gasRelay(
        bytes memory _execData,
        uint _gasPrice,
        uint _gasLimit,
        address _gasToken,
        address payable _gasRelayer,
        bytes memory _signature
    ){
        //query current gas available
        uint startGas = gasleft();

        //verify transaction parameters
        require(startGas >= _gasLimit, ERR_BAD_START_GAS);

        //verify if signatures are valid and came from correct actor;
        require(
            isValidSignature(
                abi.encodePacked(
                    address(this),
                    _execData,
                    _gasPrice,
                    _gasLimit,
                    _gasToken
                ),
                _signature
            ) == MAGICVALUE,
            ERR_BAD_SIGNER
        );
        nonce++;
        _;

        //refund gas used using contract held ERC20 tokens or ETH
        payGasRelayer(
            startGas,
            _gasPrice,
            _gasLimit,
            _gasToken,
            _gasRelayer
        );
    }


    /**
     * @notice include ethereum signed callHash in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
     *         allows identity of being controlled without requiring ether in key balace
     * @param _to destination of call
     * @param _value call value (ether)
     * @param _data call data
     * @param _gasPrice price in SNT paid back to `msg.sender` per gas unit used
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
        external
        gasRelay(
            abi.encodePacked(
                MSG_CALL_GASRELAY_PREFIX,
                _to,
                _value,
                _data,
                nonce,
                msg.sender
            ),
            _gasPrice,
            _gasLimit,
            _gasToken,
            msg.sender,
            _signature
        )
    {
        actor.call.gas(_gasLimit)(_to, _value, _data);
    }

    /**
     * @notice deploys contract in return of gas proportional amount multiplied by `_gasPrice` of `_gasToken`
     *         allows identity of being controlled without requiring ether in key balace
     * @param _value call value (ether) to be sent to newly created contract
     * @param _data contract code data
     * @param _gasPrice price in SNT paid back to `msg.sender` per gas unit used
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
        external
        gasRelay(
            abi.encodePacked(
                MSG_DEPLOY_GASRELAY_PREFIX,
                _value,
                _data,
                nonce,
                msg.sender
            ),
            _gasPrice,
            _gasLimit,
            _gasToken,
            msg.sender,
            _signature
        )
    {
        actor.create(_value, _data);
    }

    /**
     * @notice include ethereum signed approve ERC20 and call hash
     *         (`ERC20Token(baseToken).approve(_to, _value)` + `_to.call(_data)`).
     *         in return of gas proportional amount multiplied by `_gasPrice` of `_baseToken`
     *         fixes race condition in double transaction for ERC20.
     * @param _baseToken token approved for `_to` and token being used for paying `msg.sender`
     * @param _to destination of call
     * @param _value call value (in `_baseToken`)
     * @param _data call data
     * @param _gasPrice price in SNT paid back to `msg.sender` per gas unit used
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
        external
        gasRelay(
            abi.encodePacked(
                MSG_APPROVEANDCALL_GASRELAY_PREFIX,
                _baseToken,
                _to,
                _value,
                _data,
                nonce,
                msg.sender
            ),
            _gasPrice,
            _gasLimit,
            _baseToken,
            msg.sender,
            _signature
        )
    {
        actor.approveAndCall(_baseToken, _to, _value, _data, _gasLimit);
    }

    /**
     * @notice checks if owner signed `_data`. ERC1271 interface.
     * @param _data Data signed
     * @param _signature owner's signature(s) of data
     */
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature
    )
        public
        view
        returns (bytes4 magic1Value)
    {
        if(isContract(controller)){
            return ERC1271(controller).isValidSignature(_data, _signature);
        } else {
            return controller == ECDSA.recover(ECDSA.toERC191SignedMessage(_data), _signature);
        }
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
        private
    {
        uint256 _amount = 21000 + (_startGas - gasleft());
        require(_gasLimit == 0 || _amount <= _gasLimit, ERR_GAS_LIMIT_EXCEEDED);
        if (_gasPrice > 0) {
            _amount = _amount * _gasPrice;
            if (_gasToken == address(0)) {
                actor.call(_gasRelayer, _amount, new bytes(0));
            } else {
                actor.call(_gasToken, 0, abi.encodeWithSelector(ERC20Token.transfer.selector, _gasRelayer, _value));
            }
        }
    }
}