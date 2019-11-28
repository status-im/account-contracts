pragma solidity >=0.5.0 <0.6.0;

import "../cryptography/MerkleProof.sol";
import "../cryptography/ECDSA.sol";
import "../token/ERC20Token.sol";
import "./Identity.sol";
import "../common/Controlled.sol";


interface PaymentNetwork {
    function process(ERC20Token token, address from, address to, uint256 value) external;
}

/**
 * @notice Payment Network Actor for Account Contract
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @author Andrea Franz (Status Research & Development GmbH)
 */
contract PaymentNetworkActor is Controlled {
    PaymentNetwork public paymentNetwork;
    address public keycard;
    uint256 public nonce;
    Settings public settings;
    mapping(address => uint) public pendingWithdrawals;

    struct Settings {
        uint256 maxTxValue;
    }

    constructor(PaymentNetwork _paymentNetwork, address _keycard, uint256 _maxTxValue) public {
        keycard = _keycard;
        settings.maxTxValue = _maxTxValue;
        paymentNetwork = _paymentNetwork;
        nonce = 0;
    }

    function setKeycard(address _keycard) public onlyController {
        keycard = _keycard;
    }

    function setSettings(uint256 _maxTxValue) public onlyController {
        settings.maxTxValue = _maxTxValue;
    }

    function requestPayment(
        bytes32 _hashToSign,
        bytes memory _signature,
        uint256 _nonce,
        ERC20Token _token,
        address payable _to,
        uint256 _value
    ) public {
        // check that a keycard address has been set
        require(keycard != address(0), "keycard address not set");

        // check that the _hashToSign has been produced with the nonce, to, and value
        bytes32 expectedHash = ECDSA.toERC191SignedMessage(0x00, abi.encodePacked(address(this), _nonce, _token, _to, _value));
        require(expectedHash == _hashToSign, "signed params are different");

        // check that the _hashToSign has been signed by the keycard
        address signer = ECDSA.recover(_hashToSign, _signature);
        require(signer == keycard, "signer is not the keycard");

        // check that the nonce is valid
        require(nonce == _nonce, "invalid nonce");

        // check that _value is not greater than settings.maxTxValue
        require(_value <= settings.maxTxValue, "amount not allowed");

        // increment nonce
        nonce++;

        //calls identity to execute approval of token withdraw by payment network
        Identity(controller).call(address(_token), 0, abi.encodeWithSelector(_token.approve.selector, paymentNetwork, _value));
        
        //calls payment network to process payment
        paymentNetwork.process(_token, controller, _to, _value);
    }

}