// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "../../src/adapters/BaseStrategyAdapter.sol";

/**
 * @title MockStrategyAdapter
 * @notice Mock strategy adapter for testing purposes
 */
contract MockStrategyAdapter is BaseStrategyAdapter {
    // Mock state
    uint256 public mockAPY = 500; // 5%
    uint256 public mockTVL = 1_000_000e6; // 1M
    uint256 public mockUtilization = 7500; // 75%
    uint256 public mockLiquidationRisk = 1000; // 10%
    uint256 public mockOracleDeviation = 50; // 0.5%
    
    constructor(
        address _protocol,
        address _asset,
        address _vault
    ) BaseStrategyAdapter(_protocol, _asset, _vault) {}

    function _depositToProtocol(uint256 amount) internal override returns (uint256 shares) {
        // Simple 1:1 share minting for testing
        return amount;
    }

    function _withdrawFromProtocol(uint256 shares) internal override returns (uint256 amount) {
        // Simple 1:1 redemption for testing
        return shares;
    }

    function _getProtocolAPY() internal view override returns (uint256) {
        return mockAPY;
    }

    function _getProtocolTVL() internal view override returns (uint256) {
        return mockTVL;
    }

    function _getProtocolRiskMetrics() internal view override returns (
        uint256 utilization,
        uint256 liquidationRisk,
        uint256 oracleDeviation
    ) {
        return (mockUtilization, mockLiquidationRisk, mockOracleDeviation);
    }

    function _emergencyWithdrawFromProtocol() internal override returns (uint256 recovered) {
        // Return all deposited assets
        return IERC20(asset).balanceOf(address(this));
    }

    // Helper functions for testing
    function setMockAPY(uint256 _apy) external {
        mockAPY = _apy;
    }

    function setMockTVL(uint256 _tvl) external {
        mockTVL = _tvl;
    }

    function setMockRiskMetrics(
        uint256 _utilization,
        uint256 _liquidationRisk,
        uint256 _oracleDeviation
    ) external {
        mockUtilization = _utilization;
        mockLiquidationRisk = _liquidationRisk;
        mockOracleDeviation = _oracleDeviation;
    }
}
