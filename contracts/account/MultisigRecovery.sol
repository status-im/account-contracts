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
 * @notice Select privately other accounts that will allow the execution of actions (ERC-2429 compilant)
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract MultisigRecovery is Controlled, TokenClaimer {
    //Needed for EIP-1271 check
    bytes4 constant internal EIP1271_MAGICVALUE = 0x20c13b0b;
    //Needed for ENS leafs
    ENS ens;
    //flag for used recoveries (user need to define a different publicHash every execute)
    mapping(bytes32 => bool) private revealed;
    //flag to prevent leafs form resigning
    mapping(bytes32 => mapping(bytes32 => bool)) private signed;
    //storage for pending setup
    RecoverySet private pending;
    //storage for active recovery
    RecoverySet public active;

    struct RecoverySet {
        bytes32 publicHash;
        bytes32 secretThresholdHash;
        bytes32 addressListMerkleRoot;
        uint256 setupDelay;
        uint256 timestamp;
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
        active = RecoverySet(_publicHash, _secretThresholdHash, _addressListMerkleRoot, _setupDelay, block.timestamp);
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
        delete pending;
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
        RecoverySet memory newSet = RecoverySet(_publicHash, _secretThresholdHash, _addressListMerkleRoot, _setupDelay, block.timestamp);
        if(active.publicHash == bytes32(0)){
            active = newSet;
            emit Activated();
        } else {
            pending = newSet;
            emit SetupRequested(block.timestamp + active.setupDelay);
        }

    }

    /**
     * @notice Activate a pending setup of recovery parameters
     */
    function activate()
        external
    {
        require(pending.timestamp > 0, "No pending setup");
        require(pending.timestamp + active.setupDelay <= block.timestamp, "Waiting delay");
        active = pending;
        delete pending;
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
        bytes32 signingHash = ECDSA.toERC191SignedMessage(address(this), abi.encodePacked(_getChainID(), active.publicHash, _secretCall));
        require(_signer != address(0), "Invalid signer");
        require(
            (
                isContract(_signer) && Signer(_signer).isValidSignature(abi.encodePacked(signingHash), _signature) == EIP1271_MAGICVALUE
            ) || ECDSA.recover(signingHash, _signature) == _signer,
            "Invalid signature");
        approveExecution(_secretCall, _signer, _ensNode, _peerHash, _proof);
    }

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
        require(active.publicHash != bytes32(0), "Recovery not set");
        uint256 _threshold = _leafList.length;
        bytes32 peerHash = keccak256(abi.encodePacked(_executeHash));
        require(active.publicHash == keccak256(abi.encodePacked(peerHash)), "Invalid secret");
        require(active.secretThresholdHash == keccak256(abi.encodePacked(_executeHash, _threshold)), "Invalid threshold");
        revealed[active.publicHash] = true;

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

        delete active;
        delete pending;
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
        require(MerkleProof.verify(_proof, active.addressListMerkleRoot, leaf), "Invalid proof");
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