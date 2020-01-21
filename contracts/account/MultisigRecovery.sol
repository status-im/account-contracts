pragma solidity >=0.5.0 <0.7.0;

import "../cryptography/MerkleMultiProof.sol";
import "../cryptography/ECDSA.sol";
import "../account/Signer.sol";
import "../ens/ENS.sol";
import "../ens/ResolverInterface.sol";

/**
 * @notice Select privately other accounts that will allow the execution of actions (ERC-2429 compilant)
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 *         Vitalik Buterin (Ethereum Foundation)
 */
contract MultisigRecovery {
    //Needed for EIP-1271 check
    bytes4 constant internal EIP1271_MAGICVALUE = 0x20c13b0b;
    //threshold constant
    uint256 public constant THRESHOLD = 100 * 10^18;
    //Needed for ENS leafs
    ENS public ens;
    //flag for used recoveries (user need to define a different publicHash every execute)
    mapping(bytes32 => bool) public used;
    //just used offchain
    mapping(address => uint256) public nonce;
    //flag approvals
    mapping(bytes32 => mapping(bytes32=>bool)) public approved;
    //storage for pending setup
    mapping(address => RecoverySet) public pending;
    //storage for active recovery
    mapping(address => RecoverySet) public active;

    struct RecoverySet {
        bytes32 publicHash;
        uint256 setupDelay;
        uint256 timestamp;
    }

    event SetupRequested(address indexed who, uint256 activation);
    event Activated(address indexed who);
    event Approved(bytes32 indexed approveHash, bytes32 leaf);
    event Execution(address indexed who, bool success);

    /**
     * @param _ens Address of ENS Registry
     **/
    constructor(
        ENS _ens
    )
        public
    {
        ens = _ens;
    }
    /**
     * @notice Cancels a pending setup to change the recovery parameters
     */
    function cancelSetup()
        external
    {
        delete pending[msg.sender];
        emit SetupRequested(msg.sender, 0);
    }

    /**
     * @notice Configure recovery parameters of `msg.sender`. `emit Activated(msg.sender)` if there was no previous setup, or `emit SetupRequested(msg.sender, now()+setupDelay)` when reconfiguring.
     * @param _publicHash Double hash of executeHash
     * @param _setupDelay Delay for changes being active
     */
    function setup(
        bytes32 _publicHash,
        uint256 _setupDelay
    )
        external
    {
        require(!used[_publicHash], "_publicHash already used");
        used[_publicHash] = true;
        address who = msg.sender;
        RecoverySet memory newSet = RecoverySet(_publicHash, _setupDelay, block.timestamp);
        if(active[who].publicHash == bytes32(0)){
            active[who] = newSet;
            emit Activated(who);
        } else {
            pending[who] = newSet;
            emit SetupRequested(who, block.timestamp + active[who].setupDelay);
        }

    }

    /**
     * @notice Activate a pending setup of recovery parameters
     * @param _who address whih ready setupDelay.
     */
    function activate(address _who)
        external
    {
        RecoverySet storage pendingUser = pending[_who];
        require(pendingUser.timestamp > 0, "No pending setup");
        require(pendingUser.timestamp + active[_who].setupDelay <= block.timestamp, "Waiting delay");
        active[_who] = pendingUser;
        delete pending[_who];
        emit Activated(_who);
    }

    /**
     * @notice Approves a recovery. This method is important for when the address is an contract and dont implements EIP1271.
     * @param _approveHash Hash of the recovery call
     * @param _ensNode if present, the _proof is checked against _ensNode.
     */
    function approve(
        bytes32 _approveHash,
        bytes32 _ensNode
    )
        external
    {
        approveExecution(msg.sender, _approveHash, _ensNode);
    }

    /**
     * @notice Approve a recovery using an ethereum signed message
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
        external
    {
        bytes32 signingHash = ECDSA.toERC191SignedMessage(address(this), abi.encodePacked(_getChainID(), _approveHash, _ensNode));
        require(_signer != address(0), "Invalid signer");
        require(
            (
                isContract(_signer) && Signer(_signer).isValidSignature(abi.encodePacked(signingHash), _signature) == EIP1271_MAGICVALUE
            ) || ECDSA.recover(signingHash, _signature) == _signer,
            "Invalid signature");
        approveExecution(_signer,  _approveHash, _ensNode);
    }

    /**
     * @notice executes an approved transaction revaling publicHash hash, friends addresses and set new recovery parameters
     * @param _executeHash Seed of `peerHash`
     * @param _merkleRoot Revealed merkle root
     * @param _calldest Address will be called
     * @param _calldata Data to be sent
     * @param _leafHashes Pre approved leafhashes and it's weights as siblings ordered by descending weight
     * @param _proofs parents proofs
     * @param _indexes indexes that select the hashing pairs from calldata `_leafHashes` and `_proofs` and from memory `hashes`
     */
    function execute(
        bytes32 _executeHash,
        bytes32 _merkleRoot,
        address _calldest,
        bytes calldata _calldata,
        bytes32[] calldata _leafHashes,
        bytes32[] calldata _proofs,
        uint256[] calldata _indexes
    )
        external
    {
        bytes32 publicHash = active[_calldest].publicHash;
        require(publicHash != bytes32(0), "Recovery not set");
        require(
            publicHash == keccak256(
                abi.encodePacked(_executeHash, _merkleRoot)
            ), "merkleRoot or executeHash is not valid"
        );
        uint256 th = THRESHOLD;
        uint256 weight = 0;
        uint256 i = 0;
        while(weight < th){
            bytes32 leafHash = _leafHashes[i];
            uint256 leafWeight = uint256(_leafHashes[i+1]);
            bytes32 approveHash = keccak256(
                abi.encodePacked(
                    leafHash,
                    _calldest,
                    _calldata
            ));
            require(approved[leafHash][approveHash], "Hash not approved");
            weight += leafWeight;
            delete approved[leafHash][approveHash];
            i += 2;
        }
        require(MerkleMultiProof.verifyMerkleMultiproof(_merkleRoot, _leafHashes, _proofs, _indexes), "Invalid leafHashes");
        nonce[_calldest]++;
        delete active[_calldest];
        delete pending[_calldest];
        bool success;
        (success, ) = _calldest.call(_calldata);
        emit Execution(_calldest, success);
    }

    /**
     * @param _signer address of approval signer
     * @param _approveHash Hash of the recovery call
     * @param _ensNode if present, the _proof is checked against _ensNode.
     */
    function approveExecution(
        address _signer,
        bytes32 _approveHash,
        bytes32 _ensNode
    )
        internal
    {
        bool isENS = _ensNode != bytes32(0);
        require(
            !isENS || (
                _signer == ResolverInterface(ens.resolver(_ensNode)).addr(_ensNode)
            ),
            "Invalid ENS entry"
        );
        bytes32 leaf = keccak256(abi.encodePacked(isENS, isENS ? _ensNode : bytes32(uint256(_signer))));
        approved[leaf][_approveHash] = true;
        emit Approved(_approveHash, leaf);
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