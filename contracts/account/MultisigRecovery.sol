pragma solidity >=0.5.0 <0.6.0;

import "../cryptography/MerkleProof.sol";
import "../cryptography/ECDSA.sol";
import "../token/ERC20Token.sol";
import "../common/TokenClaimer.sol";
import "../common/Controlled.sol";

/**
 * @notice Select privately other accounts that will allow the execution of actions
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract MultisigRecovery is Controlled, TokenClaimer {

    /** # User Secret Data Hash
     * Hash of Semi-private information, such as a "randomly ordered personal information + secret answer", or a hash of user biometric data.
     * The secret should only be revaled together with `execute`, which requires changing the secret at every execution.
     * Contract is configured with a hash of a hash of this personal data hash. `keccak256(keccak256(userDataHash)).
     * If case of using personal information, a form containing several fields of optional data, where, must be written only things that you can always know, but is not completely or usually public.
     * Some of this fields would be used to create tthe user data hash, when recovering user would have to enter the same fields again and automatically will try all combinations with that data until find whats used for the secret.
     * Example of an userDataHash: keccak256("Alice Pleasance Liddell;1852-04-04;Lorina Hanna Liddell;England;Name of important childhood friend?Dodgson")
     * If case of user biometric data, most of sensors should be able to give more then one result for the same repetable reading for the same finger, or just a part of it is used.
     * When revealed, a different secret is needed, then another of that results from the biometric sensor.
     */
    bytes32 public userDataHash;

    /** # Secret Threshold Hash
     * A hash of threshold (number of allowances needed to execute) hashed together with the "User Secret Data Hash"
     * Example: `keccak256(userDataHash, threshold)`
     * Threshold number is revealed in execute, together with the "Secret User Data Hash" and its verified against what is configured in contract.
     * Threshold can be easily figured out if the Secret User Data Hash is known.
     */
    bytes32 public secretThresholdHash;

    /** # Secret Addresses Merkle Root
     * Each address is hashed against a hash of "User Secret Data Hash" (`kecakk256(keccak256(userDataHash), friendAddress)` and a merkle tree is build in top of the dataset.
     * Addresses in this merkle tree would be able to approve a call for anything if they know the Hash of the "User Secret Data Hash".
     */
    bytes32 public friendsMerkleRoot;

    /** # Setup Delay
     * Amount of time delay needed to activate a new recovery setup
     */
    uint256 public setupDelay;

    //flag for used recoveries (user need to define a different userDataHash every execute)
    mapping(bytes32 => bool) private revealed;
    //flag to prevent resigning
    mapping(bytes32 => mapping(address => bool)) private signed;
    //storage for pending delayed setup
    NewRecovery private pendingSetup;

    struct NewRecovery {
        uint256 timestamp;
        bytes32 userDataHash;
        bytes32 secretThresholdHash;
        bytes32 friendsMerkleRoot;
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
     * @param _userDataHash Double hash of User Secret
     * @param _secretThresholdHash Secret Amount of approvals required
     * @param _friendsMerkleRoot Merkle root of new secret friends list
     * @param _setupDelay Delay for changes being active
     **/
    constructor(
        address payable _controller,
        bytes32 _secretThresholdHash,
        bytes32 _userDataHash,
        bytes32 _friendsMerkleRoot,
        uint256 _setupDelay
    )
        public
    {
        controller = _controller;
        secretThresholdHash = _secretThresholdHash;
        userDataHash = _userDataHash;
        friendsMerkleRoot = _friendsMerkleRoot;
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
     * @notice reconfigure recovery parameters
     * @param _userDataHash Double hash of User Secret
     * @param _setupDelay Delay for changes being active
     * @param _secretThresholdHash Secret Amount of approvals required
     * @param _friendsMerkleRoot Merkle root of new secret friends list
     */
    function setup(
        bytes32 _userDataHash,
        uint256 _setupDelay,
        bytes32 _secretThresholdHash,
        bytes32 _friendsMerkleRoot
    )
        external
        onlyController
        notRevealed(_userDataHash)
    {
        if(userDataHash == bytes32(0)){
            secretThresholdHash = _secretThresholdHash;
            userDataHash = _userDataHash;
            friendsMerkleRoot = _friendsMerkleRoot;
            setupDelay = _setupDelay;
        } else {
            pendingSetup.timestamp = block.timestamp;
            pendingSetup.userDataHash = _userDataHash;
            pendingSetup.friendsMerkleRoot = _friendsMerkleRoot;
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
        userDataHash = pendingSetup.userDataHash;
        friendsMerkleRoot = pendingSetup.friendsMerkleRoot;
        delete pendingSetup;
        emit Activated();
    }

    /**
     * @notice Approves a recovery.
     * This method is important for when the address is an contract (such as Identity).
     * @param _secretCall Hash of the recovery call
     * @param _proof Merkle proof of friendsMerkleRoot with msg.sender
     */
    function approve(bytes32 _secretCall, bytes32[] calldata _proof)
        external
    {
        require(MerkleProof.verify(_proof, friendsMerkleRoot, keccak256(abi.encodePacked(userDataHash, msg.sender))), "Invalid proof");
        require(!signed[_secretCall][msg.sender], "Already approved");
        signed[_secretCall][msg.sender] = true;
        emit Approved(_secretCall, msg.sender);
    }

    /**
     * @notice Approve a recovery using an ethereum signed message
     * @param _secretCall Hash of the recovery call
     * @param _proof Merkle proof of friendsMerkleRoot with msg.sender
     * @param _signature ERC191 signature
     */
    function approvePreSigned(bytes32 _secretCall, bytes32[] calldata _proof, bytes calldata _signature)
        external
    {
        bytes32 signatureHash = ECDSA.toERC191SignedMessage(abi.encodePacked(controller, userDataHash, _secretCall));
        address signer = ECDSA.recover(signatureHash, _signature);
        require(MerkleProof.verify(_proof, friendsMerkleRoot, keccak256(abi.encodePacked(userDataHash, signer))), "Invalid proof");
        require(signer != address(0), "Invalid signature");
        require(!signed[_secretCall][signer], "Already approved");
        signed[_secretCall][signer] = true;
        emit Approved(_secretCall, signer);
    }

    /**
     * @notice executes an approved transaction revaling userDataHash hash, friends addresses and set new recovery parameters
     * @param _revealedSecret Single hash of User Secret
     * @param _dest Address will be called
     * @param _data Data to be sent
     * @param _friendList friends addresses that approved
     */
    function execute(
        bytes32 _revealedSecret,
        address _dest,
        bytes calldata _data,
        address[] calldata _friendList
    )
        external
    {
        require(userDataHash != bytes32(0), "Recovery not set");
        uint256 _threshold = _friendList.length;
        bytes32 secretHash = keccak256(abi.encodePacked(_revealedSecret));
        require(userDataHash == keccak256(abi.encodePacked(secretHash, controller)), "Invalid secret");
        require(secretThresholdHash == keccak256(abi.encodePacked(_revealedSecret, _threshold)), "Invalid threshold");
        revealed[userDataHash] = true;

        bytes32 callHash = keccak256(
            abi.encodePacked(
                controller,
                secretHash,
                _dest,
                _data
            )
        );

        for (uint256 i = 0; i < _threshold; i++) {
            address friend = _friendList[i];
            require(friend != address(0) && signed[callHash][friend], "Invalid signer");
            delete signed[callHash][friend];
        }

        delete userDataHash;
        delete secretThresholdHash;
        delete friendsMerkleRoot;
        delete pendingSetup;
        bool success;
        (success, ) = _dest.call(_data);
        emit Execution(success);
    }


}