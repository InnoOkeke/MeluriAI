// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/IStrategyAdapter.sol";

/**
 * @title SmartVault
 * @notice Core vault contract that holds user funds and manages vault shares
 * @dev ERC4626-compatible vault with access control and emergency mechanisms
 */
contract SmartVault is ISmartVault, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    mapping(address => uint256) private _shares;
    uint256 private _totalShares;
    address[] private _activeStrategies;
    bool private _paused;
    
    // Supported assets
    mapping(address => bool) public supportedAssets;
    address public immutable primaryAsset;
    
    // Strategy allocations
    mapping(address => uint256) public strategyAllocations;
    
    // Constants
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MAX_STRATEGIES = 20;

    // Errors
    error ContractPaused();
    error ContractNotPaused();
    error UnsupportedAsset();
    error InvalidAmount();
    error InsufficientShares();
    error InvalidStrategy();
    error MaxStrategiesReached();
    error ZeroAddress();

    /**
     * @notice Constructor
     * @param _primaryAsset The primary asset address (e.g., USDC)
     */
    constructor(address _primaryAsset) Ownable(msg.sender) {
        if (_primaryAsset == address(0)) revert ZeroAddress();
        primaryAsset = _primaryAsset;
        supportedAssets[_primaryAsset] = true;
    }

    // Modifiers
    modifier whenNotPaused() {
        if (_paused) revert ContractPaused();
        _;
    }

    modifier whenPaused() {
        if (!_paused) revert ContractNotPaused();
        _;
    }

    /**
     * @notice Deposit assets and mint vault shares
     * @param asset The address of the asset to deposit
     * @param amount The amount of assets to deposit
     * @return shares The amount of vault shares minted
     */
    function deposit(address asset, uint256 amount) 
        external 
        override 
        nonReentrant 
        whenNotPaused 
        returns (uint256 shares) 
    {
        if (!supportedAssets[asset]) revert UnsupportedAsset();
        if (amount == 0) revert InvalidAmount();

        // Calculate shares to mint
        shares = _calculateShares(amount);

        // Transfer assets from user
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);

        // Mint shares
        _shares[msg.sender] += shares;
        _totalShares += shares;

        emit Deposit(msg.sender, asset, amount, shares);
    }

    /**
     * @notice Withdraw assets by burning vault shares
     * @param shares The amount of vault shares to burn
     * @return amount The amount of assets withdrawn
     */
    function withdraw(uint256 shares) 
        external 
        override 
        nonReentrant 
        whenNotPaused 
        returns (uint256 amount) 
    {
        if (shares == 0) revert InvalidAmount();
        if (_shares[msg.sender] < shares) revert InsufficientShares();

        // Calculate assets to return
        amount = _calculateAssets(shares);

        // Burn shares
        _shares[msg.sender] -= shares;
        _totalShares -= shares;

        // Withdraw from strategies if needed
        uint256 vaultBalance = IERC20(primaryAsset).balanceOf(address(this));
        if (vaultBalance < amount) {
            _withdrawFromStrategies(amount - vaultBalance);
        }

        // Transfer assets to user
        IERC20(primaryAsset).safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, shares, amount);
    }

    /**
     * @notice Execute strategy allocation
     * @param strategy The address of the strategy adapter
     * @param amount The amount to allocate to the strategy
     */
    function allocate(address strategy, uint256 amount) 
        external 
        override 
        onlyOwner 
        nonReentrant 
        whenNotPaused 
    {
        if (strategy == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();

        // Add to active strategies if new
        if (strategyAllocations[strategy] == 0) {
            if (_activeStrategies.length >= MAX_STRATEGIES) revert MaxStrategiesReached();
            _activeStrategies.push(strategy);
        }

        // Approve and deposit to strategy
        IERC20(primaryAsset).forceApprove(strategy, amount);
        IStrategyAdapter(strategy).deposit(primaryAsset, amount);
        
        strategyAllocations[strategy] += amount;

        emit Allocate(strategy, amount);
    }

    /**
     * @notice Emergency withdrawal from all positions
     * @dev Only callable by owner in emergency situations
     */
    function emergencyExit() external override onlyOwner {
        uint256 totalRecovered = 0;

        // Withdraw from all active strategies
        for (uint256 i = 0; i < _activeStrategies.length; i++) {
            address strategy = _activeStrategies[i];
            if (strategyAllocations[strategy] > 0) {
                uint256 allocation = strategyAllocations[strategy];
                strategyAllocations[strategy] = 0; // Reset before external call
                
                try IStrategyAdapter(strategy).emergencyWithdraw() returns (uint256 recovered) {
                    totalRecovered += recovered;
                } catch {
                    // Continue with other strategies if one fails
                    // Note: allocation is already reset above
                }
            }
        }

        emit EmergencyExit(msg.sender, totalRecovered);
    }

    /**
     * @notice Pause contract in case of emergency
     * @dev Only callable by owner
     */
    function pause() external override onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpause contract
     * @dev Only callable by owner
     */
    function unpause() external override onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Get user's vault share balance
     * @param user The address of the user
     * @return The amount of vault shares owned by the user
     */
    function balanceOf(address user) external view override returns (uint256) {
        return _shares[user];
    }

    /**
     * @notice Calculate total assets under management
     * @return The total amount of assets in the vault
     */
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(primaryAsset).balanceOf(address(this));
        uint256 strategyBalance = 0;

        // Add balances from all strategies
        for (uint256 i = 0; i < _activeStrategies.length; i++) {
            strategyBalance += strategyAllocations[_activeStrategies[i]];
        }

        return vaultBalance + strategyBalance;
    }

    /**
     * @notice Get share price (assets per share)
     * @return The current price of one vault share in assets
     */
    function sharePrice() external view override returns (uint256) {
        if (_totalShares == 0) return PRECISION;
        return (totalAssets() * PRECISION) / _totalShares;
    }

    /**
     * @notice Get total vault shares minted
     * @return The total supply of vault shares
     */
    function totalShares() external view override returns (uint256) {
        return _totalShares;
    }

    /**
     * @notice Check if contract is paused
     * @return True if paused, false otherwise
     */
    function paused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @notice Add supported asset
     * @param asset The address of the asset to support
     */
    function addSupportedAsset(address asset) external onlyOwner {
        if (asset == address(0)) revert ZeroAddress();
        supportedAssets[asset] = true;
    }

    /**
     * @notice Remove supported asset
     * @param asset The address of the asset to remove
     */
    function removeSupportedAsset(address asset) external onlyOwner {
        supportedAssets[asset] = false;
    }

    /**
     * @notice Get active strategies
     * @return Array of active strategy addresses
     */
    function getActiveStrategies() external view returns (address[] memory) {
        return _activeStrategies;
    }

    // Internal functions

    /**
     * @notice Calculate shares to mint for a given asset amount
     * @param assets The amount of assets
     * @return The amount of shares to mint
     */
    function _calculateShares(uint256 assets) internal view returns (uint256) {
        if (_totalShares == 0) {
            return assets;
        }
        return (assets * _totalShares) / totalAssets();
    }

    /**
     * @notice Calculate assets to return for a given share amount
     * @param shares The amount of shares
     * @return The amount of assets to return
     */
    function _calculateAssets(uint256 shares) internal view returns (uint256) {
        return (shares * totalAssets()) / _totalShares;
    }

    /**
     * @notice Withdraw from strategies to cover withdrawal
     * @param amount The amount needed
     */
    function _withdrawFromStrategies(uint256 amount) internal {
        uint256 remaining = amount;

        for (uint256 i = 0; i < _activeStrategies.length && remaining > 0; i++) {
            address strategy = _activeStrategies[i];
            uint256 strategyBalance = strategyAllocations[strategy];

            if (strategyBalance > 0) {
                uint256 toWithdraw = remaining > strategyBalance ? strategyBalance : remaining;
                
                // Calculate shares to withdraw from strategy
                uint256 strategyShares = (toWithdraw * PRECISION) / PRECISION; // Simplified
                
                try IStrategyAdapter(strategy).withdraw(strategyShares) returns (uint256 withdrawn) {
                    strategyAllocations[strategy] -= toWithdraw;
                    remaining -= withdrawn;
                } catch {
                    // Continue with next strategy if withdrawal fails
                }
            }
        }
    }
}
