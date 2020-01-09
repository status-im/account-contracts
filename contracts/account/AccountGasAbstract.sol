pragma solidity >=0.5.0 <0.7.0;

import "./Account.sol";
import "../gasrelay/GasRelay.sol";

/**
 * @title AccountGasAbstract
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice defines account gas abstract
 */
contract AccountGasAbstract is Account, GasRelay {
    string internal constant ERR_INVALID_SIGNATURE = "Invalid signature";

    modifier gasRelay(
        bytes memory _execData,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken,
        address payable _gasRelayer,
        bytes memory _signature
    ){
        //query current gas available
        uint startGas = gasleft();

        //verify if signatures are valid and came from correct actor;
        require(
            isValidSignature(
                executeGasRelayERC191Msg(
                    nonce,
                    _execData,
                    _gasPrice,
                    _gasLimit,
                    _gasToken,
                    _gasRelayer
                ),
                _signature
            ) == MAGICVALUE,
            ERR_INVALID_SIGNATURE
        );

        _;

        //refund gas used using contract held ERC20 tokens or ETH
        if (_gasPrice > 0) {
            payGasRelayer(
                startGas,
                _gasPrice,
                _gasToken,
                _gasRelayer
            );
        }
    }

    function executeGasRelay(
        bytes calldata _execData,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken,
        bytes calldata _signature
    )
        external
        gasRelay(
            _execData,
            _gasPrice,
            _gasLimit,
            _gasToken,             
            msg.sender,
            _signature
        )
    {
        address(this).call.gas(_gasLimit)(_execData);
    }

    function canExecute(
        bytes memory _execData,
        uint256 _gasPrice,
        uint256 _gasLimit,
        address _gasToken,
        address _gasRelayer,
        bytes memory _signature
    )
        public
        view
        returns (bool)
    {
        return isValidSignature(
            executeGasRelayMsg(
                nonce,
                _execData,
                _gasPrice,
                _gasLimit,
                _gasToken,
                _gasRelayer
            ),
            _signature
        ) == MAGICVALUE;
    }
    
    function lastNonce() public view returns (uint256) {
        return nonce;
    }

    /**
     * @notice check gas limit and pays gas to relayer
     * @param _startGas gasleft on call start
     * @param _gasPrice price in `_gasToken` paid back to `_gasRelayer` per gas unit used
     * @param _gasToken token being used for paying `_gasRelayer`
     * @param _gasRelayer beneficiary of the payout
     */
    function payGasRelayer(
        uint256 _startGas,
        uint256 _gasPrice,
        address _gasToken,
        address payable _gasRelayer
    )
        internal
    {
        uint256 _amount = (100000 + (_startGas - gasleft()) * _gasPrice);
        if (_gasToken == address(0)) {
            _gasRelayer.call.value(_amount)("");
        } else {
            ERC20Token(_gasToken).transfer(_gasRelayer, _amount);
        }
    }
}