pragma solidity >=0.5.0 <0.6.0;

import "../cryptography/MerkleProof.sol";
import "../cryptography/ECDSA.sol";
import "../token/ERC20Token.sol";
import "../common/TokenClaimer.sol";
import "../common/Controlled.sol";
import "../account/Signer.sol";
import "../ens/ENS.sol";
import "../ens/ResolverInterface.sol";

/**
 * @notice Select privately other accounts that will allow the execution of actions
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract MultisigRecovery is Controlled, TokenClaimer {
    bytes4 constant internal EIP1271_MAGICVALUE = 0x20c13b0b;
    ENS ens;
    /** # User Secret Data Public Hash
     * Hash of the hash of Semi-private information, such as a "randomly ordered personal information + secret answer", or user biometric data.
     * The secret should only be revaled together with `execute`, which requires changing the secret at every execution.
     * Contract is configured with a hash of a hash of this personal data hash. `keccak256(keccak256(user_secret_data)).
     * If case of using personal information, a form containing several fields of optional data, where, must be written only things that you can always know, but is not completely or usually public.
     * Some of this fields would be used to create tthe user data hash, when recovering user would have to enter the same fields again and automatically will try all combinations with that data until find whats used for the secret.
     * Example of an publicHash: keccak256("Alice Pleasance Liddell;1852-04-04;Lorina Hanna Liddell;England;Name of important childhood friend?Dodgson")
     * If case of user biometric data, most of sensors should be able to give more then one result for the same repetable reading for the same finger, or just a part of it is used.
     * When revealed, a different secret is needed, then another of that results from the biometric sensor.
     */
    bytes32 public publicHash;

    /** # Secret Threshold Hash
     * A hash of threshold (number of allowances needed to execute) hashed together with the "User Secret Data Hash"
     * Example: `keccak256(publicHash, threshold)`
     * Threshold number is revealed in execute, together with the "Secret User Data Hash" and its verified against what is configured in contract.
     * Threshold can be easily figured out if the Secret User Data Hash is known.
     */
    bytes32 public secretThresholdHash;

    /** # Secret Addresses Merkle Root
     * Each address is hashed against a hash of "User Secret Data Hash" (`kecakk256(keccak256(publicHash), friendAddress)` and a merkle tree is build in top of the dataset.
     * Addresses in this merkle tree would be able to approve a call for anything if they know the Hash of the "User Secret Data Hash".
     */
    bytes32 public addressListMerkleRoot;

    /** # Setup Delay
     * Amount of time delay needed to activate a new recovery setup
     */
    uint256 public setupDelay;

    //flag for used recoveries (user need to define a different publicHash every execute)
    mapping(bytes32 => bool) private revealed;
    //flag to prevent resigning
    mapping(bytes32 => mapping(bytes32 => bool)) private signed;
    //storage for pending delayed setup
    NewRecovery private pendingSetup;

    struct NewRecovery {
        uint256 timestamp;
        bytes32 publicHash;
        bytes32 secretThresholdHash;
        bytes32 addressListMerkleRoot;
        uint256 setupDelay;
    }

    event SetupRequested(uint256 activation);
    event Activated();
    event Approved(bytes32 indexed secretHash, address approver);
    event Execution(bool success);

    modifier notRevealed(bytes32 secretHash) {
        require(!revealed[secretHash], "Already revealed");
        _;
    }

    /**
     * @notice Contructor of FriendsRecovery
     * @param _controller Controller of this contract
     * @param _ens Address of ENS Registry
     * @param _publicHash Double hash of User Secret
     * @param _secretThresholdHash Secret Amount of approvals required
     * @param _addressListMerkleRoot Merkle root of new secret friends list
     * @param _setupDelay Delay for changes being active
     **/
    constructor(
        address payable _controller,
        ENS _ens,
        bytes32 _secretThresholdHash,
        bytes32 _publicHash,
        bytes32 _addressListMerkleRoot,
        uint256 _setupDelay
    )
        public
    {
        ens = _ens;
        controller = _controller;
        secretThresholdHash = _secretThresholdHash;
        publicHash = _publicHash;
        addressListMerkleRoot = _addressListMerkleRoot;
        setupDelay = _setupDelay;
    }

    /**
     * @notice This method can be used to extract mistakenly
     *  sent tokens to this contract.
     * @param _token The address of the token contract that you want to recover
     *  set to 0 in case you want to extract ether.
     */
    function claimTokens(address _token)
        external
        onlyController
    {
        withdrawBalance(_token, controller);
    }

    /**
     * @notice Cancels a pending setup to change the recovery parameters
     */
    function cancelSetup()
        external
        onlyController
    {
        delete pendingSetup;
        emit SetupRequested(0);
    }

    /**
     * @notice Configure recovery parameters `emits Activated()` if there was no previous setup, or `emits SetupRequested(now()+setupDelay)` when reconfiguring.
     * @param _publicHash Double hash of executeHash
     * @param _setupDelay Delay for changes being active
     * @param _secretThresholdHash Secret Amount of approvals required
     * @param _addressListMerkleRoot Merkle root of secret address list
     */
    function setup(
        bytes32 _publicHash,
        uint256 _setupDelay,
        bytes32 _secretThresholdHash,
        bytes32 _addressListMerkleRoot
    )
        external
        onlyController
        notRevealed(_publicHash)
    {
        if(publicHash == bytes32(0)){
            secretThresholdHash = _secretThresholdHash;
            publicHash = _publicHash;
            addressListMerkleRoot = _addressListMerkleRoot;
            setupDelay = _setupDelay;
            emit Activated();
        } else {
            pendingSetup.timestamp = block.timestamp;
            pendingSetup.publicHash = _publicHash;
            pendingSetup.addressListMerkleRoot = _addressListMerkleRoot;
            pendingSetup.secretThresholdHash = _secretThresholdHash;
            pendingSetup.setupDelay = _setupDelay;
            emit SetupRequested(block.timestamp + setupDelay);
        }

    }

    /**
     * @notice Activate a pending setup of recovery parameters
     */
    function activate()
        external
    {
        require(pendingSetup.timestamp > 0, "No pending setup");
        require(pendingSetup.timestamp + setupDelay <= block.timestamp, "Waiting delay");
        secretThresholdHash = pendingSetup.secretThresholdHash;
        setupDelay = pendingSetup.setupDelay;
        publicHash = pendingSetup.publicHash;
        addressListMerkleRoot = pendingSetup.addressListMerkleRoot;
        delete pendingSetup;
        emit Activated();
    }

    /**
     * @notice Approves a recovery.
     * This method is important for when the address is an contract and dont implements EIP1271.
     * @param _peerHash seed of `publicHash`
     * @param _secretCall Hash of the recovery call
     * @param _proof Merkle proof of friendsMerkleRoot with msg.sender
     * @param _ensNode if present, the _proof is checked against _ensNode.
     */
    function approve(bytes32 _peerHash, bytes32 _secretCall, bytes32[] calldata _proof, bytes32 _ensNode)
        external
    {
        approveExecution(_secretCall, msg.sender, _ensNode, _peerHash, _proof);
    }

    /**
     * @notice Approve a recovery using an ethereum signed message
     * @param _signer address of _signature processor. if _signer is a contract, must be ERC1271.
     * @param _peerHash seed of `publicHash`
     * @param _secretCall Hash of the recovery call
     * @param _proof Merkle proof of friendsMerkleRoot with msg.sender
     * @param _signature ERC191 signature
     * @param _ensNode if present, the _proof is checked against _ensName.
     */
    function approvePreSigned(
        address _signer,
        bytes32 _peerHash,
        bytes32 _secretCall,
        bytes32[] calldata _proof,
        bytes calldata _signature,
        bytes32 _ensNode
    )
        external
    {
        bytes32 signatureHash = ECDSA.toERC191SignedMessage(address(this), abi.encodePacked(_getChainID(), publicHash, _secretCall));
        require(_signer != address(0), "Invalid signer");
        require(
            (
                isContract(_signer) && Signer(_signer).isValidSignature(abi.encodePacked(_secretCall), _signature) == EIP1271_MAGICVALUE
            ) || ECDSA.recover(signatureHash, _signature) == _signer,
            "Invalid signature");
        approveExecution(_secretCall, _signer, _ensNode, _peerHash, _proof);
    }
