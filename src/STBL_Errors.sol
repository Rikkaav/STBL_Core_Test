// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @notice Thrown when an unauthorized caller attempts to access a restricted function
 */
error STBL_UnauthorizedCaller();

/**
 * @notice Thrown when attempting to set up an asset with invalid parameters
 */
error STBL_InvalidAssetSetup();

/**
 * @notice Thrown when attempting to set up an asset with invalid parameters
 */
error STBL_InvalidAssetName();

/**
 * @notice Thrown when the setup has already been completed
 */
error STBL_SetupAlreadyDone();

/**
 * @notice Thrown when an asset is not active
 */
error STBL_AssetNotActive();

/**
 * @notice Thrown when an asset is active
 */
error STBL_AssetActive();

/**
 * @notice Thrown when an invalid address is provided
 */
error STBL_InvalidAddress();

/**
 * @notice Thrown when an invalid Yield Duration and duration are provided
 */
error STBL_InvalidDuration();

/**
 * @notice Thrown when an invalid treasury address is provided
 */
error STBL_InvalidTreasury();

/**
 * @notice Thrown when an unauthorized issuer attempts an operation
 */
error STBL_UnauthorizedIssuer();

/**
 * @notice Thrown when an invalid cut percentage is provided
 * @param cut The invalid cut percentage that was provided
 */
error STBL_InvalidCutPercentage(uint256 cut);

/**
 * @notice Thrown when a maximum limit has been reached
 */
error STBL_MaxLimitReached();

/**
 * @notice Thrown when YLD functionality is disabled
 * @param id The ID of the YLD that is disabled
 */
error STBL_YLDDisabled(uint256 id);

/**
 * @notice Thrown when an invalid flag value is provided
 * @param flag The invalid flag value that was provided
 */
error STBL_InvalidFlagValue(uint8 flag);

/**
 * @notice Thrown when attempting to disable an already disabled asset
 * @param id The ID of the asset that is already disabled
 */
error STBL_AssetDisabled(uint256 id);

/**
 * @notice Thrown when attempting to enable an already enabled asset
 * @param id The ID of the asset that is already enabled
 */
error STBL_AssetEnabled(uint256 id);

/**
 * @notice Thrown when an invalid fee percentage is provided
 * @param fee The invalid fee percentage that was provided
 */
error STBL_InvalidFeePercentage(uint256 fee);

/**
 * @notice Thrown when attempting to disable an already disabled insurance
 * @param id The ID of the insurance that is already disabled
 */
error STBL_IssuanceAlreadyDisabled(uint256 id);

/**
 * @notice Thrown when attempting to enable an already enabled insurance
 * @param id The ID of the insurance that is already enabled
 */
error STBL_IssuanceAlreadyEnabled(uint256 id);

/**
 * @notice Thrown when the caller is not the owner of the NFT
 * @param tokenId The ID of the token for which ownership is required
 */
error STBL_YLD_NotOwner(uint256 tokenId);

/**
 * @notice Thrown when attempting to enable an already enabled NFT
 * @param tokenId The ID of the token that is already enabled
 */
error STBL_YLD_AlreadyEnabled(uint256 tokenId);

/**
 * @notice Thrown when attempting to disable an already disabled NFT
 * @param tokenId The ID of the token that is already disabled
 */
error STBL_YLD_AlreadyDisabled(uint256 tokenId);

/**
 * @notice Thrown when attempting to transfer a token that has transfers disabled
 * @param tokenId The ID of the token that cannot be transferred
 */
error STBL_YLD_TransferDisabled(uint256 tokenId);

/**
 * @notice Thrown when the sender address is blacklisted
 * @param sender The blacklisted sender address
 */
error STBL_USST_SenderBlacklisted(address sender);

/**
 * @notice Thrown when the recipient address is blacklisted
 * @param recipient The blacklisted recipient address
 */
error STBL_USST_RecipientBlacklisted(address recipient);