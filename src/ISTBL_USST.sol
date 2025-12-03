// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./IERC20Permit.sol";

/**
 * @title STBL USST Token Interface
 * @notice Interface for the STBL USST stablecoin token
 * @dev Extends ERC20 and AccessControl functionality
 */
interface iSTBL_USST is IERC20, IERC20Permit, IAccessControl {
    /** @notice Event emitted when an address is blacklisted */
    event Blacklisted(address indexed account);

    /** @notice Event emitted when an address is unblacklisted */
    event Unblacklisted(address indexed account);

    /** @notice Event emitted when tokens are minted via protocol */
    event MintEvent(address indexed to, uint256 amount);

    /** @notice Event emitted when tokens are burned via protocol */
    event BurnEvent(address indexed from, uint256 amount);

    /** @notice Event emitted when tokens are minted via bridge */
    event BridgeMint(address indexed to, uint256 amount, bytes _data);

    /** @notice Event emitted when tokens are burned via bridge */
    event BridgeBurn(address indexed from, uint256 amount, bytes _data);

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

    /** @notice Checks if an address is blacklisted
     * @param _account Address to check
     * @return Whether the address is blacklisted
     */
    function isBlacklisted(address _account) external view returns (bool);

    /** @notice Adds an address to the blacklist
     * @param _account Address to be blacklisted
     * @dev Only callable by addresses with BLACKLISTER_ROLE
     */
    function enableBlacklist(address _account) external;

    /** @notice Removes an address from the blacklist
     * @param _account Address to be unblacklisted
     * @dev Only callable by addresses with BLACKLISTER_ROLE
     */
    function disableBlacklist(address _account) external;

    /**
     * @notice Mints new tokens to a specified address
     * @param _to Address to receive the minted tokens
     * @param _amt Amount of tokens to mint
     */
    function mint(address _to, uint256 _amt) external;

    /**
     * @notice Burns tokens from a specified address
     * @param _from Address from which to burn tokens
     * @param _amt Amount of tokens to burn
     */
    function burn(address _from, uint256 _amt) external;

    /**
     * @notice Mints new tokens for bridge operations
     * @dev Only callable by addresses with BRIDGE_ROLE when the contract is not paused.
     *      Used for cross-chain bridge operations. Emits a BridgeMint event with additional data.
     * @param _to The address that will receive the minted tokens
     * @param _amt The amount of tokens to mint
     * @param _data Additional data related to the bridge operation (e.g., source chain info)
     * @custom:event Emits BridgeMint event
     */
    function bridgeMint(address _to, uint256 _amt, bytes memory _data) external;

    /**
     * @notice Burns tokens for bridge operations
     * @dev Only callable by addresses with BRIDGE_ROLE when the contract is not paused.
     *      Used for cross-chain bridge operations. Emits a BridgeBurn event with additional data.
     * @param _from The address from which tokens will be burned
     * @param _amt The amount of tokens to burn
     * @param _data Additional data related to the bridge operation (e.g., destination chain info)
     * @custom:event Emits BridgeBurn event
     */
    function bridgeBurn(
        address _from,
        uint256 _amt,
        bytes memory _data
    ) external;

    /**
     * @notice Pauses all token transfers
     */
    function pause() external;

    /**
     * @notice Unpauses token transfers
     */
    function unpause() external;
}