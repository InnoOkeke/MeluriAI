// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title ISmartVault
 * @notice Interface for the Smart Vault contract that manages user deposits and vault shares
 * @dev ERC4626-compatible vault interface with additional yield optimization features
 */
interface ISmartVault {
    // Events
    event Deposit(address indexed user, address indexed asset, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 shares, uint256 amount);
    event Allocate(address indexed strategy, uint256 amount);
    event EmergencyExit(address indexed caller, uint256 totalRecovered);
    event Paused(address indexed caller);
    event Unpaused(address indexed caller);

    /**
     * @notice Deposit assets and mint vault shares
     * @param asset The address of the asset to deposit
     * @param amount The amount of assets to deposit
     * @return shares The amount of vault shares minted
     */
    function deposit(address asset, uint256 amount) external returns (uint256 shares);

    /**
     * @notice Withdraw assets by burning vault shares
     * @param shares The amount of vault shares to burn
     * @return amount The amount of assets withdrawn
     */
    function withdraw(uint256 shares) external returns (uint256 amount);

    /**
     * @notice Execute strategy allocation
     * @param strategy The address of the strategy adapter
     * @param amount The amount to allocate to the strategy
     */
    function allocate(address strategy, uint256 amount) external;

    /**
     * @notice Emergency withdrawal from all positions
     * @dev Only callable by owner in emergency situations
     */
    function emergencyExit() external;

    /**
     * @notice Pause contract in case of emergency
     * @dev Only callable by owner
     */
    function pause() external;

    /**
     * @notice Unpause contract
     * @dev Only callable by owner
     */
    function unpause() external;

    /**
     * @notice Get user's vault share balance
     * @param user The address of the user
     * @return The amount of vault shares owned by the user
     */
    function balanceOf(address user) external view returns (uint256);

    /**
     * @notice Calculate total assets under management
     * @return The total amount of assets in the vault
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Get share price (assets per share)
     * @return The current price of one vault share in assets
     */
    function sharePrice() external view returns (uint256);

    /**
     * @notice Get total vault shares minted
     * @return The total supply of vault shares
     */
    function totalShares() external view returns (uint256);

    /**
     * @notice Check if contract is paused
     * @return True if paused, false otherwise
     */
    function paused() external view returns (bool);
}
