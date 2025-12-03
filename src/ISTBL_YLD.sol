// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IAccessControl.sol";
import "./IERC721.sol";

import "./STBL_Structs.sol";

/**
 * @title iSTBL_YLD Interface
 * @notice Interface for the STBL YLD contract that manages yield-generating NFT tokens with lifecycle controls
 * @dev Extends IAccessControl and IERC721 to provide role-based permissions and standard NFT functionality
 * @author STBL Protocol Team
 */
interface iSTBL_YLD is IAccessControl, IERC721 {
    /**
     * @notice Emitted when the trusted forwarder address is updated
     * @param previousForwarder Address of the previous trusted forwarder
     * @param newForwarder Address of the new trusted forwarder
     * @dev Used for meta-transaction support and gasless transactions
     */
    event TrustedForwarderUpdated(
        address indexed previousForwarder,
        address indexed newForwarder
    );

    /**
     * @notice Emitted when an NFT is disabled
     * @param _id Token ID of the disabled NFT
     * @dev Disabled NFTs cannot be transferred or used until re-enabled
     */
    event NFTDisabled(uint256 indexed _id);

    /**
     * @notice Emitted when a disabled NFT is re-enabled
     * @param _id Token ID of the enabled NFT
     * @dev Re-enabled NFTs restore full functionality including transfers
     */
    event NFTEnabled(uint256 indexed _id);

    /**
     * @notice Emitted when a new NFT is minted
     * @param _addr Recipient address of the minted NFT
     * @param _id Token ID of the newly minted NFT
     * @param _nftMetadata Complete metadata structure for the NFT
     * @dev Contains all relevant data for the newly created yield-bearing token
     */
    event MintEvent(
        address indexed _addr,
        uint256 indexed _id,
        YLD_Metadata _nftMetadata
    );

    /**
     * @notice Emitted when an NFT is permanently burned
     * @param _from Address that previously owned the burned NFT
     * @param _id Token ID of the burned NFT
     * @dev Burning permanently removes the token from circulation
     */
    event BurnEvent(address indexed _from, uint256 indexed _id);

    /**
     * @notice Emitted when the contract implementation is upgraded
     * @dev Triggered during an upgrade of the contract to a new implementation
     * @param newImplementation Address of the new implementation contract
     */
    event ContractUpgraded(address newImplementation);

    /**
     * @notice Updates the base URI for token metadata
     * @dev Changes the base URI used for constructing token metadata URLs
     * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE
     * @param _uri The new base URI to set for token metadata
     */
    function setBaseURI(string memory _uri) external;

    /**
     * @notice Pauses all contract functionality
     * @dev Only callable by PAUSER_ROLE. Prevents transfers, minting, and burning
     * @custom:security Emergency function to halt all operations
     */
    function pause() external;

    /**
     * @notice Resumes all contract functionality
     * @dev Only callable by PAUSER_ROLE. Restores normal operations after pause
     * @custom:security Should only be called after emergency conditions are resolved
     */
    function unpause() external;

    /**
     * @notice Retrieves complete metadata for a specific NFT
     * @param _tokenID Token ID to query metadata for
     * @return YLD_Metadata struct containing all token data
     * @dev Reverts with NonexistentToken if tokenID does not exist
     * @custom:view-function Pure read operation with no state changes
     */
    function getNFTData(
        uint256 _tokenID
    ) external view returns (YLD_Metadata memory);

    /**
     * @notice Creates a new NFT with specified metadata
     * @param _to Recipient address for the new NFT
     * @param _metadata Complete metadata structure for the NFT
     * @return Token ID of the newly minted NFT
     * @dev Only callable by MINTER_ROLE. Increments total supply
     * @custom:security Validates recipient address and metadata integrity
     */
    function mint(
        address _to,
        YLD_Metadata memory _metadata
    ) external returns (uint256);

    /**
     * @notice Permanently destroys an existing NFT
     * @param _from Current owner address of the NFT
     * @param _id Token ID to burn
     * @dev Only callable by BURNER_ROLE. Decrements total supply
     * @custom:security Validates ownership and token existence before burning
     */
    function burn(address _from, uint256 _id) external;

    /**
     * @notice Disables an NFT, preventing transfers and usage
     * @param _id Token ID to disable
     * @dev Only callable by ADMIN_ROLE. NFT remains owned but non-transferable
     * @custom:security Used for compliance or security concerns
     */
    function disableNFT(uint256 _id) external;

    /**
     * @notice Re-enables a previously disabled NFT
     * @param _id Token ID to enable
     * @dev Only callable by ADMIN_ROLE. Restores full NFT functionality
     * @custom:security Allows restoration of NFT after issues are resolved
     */
    function enableNFT(uint256 _id) external;
}