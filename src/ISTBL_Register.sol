// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IAccessControl.sol";
import "./STBL_Structs.sol";

/** @title STBL Register Interface
 * @notice Interface for managing asset registrations and configurations in the STBL protocol
 * @dev Inherits from OpenZeppelin's IAccessControl for role-based access control
 */
interface iSTBL_Register is IAccessControl {
    /** @notice Emitted when the Core contract address is updated
     * @param _Core The new Core contract address
     */
    event CoreUpdateEvent(address _Core);

    /** @notice Emitted when the treasury address is updated
     * @param _treasury The new treasury address
     */
    event TreasuryUpdateEvent(address _treasury);

    /** @notice Emitted when a new asset is added to the registry
     * @param _id The ID of the added asset
     * @param _Assetdata The asset definition data
     */
    event AddAssetEvent(uint256 indexed _id, AssetDefinition _Assetdata);

    /** @notice Emitted when an asset is setup with contract addresses and configuration
     * @param _id The ID of the setup asset
     * @param _Assetdata The complete asset definition containing all configuration parameters including
     * contract addresses, fee structures, limits, and durations
     */
    event SetupAssetEvent(uint256 indexed _id, AssetDefinition _Assetdata);

    /** @notice Emitted when an asset's cut percentage is updated
     * @param _id The ID of the asset
     * @param _cut The new cut percentage value
     */
    event CutUpdateEvent(uint256 indexed _id, uint256 _cut);

    /** @notice Emitted when an asset's limit is updated
     * @param _id The ID of the asset
     * @param _limit The new limit value
     */
    event LimitUpdateEvent(uint256 indexed _id, uint256 _limit);

    /** @notice Emitted when an asset's fees are updated
     * @param _id The ID of the asset
     * @param _depositFee The new deposit fee value in basis points
     * @param _withdrawFee The new withdrawal fee value in basis points
     * @param _insuranceFee The new insurance fee value in basis points
     * @param _yieldFees The new yield fee value in basis points
     */
    event FeeUpdateEvent(
        uint256 indexed _id,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _insuranceFee,
        uint256 _yieldFees
    );

    /** @notice Emitted when an asset's duration parameters are updated
     * @param _id The ID of the asset
     * @param _duration The new main duration value in seconds
     * @param _yieldDuration The new yield duration value in seconds
     */
    event durationUpdateEvent(
        uint256 indexed _id,
        uint256 _duration,
        uint256 _yieldDuration
    );

    /** @notice Emitted when an additional buffer for an asset is updated
     * @param _id The ID of the asset
     * @param _data Additional buffer data stored as bytes
     */
    event AdditionalBufferUpdateEvent(uint256 indexed _id, bytes _data);

    /** @notice Emitted when an asset's oracle address is updated
     * @param _id The ID of the asset
     * @param _oracle The new oracle address for price feeds
     */
    event OracleUpdateEvent(uint256 indexed _id, address _oracle);

    /** @notice Emitted when an asset's state is updated
     * @param _id The ID of the asset
     * @param _state The new state of the asset (enum AssetStatus)
     */
    event AssetStateUpdateEvent(uint256 indexed _id, AssetStatus _state);

    /** @notice Event emitted when asset deposits are incremented
     * @param assetId The ID of the asset
     * @param amount The amount incremented
     */
    event AssetDepositIncrementEvent(uint256 indexed assetId, uint256 amount);

    /** @notice Event emitted when asset deposits are decremented
     * @param assetId The ID of the asset
     * @param amount The amount decremented
     */
    event AssetDepositDecrementEvent(uint256 indexed assetId, uint256 amount);

    /** @notice Event emitted when a trusted forwarder is updated
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

    /** @notice Sets the Core contract address
     * @dev Only callable by admin role
     * @param _Core The new Core contract address
     */
    function setCore(address _Core) external;

    /** @notice Sets the treasury address
     * @dev Only callable by admin role
     * @param _treasury The new treasury address
     */
    function setTreasury(address _treasury) external;

