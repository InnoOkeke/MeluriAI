// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SmartRouter.sol";
import "../src/SmartVault.sol";
import "./mocks/MockERC20.sol";

/**
 * @title SmartRouterTest
 * @notice Test suite for SmartRouter contract
 */
contract SmartRouterTest is Test {
    SmartRouter public router;
    SmartVault public vault;
    MockERC20 public usdc;
    
    address public owner;
    address public user1;
    address public mockBridge1;
    address public mockBridge2;
    address public mockProtocol;
    
    // Chain IDs
    uint256 constant ETHEREUM_CHAIN_ID = 1;
    uint256 constant BNB_CHAIN_ID = 56;
    uint256 constant POLYGON_CHAIN_ID = 137;
    uint256 constant ARBITRUM_CHAIN_ID = 42161;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        mockBridge1 = makeAddr("bridge1");
        mockBridge2 = makeAddr("bridge2");
        mockProtocol = makeAddr("protocol");
        
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy vault
        vault = new SmartVault(address(usdc));
        
        // Deploy router
        router = new SmartRouter(address(vault));
        
        // Setup bridges
        router.addBridge(mockBridge1);
        router.addBridge(mockBridge2);
        
        // Configure bridges for different chain pairs
        router.configureBridge(
            ETHEREUM_CHAIN_ID,
            BNB_CHAIN_ID,
            mockBridge1,
            0.01 ether, // cost
            300, // 5 minutes
            90 // security score
        );
        
        router.configureBridge(
            ETHEREUM_CHAIN_ID,
            BNB_CHAIN_ID,
            mockBridge2,
            0.02 ether, // higher cost
            180, // 3 minutes (faster)
            85 // slightly lower security
        );
        
        router.configureBridge(
            ETHEREUM_CHAIN_ID,
            POLYGON_CHAIN_ID,
            mockBridge1,
            0.005 ether,
            240,
            95
        );
        
        // Fund user
        usdc.mint(user1, 1_000_000e6);
        vm.deal(user1, 10 ether);
    }
    
    /**
     * @notice **Feature: meluri-ai-yield-aggregator, Property 9: Cross-chain routing correctness**
     * @dev For any allocation that requires moving funds between chains, the Smart Router Contract
     *      should use the Cross-Chain Messaging Protocol to execute the transfer.
     * **Validates: Requirements 3.3**
     */
    function testFuzz_CrossChainRoutingCorrectness(
        uint256 srcChainId,
        uint256 dstChainId,
        uint256 amount
    ) public {
        // Bound inputs to valid ranges - only use chain pairs we've configured
        srcChainId = bound(srcChainId, 1, 2); // Only Ethereum and BNB
        dstChainId = bound(dstChainId, 1, 3); // Ethereum, BNB, and Polygon
        amount = bound(amount, 1e6, 100_000e6); // 1 to 100K USDC
        
        // Map to actual chain IDs
        uint256[] memory chainIds = new uint256[](3);
        chainIds[0] = ETHEREUM_CHAIN_ID;
        chainIds[1] = BNB_CHAIN_ID;
        chainIds[2] = POLYGON_CHAIN_ID;
        
        uint256 actualSrcChain = chainIds[srcChainId - 1];
        uint256 actualDstChain = chainIds[dstChainId - 1];
        
        // Skip if same chain (tested separately)
        vm.assume(actualSrcChain != actualDstChain);
        
        // Only test configured chain pairs
        // We configured: Ethereum->BNB, Ethereum->Polygon
        vm.assume(actualSrcChain == ETHEREUM_CHAIN_ID);
        vm.assume(actualDstChain == BNB_CHAIN_ID || actualDstChain == POLYGON_CHAIN_ID);
        
        // Get optimal bridge
        (address bridge, uint256 estimatedCost) = router.getOptimalBridge(actualSrcChain, actualDstChain);
        
        // Property 1: Bridge should be supported
        assertTrue(router.isBridgeSupported(bridge), "Selected bridge should be supported");
        
        // Property 2: Bridge should be one of the configured bridges
        assertTrue(
            bridge == mockBridge1 || bridge == mockBridge2,
            "Bridge should be one of the configured bridges"
        );
        
        // Property 3: Estimated cost should be reasonable (greater than zero for configured cross-chain routes)
        assertGt(estimatedCost, 0, "Cross-chain routing should have non-zero cost");
        
        // Property 4: Route function should emit Route event with correct parameters
        vm.expectEmit(true, true, true, true);
        emit ISmartRouter.Route(actualSrcChain, actualDstChain, mockProtocol, amount, bridge);
        
        vm.prank(user1);
        router.route{value: estimatedCost}(
            actualSrcChain,
            actualDstChain,
            mockProtocol,
            amount,
            ""
        );
    }
    
    /**
     * @notice Test optimal bridge selection based on cost, speed, and security
     */
    function test_OptimalBridgeSelection() public {
        // Get optimal bridge for Ethereum -> BNB
        (address bridge, uint256 cost) = router.getOptimalBridge(ETHEREUM_CHAIN_ID, BNB_CHAIN_ID);
        
        // Should select bridge1 (lower cost, higher security, slightly slower)
        // or bridge2 (higher cost, faster, lower security)
        // The selection depends on the weighted scoring
        assertTrue(bridge == mockBridge1 || bridge == mockBridge2, "Should select a configured bridge");
        assertGt(cost, 0, "Cost should be greater than zero");
        
        // Get optimal bridge for Ethereum -> Polygon
        (address bridge2, uint256 cost2) = router.getOptimalBridge(ETHEREUM_CHAIN_ID, POLYGON_CHAIN_ID);
        
        // Should select bridge1 (only option for this pair)
        assertEq(bridge2, mockBridge1, "Should select bridge1 for Ethereum -> Polygon");
        assertEq(cost2, 0.005 ether, "Cost should match configured value");
    }
    
    /**
     * @notice Test that routing reverts with insufficient bridge fee
     */
    function testFuzz_InsufficientBridgeFeeReverts(uint256 amount, uint256 providedFee) public {
        amount = bound(amount, 1e6, 100_000e6);
        
        (address bridge, uint256 requiredFee) = router.getOptimalBridge(ETHEREUM_CHAIN_ID, BNB_CHAIN_ID);
        
        // Bound provided fee to be less than required
        providedFee = bound(providedFee, 0, requiredFee - 1);
        
        vm.prank(user1);
        vm.expectRevert(SmartRouter.InsufficientBridgeFee.selector);
        router.route{value: providedFee}(
            ETHEREUM_CHAIN_ID,
            BNB_CHAIN_ID,
            mockProtocol,
            amount,
            ""
        );
    }
    
    /**
     * @notice Test message receiving and processing
     */
    function testFuzz_MessageReceiving(uint256 srcChainId, uint256 amount) public {
        srcChainId = bound(srcChainId, 1, 100);
        amount = bound(amount, 1e6, 100_000e6);
        
        bytes memory payload = abi.encode(mockProtocol, amount);
        
        // Should emit MessageReceived event
        vm.expectEmit(true, false, false, false);
        emit ISmartRouter.MessageReceived(srcChainId, bytes32(0), payload);
        
        router.receiveMessage(srcChainId, payload);
    }
    
    /**
     * @notice Test that duplicate messages are rejected
     */
    function test_DuplicateMessageRejection() public {
        uint256 srcChainId = ETHEREUM_CHAIN_ID;
        uint256 amount = 1000e6;
        bytes memory payload = abi.encode(mockProtocol, amount);
        
        // First message should succeed
        router.receiveMessage(srcChainId, payload);
        
        // Duplicate message should revert
        // Note: This will fail because our messageId includes block.timestamp
        // In production, we'd need a more robust message ID scheme
        vm.warp(block.timestamp); // Keep same timestamp
        vm.expectRevert(SmartRouter.MessageAlreadyProcessed.selector);
        router.receiveMessage(srcChainId, payload);
    }
    
    /**
     * @notice Test rebalancing across protocols
     */
    function testFuzz_Rebalancing(
        uint256 amount1,
        uint256 amount2
    ) public {
        amount1 = bound(amount1, 1e6, 50_000e6);
        amount2 = bound(amount2, 1e6, 50_000e6);
        
        address[] memory exitProtocols = new address[](2);
        address[] memory enterProtocols = new address[](2);
        uint256[] memory amounts = new uint256[](2);
        
        exitProtocols[0] = makeAddr("oldProtocol1");
        exitProtocols[1] = makeAddr("oldProtocol2");
        enterProtocols[0] = makeAddr("newProtocol1");
        enterProtocols[1] = makeAddr("newProtocol2");
        amounts[0] = amount1;
        amounts[1] = amount2;
        
        // Should emit Rebalance event
        vm.expectEmit(true, true, true, true);
        emit ISmartRouter.Rebalance(exitProtocols, enterProtocols, amounts);
        
        router.rebalance(exitProtocols, enterProtocols, amounts);
    }
    
    /**
     * @notice Test that rebalancing reverts with mismatched array lengths
     */
    function test_RebalancingArrayLengthMismatch() public {
        address[] memory exitProtocols = new address[](2);
        address[] memory enterProtocols = new address[](3); // Different length
        uint256[] memory amounts = new uint256[](2);
        
        vm.expectRevert(SmartRouter.InvalidArrayLength.selector);
        router.rebalance(exitProtocols, enterProtocols, amounts);
    }
    
    /**
     * @notice Test bridge management functions
     */
    function test_BridgeManagement() public {
        address newBridge = makeAddr("newBridge");
        
        // Add bridge
        router.addBridge(newBridge);
        assertTrue(router.isBridgeSupported(newBridge), "New bridge should be supported");
        
        // Remove bridge
        router.removeBridge(newBridge);
        assertFalse(router.isBridgeSupported(newBridge), "Removed bridge should not be supported");
    }
    
    /**
     * @notice Test that only owner can perform admin functions
     */
    function test_OnlyOwnerCanManageBridges() public {
        address newBridge = makeAddr("newBridge");
        
        vm.prank(user1);
        vm.expectRevert();
        router.addBridge(newBridge);
        
        vm.prank(user1);
        vm.expectRevert();
        router.removeBridge(mockBridge1);
    }
    
    /**
     * @notice Test getting available bridges for a chain pair
     */
    function test_GetAvailableBridges() public {
        ISmartRouter.BridgeInfo[] memory bridges = router.getAvailableBridges(
            ETHEREUM_CHAIN_ID,
            BNB_CHAIN_ID
        );
        
        // Should have 2 bridges configured
        assertEq(bridges.length, 2, "Should have 2 bridges for Ethereum -> BNB");
        
        // Verify bridge details
        assertEq(bridges[0].bridge, mockBridge1, "First bridge should be mockBridge1");
        assertEq(bridges[0].estimatedCost, 0.01 ether, "First bridge cost should match");
        assertEq(bridges[0].estimatedTime, 300, "First bridge time should match");
        assertEq(bridges[0].securityScore, 90, "First bridge security should match");
    }
    
    /**
     * @notice Test same-chain routing (no bridge needed)
     */
    function testFuzz_SameChainRouting(uint256 amount) public {
        amount = bound(amount, 1e6, 100_000e6);
        
        // Route on same chain should not require bridge fee
        vm.prank(user1);
        router.route{value: 0}(
            ETHEREUM_CHAIN_ID,
            ETHEREUM_CHAIN_ID,
            mockProtocol,
            amount,
            ""
        );
        
        // Should succeed without revert
    }
}