s
    /**
     * @notice executes an approved transaction revaling publicHash hash, friends addresses and set new recovery parameters
     * @param _executeHash Seed of `peerHash`
     * @param _dest Address will be called
     * @param _data Data to be sent
     * @param _leafList leafs that approved callHash
     */
    function execute(
        bytes32 _executeHash,
        address _dest,
        bytes calldata _data,
        bytes32[] calldata _leafList
    )
        external
    {
        require(publicHash != bytes32(0), "Recovery not set");
        uint256 _threshold = _leafList.length;
        bytes32 peerHash = keccak256(abi.encodePacked(_executeHash));
        require(publicHash == keccak256(abi.encodePacked(peerHash)), "Invalid secret");
        require(secretThresholdHash == keccak256(abi.encodePacked(_executeHash, _threshold)), "Invalid threshold");
        revealed[publicHash] = true;

        bytes32 callHash = keccak256(
            abi.encodePacked(
                address(this),
                _executeHash,
                _dest,
                _data
            )
        );

        for (uint256 i = 0; i < _threshold; i++) {
            bytes32 leaf = _leafList[i];
            require(leaf != bytes32(0) && signed[callHash][leaf], "Invalid signer");
            delete signed[callHash][leaf];
        }

        delete publicHash;
        delete secretThresholdHash;
        delete addressListMerkleRoot;
        delete pendingSetup;
        bool success;
        (success, ) = _dest.call(_data);
        emit Execution(success);
    }

    /**
     * @param _signer address of _signature processor. if _signer is a contract, must be ERC1271.
     * @param _peerHash seed of `publicHash`
     * @param _secretCall Hash of the recovery call
     * @param _proof Merkle proof of friendsMerkleRoot with msg.sender
     * @param _ensNode if present, the _proof is checked against _ensName.
     */
    function approveExecution(bytes32 _secretCall, address _signer, bytes32 _ensNode, bytes32 _peerHash, bytes32[] memory _proof) internal {
        bytes32 leaf;
        if(_ensNode != bytes32(0)) {
            leaf = keccak256(abi.encodePacked(_peerHash, _ensNode));
            require(
                _signer == ens.owner(_ensNode) ||
                _signer == ResolverInterface(ens.resolver(_ensNode)).addr(_ensNode),
                "Invalid ENS entry"
            );
        } else {
            leaf = keccak256(abi.encodePacked(_peerHash, _signer));
        }
        require(MerkleProof.verify(_proof, addressListMerkleRoot, leaf), "Invalid proof");
        require(!signed[_secretCall][leaf], "Already approved");
        signed[_secretCall][leaf] = true;
        emit Approved(_secretCall, _signer);
    }

    /**
     * @dev Internal function to determine if an address is a contract
     * @param _target The address being queried
     * @return True if `_addr` is a contract
     */
    function isContract(address _target) internal view returns(bool result) {
        assembly {
            result := gt(extcodesize(_target), 0)
        }
    }

    /**
     * @notice get network identification where this contract is running
     */
    function _getChainID() internal pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}