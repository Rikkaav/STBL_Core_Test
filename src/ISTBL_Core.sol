// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./STBL_Structs.sol";

/**
 * @title STBL Core Interface
 * @notice Interface for core functionality of the STBL Protocol
 * @dev Defines the main entry and exit points for assets in the protocol
 */
interface iSTBL_Core {
    /**
     * @notice Emitted when an asset is deposited into the protocol
     * @param _id The asset identifier
     * @param _to Address receiving the minted token
     * @param _metadata Metadata associated with the YLD token
     * @param _tokenID ID of the minted token
     */
    event putEvent(
        uint256 indexed _id,
        address indexed _to,
        YLD_Metadata _metadata,
        uint256 _tokenID
    );

    /**
     * @notice Emitted when an asset is withdrawn from the protocol
     * @param _id The asset identifier
     * @param _to Address receiving the withdrawn assets
     * @param _value The value of the withdrawn assets
     * @param _tokenID ID of the burned token
     */
    event exitEvent(
        uint256 indexed _id,
        address indexed _to,
        uint256 _value,
        uint256 _tokenID
    );

    /**
     * @notice Event emitted when a trusted forwarder is updated
     * @param previousForwarder The address of the previous trusted forwarder
     * @param newForwarder The address of the new trusted forwarder
     * @dev Indicates a change in the trusted forwarder for meta-transactions
     */
    event TrustedForwarderUpdated(
        address indexed previousForwarder,
        address indexed newForwarder
    );

    /**
     * @notice Emitted when the contract implementation is upgraded
     * @dev Triggered during an upgrade of the contract to a new implementation
     * @param newImplementation Address of the new implementation contract
     */
    event ContractUpgraded(address newImplementation);

    /**
     * @notice Method to update trusted forwarder
     * @param _newForwarder Address of the new trusted forwarder
     * @dev Only callable by admin
     */
    function updateTrustedForwarder(address _newForwarder) external;

    /**
     * @notice Issues X and Y tokens for a given asset
     * @dev Only callable by the asset issuer
     * @param _to Address to receive the tokens
     * @param _metadata Metadata associated with the YLD Token
     * @return nftID The ID of the minted Y token (NFT)
     */
    function put(
        address _to,
        YLD_Metadata memory _metadata
    ) external returns (uint256);

    /**
     * @notice Withdraws assets from the protocol
     * @param _assetID The identifier of the asset being withdrawn
     * @param _from Address that owns the token being burned
     * @param _tokenID ID of the token to burn
     * @param _value The amount of X tokens to burn during redemption
     */
    function exit(
        uint256 _assetID,
        address _from,
        uint256 _tokenID,
        uint256 _value
    ) external;

    /**
     * @notice Retrieves the USP token address
     * @return The address of the USP token contract
     */
    function fetchUSPToken() external view returns (address);

    /**
     * @notice Retrieves the USI token address
     * @return The address of the USI token contract
     */
    function fetchUSIToken() external view returns (address);

    /**
     * @notice Retrieves the registry address
     * @return The address of the registry contract
     */
    function fetchRegistry() external view returns (address);
}