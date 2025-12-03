// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title STBL Protocol Structs
 * @notice Core data structures used throughout the STBL Protocol
 * @dev This file contains all the essential data structures that define the protocol's architecture
 */

/**
 * @title YLD_Metadata
 * @notice Metadata structure for yield-bearing tokens
 * @dev Stores essential information about yield tokens including values, fees, and operational state
 */
struct YLD_Metadata {
    /** @notice Unique identifier for the asset */
    uint256 assetID;
    /** @notice URI pointing to token metadata following standard metadata format */
    string uri;
    /** @notice Value representing the amount of the asset deposited in native asset units */
    uint256 assetValue;
    /** @notice The total USD value of tokens deposited in the protocol before any adjustments */
    uint256 stableValueGross;
    /** @notice The net USD value of USP tokens minted by the protocol after applying haircuts and fees */
    uint256 stableValueNet;
    /** @notice Block Timestamp when the deposit was made for time-based calculations */
    uint256 depositTimestamp;
    /** @notice Absolute fee amount charged on asset deposits in wei */
    uint256 depositfeeAmount;
    /** @notice Absolute haircut amount taken in USD terms as protocol fee */
    uint256 haircutAmount;
    /** @notice Absolute haircut amount taken in asset terms as protocol fee */
    uint256 haircutAmountAssetValue;
    /** @notice Absolute fee amount charged on asset withdrawals in wei */
    uint256 withdrawfeeAmount;
    /** @notice Absolute fee amount allocated to insurance pool in wei */
    uint256 insurancefeeAmount;
    /** @notice Snapshot of fee structure at the time of deposit for consistency */
    FeeStruct Fees;
    /** @notice Additional data buffer for future extensibility and upgrades */
    bytes additionalBuffer;
    /** @notice Flag indicating if token is disabled and cannot be used */
    bool isDisabled;
}

/**
 * @title AssetStatus
 * @notice Enumeration defining the operational status of assets within the protocol
 * @dev Used to track asset lifecycle and control operational permissions
 * @param INACTIVE Asset is not yet configured or deployed
 * @param INITIALIZED Asset is configured but not yet active for operations
 * @param ENABLED Asset is fully operational and available for deposits/withdrawals
 * @param DISABLED Asset is temporarily disabled but can be reactivated
 * @param EMERGENCY_STOP Asset is in emergency state with all operations halted
 */
enum AssetStatus {
    INACTIVE,
    INITIALIZED,
    ENABLED,
    DISABLED,
    EMERGENCY_STOP
}

/**
 * @title AssetDefinition
 * @notice Structure defining comprehensive properties of an asset in the protocol
 * @dev Contains all configuration parameters, addresses, and operational settings for an asset
 */
struct AssetDefinition {
    /** @notice Unique identifier assigned to the asset within the protocol */
    uint256 id;
    /** @notice Human-readable name of the asset for display purposes */
    string name;
    /** @notice Detailed description of the asset and its characteristics */
    string description;
    /** @notice Type of contract (ERC20 = 0, ERC721 = 1, Custom = 2) */
    uint8 contractType;
    /** @notice Flag indicating if yields are aggregated for this asset across all deposits */
    bool isAggreagated;
    /** @notice Current operational status of the asset (INACTIVE, INITIALIZED, ENABLED, DISABLED) */
    AssetStatus status;
    /** @notice Haircut percentage taken by the protocol in basis points */
    uint256 cut;
    /** @notice Maximum allowable deposit amount for this asset in native units */
    uint256 limit;
    /** @notice Contract address of the underlying token */
    address token;
    /** @notice Address responsible for asset issuance and management */
    address issuer;
    /** @notice Address responsible for distributing rewards to token holders */
    address rewardDistributor;
    /** @notice Address of the oracle providing price feeds and market data */
    address oracle;
    /** @notice Address of the custodian vault holding the actual assets */
    address vault;
    /** @notice Fee percentage charged on deposits in basis points */
    uint256 depositFees;
    /** @notice Fee percentage charged on withdrawals in basis points */
    uint256 withdrawFees;
    /** @notice Fee percentage charged on yield generation in basis points */
    uint256 yieldFees;
    /** @notice Percentage of fees allocated to insurance pool in basis points */
    uint256 insuranceFees;
    /** @notice Time duration in seconds for which asset must remain locked post deposit */
    uint256 duration;
    /** @notice Time interval in seconds between yield distribution events */
    uint256 yieldDuration;
    /** @notice Additional data buffer for future extensibility and protocol upgrades */
    bytes additionalBuffer;
}

/**
 * @title stakingStruct
 * @notice Data structure tracking token staking details for protocol participants
 * @dev Used to manage individual staking positions, rewards, and distribution tracking
 * @custom:security Balance must never underflow, implement proper checks before withdrawals
 * @custom:security RewardIndex must be properly synchronized with global reward calculations
 */
struct stakingStruct {
    /** @notice Current staked balance of the participant in wei */
    uint256 balance;
    /** @notice Index tracking participant's position in yield distribution calculations */
    uint256 rewardIndex;
    /** @notice Total rewards earned but not yet claimed by the participant */
    uint256 earned;
    /** @notice Flag indicating if staking position is currently active and earning rewards */
    bool isActive;
}

/**
 * @title VaultStruct
 * @notice Structure tracking protocol vault metrics and cumulative financial data
 * @dev Comprehensive record of all fees, deposits, and protocol revenue streams
 * @custom:security All fee calculations must prevent overflow and maintain precision
 */
struct VaultStruct {
    /** @notice Total accumulated fees from asset deposits across all assets */
    uint256 depositFees;
    /** @notice Total accumulated fees from asset withdrawals across all assets */
    uint256 withdrawFees;
    /** @notice Total accumulated fees from insurance contributions */
    uint256 insuranceFees;
    /** @notice Total accumulated fees from yield generation activities */
    uint256 yieldFees;
    /** @notice Cumulative total of all haircut fees collected by protocol in USD */
    uint256 cumilativeHairCutValue;
    /** @notice Current USD value of all deposits held in the vault */
    uint256 depositValueUSD;
    /** @notice Total gross value of asset deposits before any deductions */
    uint256 assetDepositGross;
    /** @notice Net value of asset deposits after haircuts and fees are applied */
    uint256 assetDepositNet;
}

/**
 * @title FeeStruct
 * @notice Structure defining fee configuration for various protocol operations
 * @dev Contains granular fee settings and timing parameters for protocol actions
 * @custom:security All fee percentages should be validated to prevent excessive fees
 */
struct FeeStruct {
    /** @notice Fee percentage charged on asset deposits in basis points */
    uint256 depositFee;
    /** @notice Percentage of deposit value taken as protocol haircut in basis points */
    uint256 hairCut;
    /** @notice Fee percentage charged on asset withdrawals in basis points */
    uint256 withdrawFee;
    /** @notice Percentage of total fees allocated to insurance pool in basis points */
    uint256 insuranceFee;
    /** @notice Lock duration in seconds for deposited assets */
    uint256 duration;
    /** @notice Time interval in seconds between yield distribution events */
    uint256 yieldDuration;
}

uint256 constant FEES_CONSTANT = 10 ** 9;