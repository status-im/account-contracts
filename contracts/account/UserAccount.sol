pragma solidity >=0.5.0 <0.6.0;

import "./UserAccountInterface.sol";
import "./AccountGasAbstract.sol";
import "../cryptography/ECDSA.sol";
import "../common/LibBytes.sol";

/**
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @notice Defines an account which can be setup by a owner address (multisig contract), recovered by a recover address (a sort of secret multisig contract), and execute actions from a list of addresses (authorized contracts, extensions, etc)
 */
contract UserAccount is UserAccountInterface, AccountGasAbstract {
    using LibBytes for bytes
    ;
    string internal constant ERR_BAD_PARAMETER = "Bad parameter";
    string internal constant ERR_UNAUTHORIZED = "Unauthorized";
    string internal constant ERR_CREATE_FAILED = "Contract creation failed";
    uint256 constant OPERATION_CALL = 0;
    uint256 constant OPERATION_CREATE = 1;
    mapping(bytes32 => bytes) store;

    address public owner;
    address public recovery;
    address public actor;

    /**
     * Allow only calls from itself or directly from owner
     */
    modifier management {
        require(msg.sender == address(owner) || msg.sender == address(this), ERR_UNAUTHORIZED);
        _;
    }

    /**
     * @dev Allow calls only from actor to external addresses, or any call from owner
     */
    modifier authorizedAction(address _to) {
        require(
            (
                msg.sender == actor && //must be an actor
                _to != address(this)  //can only call external address
            ) || msg.sender == address(owner), //owner can anything
            ERR_UNAUTHORIZED);
        _;
    }

    /**
     * @notice Defines recovery address. Can only be called by owner when no recovery is set, or by recovery.
     * @param _recovery address of recovery contract
     */
    function setRecovery(address _recovery)
        external
    {
        require(
            (
                msg.sender == owner && recovery == address(0)
            ) || msg.sender == recovery,
            ERR_UNAUTHORIZED
        );
        recovery = _recovery;
    }

    /**
     * @notice Defines the new owner and disable actor. Can only be called by recovery.
     * @param newOwner an ERC1271 contract or externally owned account
     */
    function recoverAccount(address newOwner)
        external
    {
        require(recovery == msg.sender, ERR_UNAUTHORIZED);
        require(newOwner != address(0), ERR_BAD_PARAMETER);
        owner = newOwner;
        actor = address(0);
    }

    /**
     * @notice Add public data to account. Can only be called by management. ERC725 interface.
     * @param _key identifier
     * @param _value data
     */
    function setData(bytes32 _key, bytes calldata _value)
        external
        management
    {
        store[_key] = _value;
        emit DataChanged(_key, _value);
    }

    /**
     * @notice Changes actor contract
     * @param _actors Contract which can call actions from this contract
     */
    function setActors(address _actors)
        external
        management
    {
        actor = _actors;
    }

    /**
     * @notice Replace owner address.
     * @param newOwner address of externally owned account or ERC1271 contract to control this account
     */
    function changeOwner(address newOwner)
        external
        management
    {
        require(newOwner != address(0), ERR_BAD_PARAMETER);
        owner = newOwner;
    }

    /**
     * @notice ERC725 execute interface
     * @param _operationType destination of call
     * @param _to destination of call
     * @param _value call ether value (in wei)
     * @param _data call data
     */
    function execute(
        uint256 _operationType,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(_to)
    {
        if (_operationType == OPERATION_CALL) {
            _call(_to, _value, _data);
        } else if (_operationType == OPERATION_CREATE) {
            require(_to == address(0), "Bad parameter");
            _create(_value, _data);
        } else {
            revert("Unsupported");
        }
    }

    /**
     * @notice calls another contract
     * @param _to destination of call
     * @param _value call ether value (in wei)
     * @param _data call data
     * @return internal transaction status and returned data
     */
    function call(
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(_to)
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _call(_to, _value, _data);
    }

    /**
     * @notice Approves `_to` spending ERC20 `_baseToken` a total of `_value` and calls `_to` with `_data`. Useful for a better UX on ERC20 token use, and avoid race conditions.
     * @param _baseToken ERC20 token being approved to spend
     * @param _to Destination of contract accepting this ERC20 token payments through approve
     * @param _value amount of ERC20 being approved
     * @param _data abi encoded calldata to be executed in `_to` after approval.
     * @return internal transaction status and returned data
     */
    function approveAndCall(
        address _baseToken,
        address _to,
        uint256 _value,
        bytes calldata _data
    )
        external
        authorizedAction(_to)
        returns(bool success, bytes memory returndata)
    {
        (success, returndata) = _approveAndCall(_baseToken, _to, _value, _data);
    }

    /**
     * @notice creates new contract based on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @return created contract address
     */
    function create(
        uint256 _value,
        bytes calldata _code
    )
        external
        authorizedAction(address(0))
        returns(address createdContract)
    {
        (createdContract) = _create(_value, _code);
        require(isContract(createdContract), ERR_CREATE_FAILED);
    }

    /**
     * @notice creates deterministic address contract using on input `_code` and transfer `_value` ETH to this instance
     * @param _value amount ether in wei to sent to deployed address at its initialization
     * @param _code contract code
     * @param _salt changes the resulting address
     * @return created contract address
     */
    function create2(
        uint256 _value,
        bytes calldata _code,
        bytes32 _salt
    )
        external
        authorizedAction(address(0))
        returns(address createdContract)
    {
        (createdContract) = _create2(_value, _code, _salt);
        require(isContract(createdContract), ERR_CREATE_FAILED);
    }

    /**
     * @notice Reads data set in this account. ERC725 interface.
     * @param _key identifier
     * @return data
     */
    function getData(bytes32 _key)
        external
        view
        returns (bytes memory _value)
    {
        return store[_key];
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
        returns (bytes4 magicValue)
    {
        if(isContract(owner)){
            return Signer(owner).isValidSignature(_data, _signature);
        } else {
            return owner == ECDSA.recover(ECDSA.toERC191SignedMessage(_data), _signature) ? ERC1271_TRUE : ERC1271_FALSE;
        }
    }

    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        require(
            signature.length > 0,
            "LENGTH_GREATER_THAN_0_REQUIRED"
        );

        // Ensure signature is supported
        uint8 signatureTypeRaw = uint8(signature.popLastByte());
        require(
            signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
            "SIGNATURE_UNSUPPORTED"
        );

        // Pop last byte off of signature byte array.
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        if (signatureType == SignatureType.Illegal) {
            revert("SIGNATURE_ILLEGAL");
        } else if (signatureType == SignatureType.Invalid) {
            require(
                signature.length == 0,
                "LENGTH_0_REQUIRED"
            );
            isValid = false;
            return isValid;
        } else if (signatureType == SignatureType.Validator) {
            address validatorAddress = signature.popLast20Bytes();
            if(validatorAddress == owner || validatorAddress == actor) {
                return false;
            }
            isValid = Signer(validatorAddress).isValidSignature(
                hash,
                signerAddress,
                signature
            );
            return isValid;
        }

        if(signerAddress != owner && signerAddress != actor) {
            return false;
        }
        
        if (signatureType == SignatureType.EIP712) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(hash, v, r, s);
            isValid = signerAddress == recovered;
            return isValid;
        } else if (signatureType == SignatureType.EthSign || signatureType == SignatureType.Trezor) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(
                ECDSA.toEthSignedMessageHash(hash),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;
            return isValid;

        } else if (signatureType == SignatureType.Caller) {
            require(
                signature.length == 0,
                "LENGTH_0_REQUIRED"
            );
            isValid = signerAddress == msg.sender;
            
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = Signer(signerAddress).isValidSignature(abi.encode(hash), signature);
            return isValid;
        }
        revert("SIGNATURE_UNSUPPORTED");
    }

}