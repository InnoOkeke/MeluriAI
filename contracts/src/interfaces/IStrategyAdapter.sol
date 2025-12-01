// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title IStrategyAdapter
 * @notice Interface for protocol-specific strategy adapters
 * @dev Each DeFi protocol integration implements this standard interface
 */
interface IStrategyAdapter {
    // Events
    event Deposit(address indexed asset, uint256 amount, uint256 shares);
    event Withdraw(uint256 shares, uint256 amount);
    event EmergencyWithdraw(uint256 recovered);

    /**
     * @notice Deposit funds into protocol
     * @param asset The address of the asset to deposit
     * @param amount The amount to deposit
     * @return shares The amount of protocol shares received
     */
    function deposit(address asset, uint256 amount) external returns (uint256 shares);

    /**
     * @notice Withdraw funds from protocol
     * @param shares The amount of protocol shares to redeem
     * @return amount The amount of assets withdrawn
     */
    function withdraw(uint256 shares) external returns (uint256 amount);

    /**
     * @notice Get current APY (in basis points)
     * @return The current annual percentage yield (e.g., 500 = 5%)
     */
    function getCurrentAPY() external view returns (uint256);

    /**
     * @notice Get total value locked in this strategy
     * @return The total value locked in the underlying protocol
     */
    function getTVL() external view returns (uint256);

    /**
     * @notice Get protocol-specific risk metrics
     * @return utilization The utilization rate (0-10000 basis points)
     * @return liquidationRisk The liquidation risk score (0-10000)
     * @return oracleDeviation The oracle price deviation (0-10000)
     */
    function getRiskMetrics() external view returns (
        uint256 utilization,
        uint256 liquidationRisk,
        uint256 oracleDeviation
    );

    /**
     * @notice Emergency exit from protocol
     * @return recovered The amount of assets recovered
     */
    function emergencyWithdraw() external returns (uint256 recovered);

    /**
     * @notice Get the underlying protocol address
     * @return The address of the underlying DeFi protocol
     */
    function protocol() external view returns (address);

    /**
     * @notice Get the supported asset
     * @return The address of the asset this adapter supports
     */
    function asset() external view returns (address);
}