    /** @notice Adds a new asset to the registry
     * @dev Only callable by admin role
     * @param _name The name of the asset
     * @param _desc Description of the asset
     * @param _type Asset type identifier
     * @param _aggType Aggregation type flag
     * @return The asset ID of the newly added asset
     */
    function addAsset(
        string memory _name,
        string memory _desc,
        uint8 _type,
        bool _aggType
    ) external returns (uint256);

    /** @notice Sets up an asset with contract addresses and configuration parameters
     * @dev Only callable by admin role and allows setting all key parameters for an asset
     * @param _id The unique identifier of the asset to configure
     * @param _contractAddr The primary token contract address for the asset
     * @param _issuanceAddr Address responsible for issuing the asset tokens
     * @param _distAddr Address of the reward distribution contract
     * @param _vaultAddr Address of the asset's vault contract
     * @param _oracle Address of the price oracle for the asset
     * @param _cut Percentage cut applied to the asset's transactions
     * @param _limit Maximum value/cap for the asset
     * @param _depositFee Fee charged for depositing the asset (in basis points)
     * @param _withdrawFee Fee charged for withdrawing the asset (in basis points)
     * @param _yieldFee Fee applied to yield generation (in basis points)
     * @param _insuranceFee Insurance fee applied (in basis points)
     * @param _duration Main duration parameter for protocol operations (in seconds)
     * @param _yieldDuration Duration specifically for yield calculations (in seconds)
     * @param _additionalBytes Additional configuration data stored as bytes
     * @custom:error Pi_SetupAlreadyDone if the asset has already been set up
     * @custom:error Pi_InvalidAssetSetup if the asset ID is invalid
     * @custom:error Pi_InvalidFeePercentage if any fee exceeds 100% (10000 basis points)
     * @custom:event SetupAssetEvent emitted when the asset is successfully set up
     */
    function setupAsset(
        uint256 _id,
        address _contractAddr,
        address _issuanceAddr,
        address _distAddr,
        address _vaultAddr,
        address _oracle,
        uint256 _cut,
        uint256 _limit,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _yieldFee,
        uint256 _insuranceFee,
        uint256 _duration,
        uint256 _yieldDuration,
        bytes memory _additionalBytes
    ) external;

    /** @notice Sets the cut percentage for an asset
     * @dev Only callable by admin role
     * @param _id The ID of the asset
     * @param _cut The new cut percentage
     */
    function setCut(uint256 _id, uint256 _cut) external;

    /** @notice Sets the limit for an asset
     * @dev Only callable by admin role
     * @param _id The ID of the asset
     * @param _limit The new limit value
     */
    function setLimit(uint256 _id, uint256 _limit) external;

    /** @notice Sets the fee structure for an asset
     * @dev Only callable by admin role, all fees are in basis points (10000 = 100%)
     * @param _id The ID of the asset
     * @param _depositFee The new deposit fee percentage in basis points
     * @param _withdrawFee The new withdrawal fee percentage in basis points
     * @param _yieldFee The new yield fee percentage in basis points
     * @param _insuranceFee The new insurance fee percentage in basis points
     * @custom:error Pi_InvalidFeePercentage if any fee exceeds 100% (10000 basis points)
     */
    function setFees(
        uint256 _id,
        uint256 _depositFee,
        uint256 _withdrawFee,
        uint256 _yieldFee,
        uint256 _insuranceFee
    ) external;

    /** @notice Sets the duration parameters for a specific asset
     * @dev Only callable by admin role
     * @param _id The ID of the asset to update durations for
     * @param _duration The main duration parameter for the asset's operations, measured in seconds
     * @param _yieldduration The duration parameter specifically for yield calculations, measured in seconds
     */
    function setDurations(
        uint256 _id,
        uint256 _duration,
        uint256 _yieldduration
    ) external;

    /** @notice Sets additional buffer data for an asset
     * @dev Only callable by admin role
     * @param _id The ID of the asset
     * @param _data Additional buffer data to store as bytes
     */
    function setAdditionalBuffer(uint256 _id, bytes memory _data) external;

