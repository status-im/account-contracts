pragma solidity >=0.5.0 <0.6.0;

/**
 * @notice ERC-1271: Standard Signature Validation Method for Contracts
 */
contract Signer {

    //bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 constant internal ERC1271_TRUE = 0x20c13b0b;
    bytes4 constant internal ERC1271_FALSE = 0xffffffff;

    // Allowed signature types.
    enum SignatureType {
        Illegal,         // 0x00, default value
        Invalid,         // 0x01
        EIP712,          // 0x02
        EthSign,         // 0x03
        Caller,          // 0x04
        Wallet,          // 0x05
        Validator,       // 0x06
        PreSigned,       // 0x07
        Trezor,          // 0x08
        NSignatureTypes  // 0x09, number of signature types. Always leave at end.
    }

    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(
        bytes memory _data,
        bytes memory _signature
    )
        public
        view
        returns (bytes4 magicValue);

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param hash Any 32 byte hash.
     * @param signerAddress Address that should have signed the given hash.
     * @param signature Proof that the hash has been signed by signer.
     * @return True if the address recovered from the provided signature matches the input signer address
     */
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);

        
}
