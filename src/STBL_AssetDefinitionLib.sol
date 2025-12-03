// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./STBL_Structs.sol";

/**
 * @title STBL_AssetDefinitionLib
 * @notice Library providing utility functions for AssetDefinition struct operations
 * @dev This library contains pure functions for validating, checking status, and calculating fees for asset definitions
 */
library STBL_AssetDefinitionLib {
    /**
     * @notice Checks if an asset definition is valid by verifying all required fields are set
     * @dev Validates that id is non-zero, name is not empty, and all addresses are non-zero
     * @param asset The asset definition to validate
     * @return True if the asset definition is valid, false otherwise
     */
    function isValid(
        AssetDefinition memory asset
    ) internal pure returns (bool) {
        return
            asset.id != 0 &&
            bytes(asset.name).length > 0 &&
            asset.token != address(0) &&
            asset.issuer != address(0) &&
            asset.rewardDistributor != address(0) &&
            asset.vault != address(0);
    }

    /**
     * @notice Checks if an asset is active and available for use
     * @dev An asset is considered active if it's setup and not disabled
     * @param asset The asset definition to check
     * @return True if the asset is active, false otherwise
     */
    function isActive(
        AssetDefinition memory asset
    ) internal pure returns (bool) {
        return asset.status == AssetStatus.ENABLED;
    }

    /**
     * @notice Calculates yield fees for a given amount
     * @dev Calculates yield fee for given amount based on asset configuration using basis points (10000 = 100%)
     * @param asset The asset definition with yield fee configuration
     * @param amount The amount to calculate yield fee for
     * @return netAmount The amount after deducting yield fee
     * @return yieldFee The calculated yield fee amount
     */
    function calculateYieldFee(
        AssetDefinition memory asset,
        uint256 amount
    ) internal pure returns (uint256, uint256) {
        uint256 yieldFee = (amount * asset.yieldFees) / FEES_CONSTANT; // Assuming fee is in basis points
        return (amount - yieldFee, yieldFee);
    }

    /**
     * @notice Checks if an address matches the token address of an asset
     * @dev Compares the provided account address with the asset's token address
     * @param asset The asset definition to check
     * @param account The address to compare
     * @return True if the address matches the token address, false otherwise
     */
    function isToken(
        AssetDefinition memory asset,
        address account
    ) internal pure returns (bool) {
        return account == asset.token;
    }

    /**
     * @notice Checks if an address matches the vault address of an asset
     * @dev Compares the provided account address with the asset's vault address
     * @param asset The asset definition to check
     * @param account The address to compare
     * @return True if the address matches the vault address, false otherwise
     */
    function isVault(
        AssetDefinition memory asset,
        address account
    ) internal pure returns (bool) {
        return account == asset.vault;
    }

    /**
     * @notice Checks if an address matches the issuer address of an asset
     * @dev Compares the provided account address with the asset's issuer address
     * @param asset The asset definition to check
     * @param account The address to compare
     * @return True if the address matches the issuer address, false otherwise
     */
    function isIssuer(
        AssetDefinition memory asset,
        address account
    ) internal pure returns (bool) {
        return account == asset.issuer;
    }

    /**
     * @notice Checks if an address matches the reward distributor address of an asset
     * @dev Compares the provided account address with the asset's reward distributor address
     * @param asset The asset definition to check
     * @param account The address to compare
     * @return True if the address matches the reward distributor address, false otherwise
     */
    function isDistributor(
        AssetDefinition memory asset,
        address account
    ) internal pure returns (bool) {
        return account == asset.rewardDistributor;
    }

    /**
     * @notice Creates a string representation of the asset's contract type
     * @dev Maps numeric contract type to human-readable string representation
     * @param asset The asset definition
     * @return The contract type as a string ("ERC20", "ERC721", "Custom", or "Unknown")
     */
    function getContractTypeString(
        AssetDefinition memory asset
    ) internal pure returns (string memory) {
        if (asset.contractType == 0) return "ERC20";
        if (asset.contractType == 1) return "ERC721";
        if (asset.contractType == 2) return "Custom";
        return "Unknown";
    }
}