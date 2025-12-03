// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title STBL_Decoder
 * @author STBL Protocol
 * @notice Library for efficiently decoding single ABI elements from calldata
 * @dev Uses assembly for gas-efficient decoding of common types.
 *      All functions expect exactly 32 bytes of ABI-encoded data as input.
 *      This library is optimized for scenarios where you need to decode
 *      individual values without the overhead of abi.decode().
 */
library STBL_Decoder {
    /**
     * @notice Decodes an ABI-encoded uint256 from calldata
     * @dev Loads 32 bytes from calldata starting at the offset
     * @param abiEncodedData The ABI-encoded data to decode (must be exactly 32 bytes)
     * @return value The decoded uint256 value
     */
    function decodeUin256(
        bytes calldata abiEncodedData
    ) internal pure returns (uint256) {
        uint256 value;
        assembly {
            value := calldataload(abiEncodedData.offset)
        }
        return value;
    }

    /**
     * @notice Decodes an ABI-encoded address from calldata
     * @dev Uses bitwise AND to mask the address to 20 bytes (160 bits)
     * @param abiEncodedData The ABI-encoded data to decode (must be exactly 32 bytes)
     * @return value The decoded address value
     */
    function decodeAddr(
        bytes calldata abiEncodedData
    ) internal pure returns (address) {
        address value;
        assembly {
            value := and(
                calldataload(abiEncodedData.offset),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
        return value;
    }

    /**
     * @notice Decodes an ABI-encoded boolean from calldata
     * @dev Extracts the least significant byte (rightmost byte) from the 32-byte word
     * @param abiEncodedData The ABI-encoded data to decode (must be exactly 32 bytes)
     * @return value The decoded boolean value (true if non-zero, false if zero)
     */
    function decodeBool(
        bytes calldata abiEncodedData
    ) internal pure returns (bool) {
        bool value;
        assembly {
            value := byte(31, calldataload(abiEncodedData.offset))
        }
        return value;
    }

    /**
     * @notice Decodes an ABI-encoded bytes32 from calldata
     * @dev Loads the full 32-byte word from calldata
     * @param abiEncodedData The ABI-encoded data to decode (must be exactly 32 bytes)
     * @return value The decoded bytes32 value
     */
    function decodeBytes32(
        bytes calldata abiEncodedData
    ) internal pure returns (bytes32) {
        bytes32 value;
        assembly {
            value := calldataload(abiEncodedData.offset)
        }
        return value;
    }

    /**
     * @notice Decodes an ABI-encoded uint8 from calldata
     * @dev Extracts the least significant byte (rightmost byte) from the 32-byte word
     * @param abiEncodedData The ABI-encoded data to decode (must be exactly 32 bytes)
     * @return value The decoded uint8 value (0-255)
     */
    function decodeUint8(
        bytes calldata abiEncodedData
    ) internal pure returns (uint8) {
        uint8 value;
        assembly {
            value := byte(31, calldataload(abiEncodedData.offset))
        }
        return value;
    }
}