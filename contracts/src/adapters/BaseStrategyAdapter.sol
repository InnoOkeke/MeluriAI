// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IStrategyAdapter.sol";

/**
 * @title BaseStrategyAdapter
 * @notice Base implementation for protocol-specific strategy adapters
 * @dev Provides common functionality for all strategy adapters
 */
abstract contract BaseStrategyAdapter is IStrategyAdapter, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable override protocol;
    address public immutable override asset;
    address public vault;
    
    // Tracking
    uint256 public totalDeposited;
    uint256 public totalShares;
    
    // Constants
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant PRECISION = 1e18;

    // Errors
    error OnlyVault();
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance();

    // Modifiers
    modifier onlyVault() {
        if (msg.sender != vault) revert OnlyVault();
        _;
    }

    /**
     * @notice Constructor
     * @param _protocol The address of the underlying DeFi protocol
     * @param _asset The address of the asset this adapter supports
     * @param _vault The address of the vault contract
     */
    constructor(
        address _protocol,
        address _asset,
        address _vault
    ) Ownable(msg.sender) {
        if (_protocol == address(0) || _asset == address(0) || _vault == address(0)) {
            revert ZeroAddress();
        }
        protocol = _protocol;
        asset = _asset;
        vault = _vault;
    }

    /**
     * @notice Deposit funds into protocol
     * @param _asset The address of the asset to deposit
     * @param amount The amount to deposit
     * @return shares The amount of protocol shares received
     */
    function deposit(address _asset, uint256 amount) 
        external 
        virtual 
        override 
        onlyVault 
        nonReentrant 
        returns (uint256 shares) 
    {
        if (_asset != asset) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();

        // Transfer assets from vault
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), amount);

        // Deposit to protocol (implemented by child contracts)
        shares = _depositToProtocol(amount);

        // Update tracking
        totalDeposited += amount;
        totalShares += shares;

        emit Deposit(_asset, amount, shares);
    }

    /**
     * @notice Withdraw funds from protocol
     * @param shares The amount of protocol shares to redeem
     * @return amount The amount of assets withdrawn
     */
    function withdraw(uint256 shares) 
        external 
        virtual 
        override 
        onlyVault 
        nonReentrant 
        returns (uint256 amount) 
    {
        if (shares == 0) revert ZeroAmount();
        if (shares > totalShares) revert InsufficientBalance();

        // Withdraw from protocol (implemented by child contracts)
        amount = _withdrawFromProtocol(shares);

        // Update tracking
        totalShares -= shares;
        if (amount <= totalDeposited) {
            totalDeposited -= amount;
        } else {
            totalDeposited = 0; // Gained yield
        }

        // Transfer assets back to vault
        IERC20(asset).safeTransfer(vault, amount);

        emit Withdraw(shares, amount);
    }

    /**
     * @notice Get current APY (in basis points)
     * @return The current annual percentage yield (e.g., 500 = 5%)
     */
    function getCurrentAPY() external view virtual override returns (uint256) {
        return _getProtocolAPY();
    }

    /**
     * @notice Get total value locked in this strategy
     * @return The total value locked in the underlying protocol
     */
    function getTVL() external view virtual override returns (uint256) {
        return _getProtocolTVL();
    }

    /**
     * @notice Get protocol-specific risk metrics
     * @return utilization The utilization rate (0-10000 basis points)
     * @return liquidationRisk The liquidation risk score (0-10000)
     * @return oracleDeviation The oracle price deviation (0-10000)
     */
    function getRiskMetrics() external view virtual override returns (
        uint256 utilization,
        uint256 liquidationRisk,
        uint256 oracleDeviation
    ) {
        return _getProtocolRiskMetrics();
    }

    /**
     * @notice Emergency exit from protocol
     * @return recovered The amount of assets recovered
     */
    function emergencyWithdraw() 
        external 
        virtual 
        override 
        onlyOwner 
        nonReentrant 
        returns (uint256 recovered) 
    {
        // Emergency withdraw from protocol (implemented by child contracts)
        recovered = _emergencyWithdrawFromProtocol();

        // Reset tracking
        totalShares = 0;
        totalDeposited = 0;

        // Transfer all recovered assets to vault
        if (recovered > 0) {
            IERC20(asset).safeTransfer(vault, recovered);
        }

        emit EmergencyWithdraw(recovered);
    }

    /**
     * @notice Update vault address
     * @param _vault New vault address
     */
    function setVault(address _vault) external onlyOwner {
        if (_vault == address(0)) revert ZeroAddress();
        vault = _vault;
    }

    // Internal functions to be implemented by child contracts

    /**
     * @notice Deposit to the underlying protocol
     * @param amount Amount to deposit
     * @return shares Shares received from protocol
     */
    function _depositToProtocol(uint256 amount) internal virtual returns (uint256 shares);

    /**
     * @notice Withdraw from the underlying protocol
     * @param shares Shares to redeem
     * @return amount Amount of assets withdrawn
     */
    function _withdrawFromProtocol(uint256 shares) internal virtual returns (uint256 amount);

    /**
     * @notice Get protocol APY
     * @return APY in basis points
     */
    function _getProtocolAPY() internal view virtual returns (uint256);

    /**
     * @notice Get protocol TVL
     * @return TVL in asset units
     */
    function _getProtocolTVL() internal view virtual returns (uint256);

    /**
     * @notice Get protocol risk metrics
     * @return utilization Utilization rate
     * @return liquidationRisk Liquidation risk score
     * @return oracleDeviation Oracle deviation
     */
    function _getProtocolRiskMetrics() internal view virtual returns (
        uint256 utilization,
        uint256 liquidationRisk,
        uint256 oracleDeviation
    );

    /**
     * @notice Emergency withdraw from protocol
     * @return recovered Amount recovered
     */
    function _emergencyWithdrawFromProtocol() internal virtual returns (uint256 recovered);

    /**
     * @notice Get current balance in protocol
     * @return Balance in asset units
     */
    function getBalance() public view virtual returns (uint256) {
        if (totalShares == 0) return 0;
        // This should be overridden by child contracts to query actual protocol balance
        return totalDeposited;
    }
}
