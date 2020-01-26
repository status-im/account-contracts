pragma solidity >=0.5.0 <0.7.0;

interface ERC2429 {
    event SetupRequested(address indexed who, uint256 activation);
    event Activated(address indexed who);
    event Approved(bytes32 indexed approveHash, bytes32 leaf);
    event Execution(address indexed who, bool success);

    struct RecoverySet {
        bytes32 publicHash;
        uint256 setupDelay;
        uint256 timestamp;
    }

    /**
     * @notice Cancels a pending setup of `msg.sender` to change the recovery set parameters
     */
    function cancelSetup()
        external;

    /**
     * @notice Configure recovery set parameters of `msg.sender`. `emit Activated(msg.sender)` if there was no previous setup, or `emit SetupRequested(msg.sender, now()+setupDelay)` when reconfiguring.
     * @param _publicHash Hash of `peerHash`.
     * @param _setupDelay Delay for changes being activ.
     */
    function setup(
        bytes32 _publicHash,
        uint256 _setupDelay
    )
        external;

    /**
     * @notice Activate a pending setup of `_who` recovery set parameters.
     * @param _who address whih ready setupDelay.
     */
    function activate(address _who)
        external;

    /**
     * @notice Approves a recovery. This method is important for when the address is an contract and dont implements EIP1271.
     * @param _approveHash Hash of the recovery call
     * @param _ensNode if present, the _proof is checked against _ensNode.
     */
    function approve(
        bytes32 _approveHash,
        bytes32 _ensNode
    )
        external;
    /**
     * @notice Approve a recovery execution using an ethereum signed message.
     * @param _signer address of _signature processor. if _signer is a contract, must be ERC1271.
     * @param _approveHash Hash of the recovery call
     * @param _ensNode if present, the _proof is checked against _ensName.
     * @param _signature ERC191 signature
     */
    function approvePreSigned(
        address _signer,
        bytes32 _approveHash,
        bytes32 _ensNode,
        bytes calldata _signature
    )
        external;

    /**
     * @notice executes an approved transaction revaling publicHash hash, friends addresses and set new recovery parameters
     * @param _executeHash Seed of `peerHash`
     * @param _merkleRoot Revealed merkle root
     * @param _calldest Address will be called
     * @param _calldata Data to be sent
     * @param _leafData Pre approved leafhashes and it's weights as siblings ordered by descending weight
     * @param _proofs parents proofs
     * @param _proofFlags indexes that select the hashing pairs from calldata `_leafHashes` and `_proofs` and from memory `hashes`
     */
    function execute(
        bytes32 _executeHash,
        bytes32 _merkleRoot,
        address _calldest,
        bytes calldata _calldata,
        bytes32[] calldata _leafData,
        bytes32[] calldata _proofs,
        bool[] calldata _proofFlags
    )
        external;
}