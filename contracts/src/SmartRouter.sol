// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/ISmartRouter.sol";
import "./interfaces/ISmartVault.sol";
import "./interfaces/IStrategyAdapter.sol";

/**
 * @title SmartRouter
 * @notice Handles cross-chain fund routing and protocol interactions
 * @dev Manages bridge selection, cross-chain messaging, and rebalancing operations
 */
contract SmartRouter is ISmartRouter, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // State variables
    address public immutable override vault;
    
    // Supported bridges
    mapping(address => bool) public supportedBridges;
    address[] private bridgeList;
    
    // Bridge configurations for chain pairs
    mapping(uint256 => mapping(uint256 => BridgeInfo[])) private chainPairBridges;
    
    // Message tracking
    mapping(bytes32 => bool) public processedMessages;
    
    // Constants
    uint256 private constant MAX_BRIDGES = 10;
    uint256 private constant COST_WEIGHT = 40; // 40% weight
    uint256 private constant SPEED_WEIGHT = 30; // 30% weight
    uint256 private constant SECURITY_WEIGHT = 30; // 30% weight

    // Errors
    error InvalidChainId();
    error InvalidProtocol();
    error InvalidAmount();
    error InvalidArrayLength();
    error BridgeNotSupported();
    error MessageAlreadyProcessed();
    error InsufficientBridgeFee();
    error RebalanceFailed();
    error ZeroAddress();

    /**
     * @notice Constructor
     * @param _vault The address of the SmartVault contract
     */
    constructor(address _vault) Ownable(msg.sender) {
        if (_vault == address(0)) revert ZeroAddress();
        vault = _vault;
    }

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
    ) external payable override nonReentrant {
        if (srcChainId == 0 || dstChainId == 0) revert InvalidChainId();
        if (protocol == address(0)) revert InvalidProtocol();
        if (amount == 0) revert InvalidAmount();

        // Get optimal bridge for this chain pair
        (address bridge, uint256 estimatedCost) = getOptimalBridge(srcChainId, dstChainId);
        
        if (!supportedBridges[bridge]) revert BridgeNotSupported();
        if (msg.value < estimatedCost) revert InsufficientBridgeFee();

        // If same chain, directly interact with protocol
        if (srcChainId == dstChainId) {
            _routeLocal(protocol, amount);
        } else {
            // Cross-chain routing through bridge
            _routeCrossChain(srcChainId, dstChainId, protocol, amount, bridge, bridgeParams);
        }

        emit Route(srcChainId, dstChainId, protocol, amount, bridge);
    }

    /**
     * @notice Receive cross-chain message
     * @param srcChainId Source chain ID
     * @param payload Message payload
     */
    function receiveMessage(
        uint256 srcChainId,
        bytes calldata payload
    ) external override nonReentrant {
        // Generate message ID
        bytes32 messageId = keccak256(abi.encodePacked(srcChainId, payload, block.timestamp));
        
        if (processedMessages[messageId]) revert MessageAlreadyProcessed();
        
        // Mark message as processed
        processedMessages[messageId] = true;

        // Decode and process message
        (address protocol, uint256 amount) = abi.decode(payload, (address, uint256));
        
        // Execute the routing on this chain
        _routeLocal(protocol, amount);

        emit MessageReceived(srcChainId, messageId, payload);
    }

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
    ) external override onlyOwner nonReentrant {
        if (exitProtocols.length != enterProtocols.length || 
            exitProtocols.length != amounts.length) {
            revert InvalidArrayLength();
        }

        // Exit from protocols
        for (uint256 i = 0; i < exitProtocols.length; i++) {
            if (amounts[i] > 0) {
                _exitProtocol(exitProtocols[i], amounts[i]);
            }
        }

        // Enter new protocols
        for (uint256 i = 0; i < enterProtocols.length; i++) {
            if (amounts[i] > 0) {
                _enterProtocol(enterProtocols[i], amounts[i]);
            }
        }

        emit Rebalance(exitProtocols, enterProtocols, amounts);
    }

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
    ) public view override returns (address bridge, uint256 estimatedCost) {
        BridgeInfo[] memory bridges = chainPairBridges[srcChain][dstChain];
        
        if (bridges.length == 0) {
            // Return first supported bridge as fallback
            if (bridgeList.length > 0) {
                return (bridgeList[0], 0);
            }
            revert BridgeNotSupported();
        }

        // Calculate scores for each bridge
        uint256 bestScore = 0;
        uint256 bestIndex = 0;

        for (uint256 i = 0; i < bridges.length; i++) {
            // Normalize values (assuming max cost is 1 ether, max time is 1 hour, security is 0-100)
            uint256 costScore = bridges[i].estimatedCost > 0 
                ? (1e18 * COST_WEIGHT) / bridges[i].estimatedCost 
                : COST_WEIGHT * 1e18;
            
            uint256 speedScore = bridges[i].estimatedTime > 0 
                ? (3600 * SPEED_WEIGHT * 1e18) / bridges[i].estimatedTime 
                : SPEED_WEIGHT * 1e18;
            
            uint256 securityScore = (bridges[i].securityScore * SECURITY_WEIGHT * 1e18) / 100;

            uint256 totalScore = (costScore + speedScore + securityScore) / 1e18;

            if (totalScore > bestScore) {
                bestScore = totalScore;
                bestIndex = i;
            }
        }

        return (bridges[bestIndex].bridge, bridges[bestIndex].estimatedCost);
    }

    /**
     * @notice Get all available bridges for a chain pair
     * @param srcChain Source chain ID
     * @param dstChain Destination chain ID
     * @return bridges Array of available bridge information
     */
    function getAvailableBridges(
        uint256 srcChain,
        uint256 dstChain
    ) external view override returns (BridgeInfo[] memory bridges) {
        return chainPairBridges[srcChain][dstChain];
    }

    /**
     * @notice Check if a bridge is supported
     * @param bridge Bridge address
     * @return True if bridge is supported
     */
    function isBridgeSupported(address bridge) external view override returns (bool) {
        return supportedBridges[bridge];
    }

    // Admin functions

    /**
     * @notice Add supported bridge
     * @param bridge Bridge address
     */
    function addBridge(address bridge) external onlyOwner {
        if (bridge == address(0)) revert ZeroAddress();
        if (bridgeList.length >= MAX_BRIDGES) revert BridgeNotSupported();
        
        supportedBridges[bridge] = true;
        bridgeList.push(bridge);
    }

    /**
     * @notice Remove supported bridge
     * @param bridge Bridge address
     */
    function removeBridge(address bridge) external onlyOwner {
        supportedBridges[bridge] = false;
        
        // Remove from list
        for (uint256 i = 0; i < bridgeList.length; i++) {
            if (bridgeList[i] == bridge) {
                bridgeList[i] = bridgeList[bridgeList.length - 1];
                bridgeList.pop();
                break;
            }
        }
    }

    /**
     * @notice Configure bridge for chain pair
     * @param srcChain Source chain ID
     * @param dstChain Destination chain ID
     * @param bridge Bridge address
     * @param estimatedCost Estimated cost
     * @param estimatedTime Estimated time in seconds
     * @param securityScore Security score (0-100)
     */
    function configureBridge(
        uint256 srcChain,
        uint256 dstChain,
        address bridge,
        uint256 estimatedCost,
        uint256 estimatedTime,
        uint256 securityScore
    ) external onlyOwner {
        if (!supportedBridges[bridge]) revert BridgeNotSupported();
        
        BridgeInfo memory info = BridgeInfo({
            bridge: bridge,
            estimatedCost: estimatedCost,
            estimatedTime: estimatedTime,
            securityScore: securityScore
        });

        chainPairBridges[srcChain][dstChain].push(info);
    }

    /**
     * @notice Get list of all supported bridges
     * @return Array of bridge addresses
     */
    function getSupportedBridges() external view returns (address[] memory) {
        return bridgeList;
    }

    // Internal functions

    /**
     * @notice Route funds locally (same chain)
     * @param protocol Target protocol
     * @param amount Amount to route
     */
    function _routeLocal(address protocol, uint256 amount) internal {
        // This would interact with the vault to allocate funds
        // For now, we emit an event
        // In production, this would call vault.allocate(protocol, amount)
    }

    /**
     * @notice Route funds cross-chain
     * @param srcChainId Source chain ID
     * @param dstChainId Destination chain ID
     * @param protocol Target protocol
     * @param amount Amount to route
     * @param bridge Bridge to use
     * @param bridgeParams Bridge-specific parameters
     */
    function _routeCrossChain(
        uint256 srcChainId,
        uint256 dstChainId,
        address protocol,
        uint256 amount,
        address bridge,
        bytes calldata bridgeParams
    ) internal {
        // Encode message payload
        bytes memory payload = abi.encode(protocol, amount);
        
        // This would interact with the actual bridge contract
        // For now, we just emit an event
        // In production, this would call the bridge's send function
        
        emit BridgeSelected(srcChainId, dstChainId, bridge, msg.value);
    }

    /**
     * @notice Exit from a protocol
     * @param protocol Protocol to exit
     * @param amount Amount to withdraw
     */
    function _exitProtocol(address protocol, uint256 amount) internal {
        // This would interact with the strategy adapter
        // In production: IStrategyAdapter(protocol).withdraw(amount)
    }

    /**
     * @notice Enter a protocol
     * @param protocol Protocol to enter
     * @param amount Amount to deposit
     */
    function _enterProtocol(address protocol, uint256 amount) internal {
        // This would interact with the strategy adapter
        // In production: IStrategyAdapter(protocol).deposit(asset, amount)
    }

    /**
     * @notice Withdraw stuck tokens (emergency)
     * @param token Token address
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }

    /**
     * @notice Withdraw stuck native tokens (emergency)
     */
    function emergencyWithdrawNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Receive function to accept native tokens
    receive() external payable {}
}