    /** @notice Sets the oracle address for an asset
     * @dev Only callable by admin role
     * @param _id The ID of the asset
     * @param _oracle The new oracle address
     */
    function setOracle(uint256 _id, address _oracle) external;

    /** @notice Disables an asset in the registry
     * @dev Only callable by admin role
     * @param _id Asset ID to disable
     */
    function disableAsset(uint256 _id) external;

    /** @notice Enables a previously disabled asset
     * @dev Only callable by admin role
     * @param _id Asset ID to enable
     */
    function enableAsset(uint256 _id) external;

    /** @notice Increments the total deposits for a specific asset
     * @dev Only callable by admin or authorized contracts
     * @param _id The ID of the asset to increment deposits for
     * @param _amount The amount to increment deposits by
     */
    function incrementAssetDeposits(uint256 _id, uint256 _amount) external;

    /** @notice Decrements the total deposits for a specific asset
     * @dev Only callable by Core contract
     * @param _id The ID of the asset to decrement deposits for
     * @param _amount The amount to decrement deposits by
     */
    function decrementAssetDeposits(uint256 _id, uint256 _amount) external;

    /** @notice Updates the trusted forwarder address for meta-transactions
     * @dev Only callable by admin role, updates the address used for ERC2771 meta-transactions
     * @param _newForwarder The new trusted forwarder address to be used
     * @custom:event Emits TrustedForwarderUpdated with previous and new forwarder addresses
     */
    function updateTrustedForwarder(address _newForwarder) external;

    /** @notice Retrieves the complete data for a specific asset
     * @param _id Asset ID to query
     * @return The AssetDefinition struct containing all asset data
     */
    function fetchAssetData(
        uint256 _id
    ) external view returns (AssetDefinition memory);

    /** @notice Retrieves specific element of asset data based on flag
     * @dev Flag values: 0=name, 1=description, 2=contractType, 3=isAggregated, 4=isDisabled,
     *                   5=isSetup, 6=cut, 7=limit, 8=token, 9=issuer, 10=rewardDistributor, 11=vault
     * @param _id The ID of the asset to fetch from
     * @param _flag The flag indicating which element to fetch
     * @return The requested element value encoded as bytes
     */
    function fetchAssetElement(
        uint256 _id,
        uint8 _flag
    ) external view returns (bytes memory);

    /** @notice Fetches the USST-Pegged token contract address used in the system
     * @dev This represents the main stablecoin contract address
     * @return The contract address of the USD-Pegged token
     */
    function fetchUSSTToken() external view returns (address);

    /** @notice Fetches the USD-Interest token contract address used in the system
     * @dev This represents the interest-bearing stablecoin contract address
     * @return The contract address of the USD-Interest token
     */
    function fetchYLDToken() external view returns (address);

    /** @notice Retrieves the Core contract address
     * @return The address of the Core contract
     */
    function fetchCore() external view returns (address);

    /** @notice Retrieves the treasury address
     * @return The address of the treasury contract
     */
    function fetchTreasury() external view returns (address);

    /** @notice Retrieves the current counter value
     * @dev The counter tracks the total number of assets added to the registry
     * @return The current counter value
     */
    function fetchCounter() external view returns (uint256);

    /** @notice Retrieves the total deposit amount for a specific asset
     * @param _assetID The ID of the asset to query
     * @return The total amount deposited for the specified asset
     */
    function fetchDeposits(uint256 _assetID) external view returns (uint256);

    /** @notice Checks if adding a deposit amount would exceed the asset's deposit limit
     * @param _assetID The ID of the asset to check deposit limit for
     * @param _amount The amount proposed to be deposited
     * @return True if the deposit limit would be exceeded, false otherwise
     */
    function isDepositLimitReached(
        uint256 _assetID,
        uint256 _amount
    ) external view returns (bool);

    /** @notice Returns the address of the trusted forwarder for meta-transactions
     * @dev Used by ERC2771Context to validate meta-transaction relayers
     * @return The address of the current trusted forwarder
     */
    function trustedForwarder() external view returns (address);
}