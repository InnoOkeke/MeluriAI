// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title ISmartRouter
 * @notice Interface for the Smart Router contract that handles cross-chain fund routing
 * @dev Manages cross-chain operations and protocol interactions
 */
interface ISmartRouter {
    // Structs
    struct BridgeInfo {
        address bridge;
        uint256 estimatedCost;
        uint256 estimatedTime;
        uint256 securityScore;
    }

    struct RebalanceParams {
        address[] exitProtocols;
        address[] enterProtocols;
        uint256[] amounts;
    }

    // Events
    event Route(
        uint256 indexed srcChainId,
        uint256 indexed dstChainId,
        address indexed protocol,
        uint256 amount,
        address bridge
    );
    event MessageReceived(
        uint256 indexed srcChainId,
        bytes32 indexed messageId,
        bytes payload
    );
    event Rebalance(
        address[] exitProtocols,
        address[] enterProtocols,
        uint256[] amounts
    );
    event BridgeSelected(
        uint256 indexed srcChainId,
        uint256 indexed dstChainId,
        address bridge,
        uint256 cost
    );

    /**
     * @notice Route funds to optimal protocol on target chain
     * @param srcChainId Source chain ID
     * @param dstChainId Destination chain ID
     * @param protocol Target protocol address
     * @param amount Amount to route
     * @param bridgeParams Encoded bridge-specific parameters
     */
    function route(
        uint256 srcChainId,
        uint256 dstChainId,
        address protocol,
        uint256 amount,
        bytes calldata bridgeParams
    ) external payable;

    /**
     * @notice Receive cross-chain message
     * @param srcChainId Source chain ID
     * @param payload Message payload
     */
    function receiveMessage(
        uint256 srcChainId,
        bytes calldata payload
    ) external;

    /**
     * @notice Execute rebalancing across protocols
     * @param exitProtocols Protocols to exit from
     * @param enterProtocols Protocols to enter
     * @param amounts Amounts for each protocol
     */
    function rebalance(
        address[] calldata exitProtocols,
        address[] calldata enterProtocols,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Get optimal bridge for chain pair
     * @param srcChain Source chain ID
     * @param dstChain Destination chain ID
     * @return bridge Address of the optimal bridge
     * @return estimatedCost Estimated cost in native token
     */
    function getOptimalBridge(
        uint256 srcChain,
        uint256 dstChain
    ) external view returns (address bridge, uint256 estimatedCost);

    /**
     * @notice Get all available bridges for a chain pair
     * @param srcChain Source chain ID
     * @param dstChain Destination chain ID
     * @return bridges Array of available bridge information
     */
    function getAvailableBridges(
        uint256 srcChain,
        uint256 dstChain
    ) external view returns (BridgeInfo[] memory bridges);

    /**
     * @notice Check if a bridge is supported
     * @param bridge Bridge address
     * @return True if bridge is supported
     */
    function isBridgeSupported(address bridge) external view returns (bool);

    /**
     * @notice Get the vault address
     * @return The address of the associated vault
     */
    function vault() external view returns (address);
}
