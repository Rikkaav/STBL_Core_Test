// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControlUpgradeable.sol";
import "./ERC2771ContextUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";

import "./ISTBL_Register.sol";
import "./ISTBL_USST.sol";
import "./ISTBL_YLD.sol";
import "./ISTBL_Core.sol";

import "./STBL_AssetDefinitionLib.sol";
import "./STBL_Decoder.sol";
import "./STBL_Errors.sol";

/**
 * @title STBL Protocol Core Contract
 * @author STBL Protocol Team
 * @notice Core contract managing the issuance and redemption of USST and YLD tokens
 * @dev Implements iSTBL_Core interface and handles the core functionality of the STBL Protocol.
 *      This contract uses the UUPS proxy pattern for upgradability and supports meta-transactions
 *      through ERC2771Context.
 */
contract STBL_Core is
    Initializable,
    iSTBL_Core,
    AccessControlUpgradeable,
    ERC2771ContextUpgradeable,
    UUPSUpgradeable
{
    using STBL_AssetDefinitionLib for AssetDefinition;
    using STBL_Decoder for bytes;

    /** @notice Role identifier for upgrade functionality */
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    /** @notice Version number of the contract implementation */
    uint256 private _version;

    /**
     * @notice Reference to the STBL Registry contract
     * @dev Stores asset definitions and configuration data
     */
    iSTBL_Register private registry;

    /**
     * @notice Reference to the USST token contract
     * @dev Represents the fungible stablecoin token component of the protocol
     */
    iSTBL_USST private USST;

    /**
     * @notice Reference to the YLD token contract
     * @dev Represents the non-fungible yield-bearing token component of the protocol
     */
    iSTBL_YLD private YLD;

    /**
     * @notice Address of the trusted forwarder for meta-transactions
     * @dev Used to verify and process transactions where the sender is not the original transaction origin.
     *      Set to address(0) to disable meta-transaction support.
     */
    address private trustedForwarderAddress;

    /**
     * @notice Modifier to check if caller is a valid issuer for an asset
     * @param _assetID The asset ID to check issuer permissions for
     * @dev Reverts if caller is not authorized issuer or asset is not active
     * @custom:error STBL_UnauthorizedIssuer Thrown when caller is not authorized as an issuer
     * @custom:error STBL_AssetDisabled Thrown when the asset is not active
     */
    modifier isValidIssuer(uint256 _assetID) {
        AssetDefinition memory AssetData = registry.fetchAssetData(_assetID);
        if (!AssetData.isIssuer(msg.sender)) revert STBL_UnauthorizedIssuer();
        if (!AssetData.isActive()) revert STBL_AssetDisabled(_assetID);
        _;
    }

    /**
     * @dev Storage gap for future upgrades
     * @notice Reserved storage space to allow for layout changes in future versions.
     *         This gap ensures that new storage variables can be added without affecting
     *         the storage layout of existing variables.
     */
    uint256[64] private __gap;

    /**
     * @dev Constructor that disables initializers to prevent implementation contract initialization
     * @notice This constructor is marked as unsafe for upgrades but is required for proper proxy pattern implementation.
     *         The implementation contract itself should never be initialized, only proxy contracts should be.
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() ERC2771ContextUpgradeable(address(0)) {
        _disableInitializers();
    }

    /**
     * @notice Initializes the STBL Core contract
     * @dev Sets up access control roles, connects to registry and token contracts, and configures trusted forwarder.
     *      Can only be called once during deployment. This replaces the constructor for upgradeable contracts.
     * @param _registry Address of the STBL Registry contract
     */
    function initialize(address _registry) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(UPGRADER_ROLE, _msgSender());
        _setRoleAdmin(UPGRADER_ROLE, DEFAULT_ADMIN_ROLE);
        registry = iSTBL_Register(_registry);
        USST = iSTBL_USST(registry.fetchUSSTToken());
        YLD = iSTBL_YLD(registry.fetchYLDToken());

        trustedForwarderAddress = address(0);
    }

    /**
     * @notice Authorizes upgrades to the contract implementation
     * @dev Only callable by addresses with UPGRADER_ROLE. Increments version number on each upgrade.
     * @param newImplementation Address of the new implementation contract (parameter currently unused)
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {
        _version = _version + 1;
        emit ContractUpgraded(newImplementation);
    }

    /**
     * @notice Returns the current implementation version
     * @dev Useful for tracking upgrade versions and ensuring correct implementation is deployed
     * @return Current version number of the implementation
     */
    function version() external view returns (uint256) {
        return _version;
    }

    /**
     * @notice Updates the trusted forwarder address for meta-transactions
     * @dev Only callable by addresses with DEFAULT_ADMIN_ROLE. Setting to address(0) disables meta-transactions.
     * @param _newForwarder Address of the new trusted forwarder
     * @custom:event TrustedForwarderUpdated Emitted when the forwarder is updated
     */
    function updateTrustedForwarder(
        address _newForwarder
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address previousForwarder = trustedForwarderAddress;
        trustedForwarderAddress = _newForwarder;
        emit TrustedForwarderUpdated(previousForwarder, _newForwarder);
    }

    /**
     * @notice Issues USST and YLD tokens for a given asset
     * @dev Only callable by the asset issuer. Checks deposit limits before minting.
     *      Mints fungible USST tokens representing the stable value and a non-fungible YLD token
     *      containing the asset metadata and yield information.
     * @param _to Address to receive the tokens
     * @param _metadata Metadata associated with the YLD NFT, including asset ID and stable value
     * @return nftID The ID of the minted YLD token (NFT)
     * @custom:event putEvent Emitted when tokens are issued
     * @custom:error STBL_MaxLimitReached Thrown when deposit limit for asset has been reached
     * @custom:error STBL_UnauthorizedIssuer Thrown when caller is not authorized as an issuer
     * @custom:error STBL_AssetDisabled Thrown when the asset is not active
     */
    function put(
        address _to,
        YLD_Metadata memory _metadata
    ) external isValidIssuer(_metadata.assetID) returns (uint256) {
        if (
            registry.isDepositLimitReached(
                _metadata.assetID,
                _metadata.stableValueNet
            )
        ) {
            revert STBL_MaxLimitReached();
        }

        registry.incrementAssetDeposits(
            _metadata.assetID,
            _metadata.stableValueNet
        );

        USST.mint(_to, _metadata.stableValueNet);
        uint256 nftID = YLD.mint(_to, _metadata);

        emit putEvent(_metadata.assetID, _to, _metadata, nftID);
        return nftID;
    }

    /**
     * @notice Redeems USST and YLD tokens for a given asset
     * @dev Only callable by the asset issuer. Burns both the fungible USST tokens and the
     *      non-fungible YLD token, then decrements the asset deposit tracking.
     * @param _assetID The ID of the asset being redeemed
     * @param _from Address from which tokens are being redeemed
     * @param _tokenID The ID of the YLD token (NFT) being redeemed
     * @param _value The amount of USST tokens to burn during redemption
     * @custom:event exitEvent Emitted when tokens are redeemed
     * @custom:error STBL_UnauthorizedIssuer Thrown when caller is not authorized as an issuer
     * @custom:error STBL_AssetDisabled Thrown when the asset is not active
     */
    function exit(
        uint256 _assetID,
        address _from,
        uint256 _tokenID,
        uint256 _value
    ) external isValidIssuer(_assetID) {
        USST.burn(_from, _value);
        YLD.burn(_from, _tokenID);

        registry.decrementAssetDeposits(_assetID, _value);

        emit exitEvent(_assetID, _from, _value, _tokenID);
    }

    /**
     * @notice Retrieves the USST token contract address
     * @dev Returns the address of the fungible stablecoin token contract
     * @return The address of the USST token contract
     */
    function fetchUSPToken() external view returns (address) {
        return address(USST);
    }

    /**
     * @notice Retrieves the YLD token contract address
     * @dev Returns the address of the non-fungible yield token contract
     * @return The address of the YLD token contract
     */
    function fetchUSIToken() external view returns (address) {
        return address(YLD);
    }

    /**
     * @notice Retrieves the registry contract address
     * @dev Returns the address of the STBL Registry contract that manages asset definitions
     * @return The address of the registry contract
     */
    function fetchRegistry() external view returns (address) {
        return address(registry);
    }

    /**
     * @notice Returns the address of the trusted forwarder for meta-transactions
     * @dev Implementation of the virtual function from ERC2771Context.
     *      Returns address(0) if meta-transactions are disabled.
     * @return Address of the trusted forwarder
     */
    function trustedForwarder() public view virtual override returns (address) {
        return trustedForwarderAddress;
    }

    /**
     * @notice Override to resolve inheritance conflict between ERC2771Context and Context
     * @dev Returns the actual sender of the transaction, accounting for meta-transactions.
     *      If the transaction was sent through a trusted forwarder, extracts the real sender
     *      from the calldata suffix.
     * @return The actual sender address
     */
    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (address)
    {
        return ERC2771ContextUpgradeable._msgSender();
    }

    /**
     * @notice Override to resolve inheritance conflict between ERC2771Context and Context
     * @dev Returns the actual calldata of the transaction, accounting for meta-transactions.
     *      If the transaction was sent through a trusted forwarder, removes the sender address
     *      from the end of the calldata.
     * @return The actual transaction calldata
     */
    function _msgData()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (bytes calldata)
    {
        return ERC2771ContextUpgradeable._msgData();
    }

    /**
     * @notice Override to resolve inheritance conflict for ERC2771Context
     * @dev Returns the length of the context suffix for meta-transaction support.
     *      The suffix contains the real sender address when using trusted forwarders.
     * @return The length of the context suffix in bytes
     */
    function _contextSuffixLength()
        internal
        view
        override(ContextUpgradeable, ERC2771ContextUpgradeable)
        returns (uint256)
    {
        return ERC2771ContextUpgradeable._contextSuffixLength();
    }
}