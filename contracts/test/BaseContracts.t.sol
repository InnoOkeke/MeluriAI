// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "../src/SmartRouter.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockStrategyAdapter.sol";

/**
 * @title BaseContractsTest
 * @notice Unit tests for SmartVault, SmartRouter, and StrategyAdapter base contracts
 */
contract BaseContractsTest is Test {
    SmartVault public vault;
    SmartRouter public router;
    MockStrategyAdapter public adapter;
    MockERC20 public usdc;
    
    address public owner;
    address public user1;
    address public user2;
    address public mockProtocol;
    
    uint256 constant INITIAL_BALANCE = 1_000_000e6;
    
    // Receive function to accept ETH
    receive() external payable {}
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        mockProtocol = makeAddr("protocol");
        
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy vault
        vault = new SmartVault(address(usdc));
        
        // Deploy router
        router = new SmartRouter(address(vault));
        
        // Deploy adapter
        adapter = new MockStrategyAdapter(mockProtocol, address(usdc), address(vault));
        
        // Mint tokens
        usdc.mint(user1, INITIAL_BALANCE);
        usdc.mint(user2, INITIAL_BALANCE);
        usdc.mint(address(adapter), INITIAL_BALANCE); // For adapter testing
    }
    
    // ============ SmartVault Tests ============
    
    function test_VaultDeposit() public {
        uint256 depositAmount = 1000e6;
        
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        assertEq(shares, depositAmount, "First deposit should mint shares 1:1");
        assertEq(vault.balanceOf(user1), shares, "User should have minted shares");
        assertEq(vault.totalAssets(), depositAmount, "Total assets should equal deposit");
    }
    
    function test_VaultWithdraw() public {
        uint256 depositAmount = 1000e6;
        
        // Deposit first
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(address(usdc), depositAmount);
        
        // Withdraw
        uint256 balanceBefore = usdc.balanceOf(user1);
        uint256 withdrawn = vault.withdraw(shares);
        uint256 balanceAfter = usdc.balanceOf(user1);
        vm.stopPrank();
        
        assertEq(withdrawn, depositAmount, "Should withdraw deposited amount");
        assertEq(balanceAfter - balanceBefore, depositAmount, "User should receive assets");
        assertEq(vault.balanceOf(user1), 0, "User shares should be zero");
    }
    
    function test_VaultPause() public {
        vault.pause();
        assertTrue(vault.paused(), "Vault should be paused");
        
        vm.startPrank(user1);
        usdc.approve(address(vault), 1000e6);
        vm.expectRevert(SmartVault.ContractPaused.selector);
        vault.deposit(address(usdc), 1000e6);
        vm.stopPrank();
    }
    
    function test_VaultUnpause() public {
        vault.pause();
        vault.unpause();
        assertFalse(vault.paused(), "Vault should be unpaused");
        
        // Should be able to deposit after unpause
        vm.startPrank(user1);
        usdc.approve(address(vault), 1000e6);
        vault.deposit(address(usdc), 1000e6);
        vm.stopPrank();
    }
    
    function test_VaultAllocate() public {
        // Setup: deposit some funds
        vm.startPrank(user1);
        usdc.approve(address(vault), 10000e6);
        vault.deposit(address(usdc), 10000e6);
        vm.stopPrank();
        
        // Allocate to strategy
        uint256 allocateAmount = 5000e6;
        vault.allocate(address(adapter), allocateAmount);
        
        assertEq(vault.strategyAllocations(address(adapter)), allocateAmount, "Strategy allocation should be recorded");
    }
    
    function test_VaultEmergencyExit() public {
        // Setup: deposit and allocate
        vm.startPrank(user1);
        usdc.approve(address(vault), 10000e6);
        vault.deposit(address(usdc), 10000e6);
        vm.stopPrank();
        
        vault.allocate(address(adapter), 5000e6);
        
        // Emergency exit
        vault.emergencyExit();
        
        assertEq(vault.strategyAllocations(address(adapter)), 0, "Strategy allocation should be zero after emergency exit");
    }
    
    function test_VaultRevertUnsupportedAsset() public {
        MockERC20 unsupportedToken = new MockERC20("Unsupported", "UNS", 18);
        unsupportedToken.mint(user1, 1000e18);
        
        vm.startPrank(user1);
        unsupportedToken.approve(address(vault), 1000e18);
        vm.expectRevert(SmartVault.UnsupportedAsset.selector);
        vault.deposit(address(unsupportedToken), 1000e18);
        vm.stopPrank();
    }
    
    function test_VaultRevertZeroAmount() public {
        vm.startPrank(user1);
        usdc.approve(address(vault), 1000e6);
        vm.expectRevert(SmartVault.InvalidAmount.selector);
        vault.deposit(address(usdc), 0);
        vm.stopPrank();
    }
    
    function test_VaultRevertInsufficientShares() public {
        vm.startPrank(user1);
        vm.expectRevert(SmartVault.InsufficientShares.selector);
        vault.withdraw(1000e6);
        vm.stopPrank();
    }
    
    function test_VaultAddSupportedAsset() public {
        MockERC20 newToken = new MockERC20("New Token", "NEW", 18);
        vault.addSupportedAsset(address(newToken));
        assertTrue(vault.supportedAssets(address(newToken)), "New asset should be supported");
    }
    
    function test_VaultRemoveSupportedAsset() public {
        vault.removeSupportedAsset(address(usdc));
        assertFalse(vault.supportedAssets(address(usdc)), "Asset should not be supported");
    }
    
    // ============ SmartRouter Tests ============
    
    function test_RouterAddBridge() public {
        address newBridge = makeAddr("newBridge");
        router.addBridge(newBridge);
        assertTrue(router.isBridgeSupported(newBridge), "Bridge should be supported");
    }
    
    function test_RouterRemoveBridge() public {
        address bridge = makeAddr("bridge");
        router.addBridge(bridge);
        router.removeBridge(bridge);
        assertFalse(router.isBridgeSupported(bridge), "Bridge should not be supported");
    }
    
    function test_RouterConfigureBridge() public {
        address bridge = makeAddr("bridge");
        router.addBridge(bridge);
        
        router.configureBridge(1, 56, bridge, 0.01 ether, 300, 90);
        
        ISmartRouter.BridgeInfo[] memory bridges = router.getAvailableBridges(1, 56);
        assertEq(bridges.length, 1, "Should have one configured bridge");
        assertEq(bridges[0].bridge, bridge, "Bridge address should match");
        assertEq(bridges[0].estimatedCost, 0.01 ether, "Cost should match");
    }
    
    function test_RouterRebalance() public {
        address[] memory exitProtocols = new address[](1);
        address[] memory enterProtocols = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        
        exitProtocols[0] = makeAddr("oldProtocol");
        enterProtocols[0] = makeAddr("newProtocol");
        amounts[0] = 1000e6;
        
        router.rebalance(exitProtocols, enterProtocols, amounts);
        // Should not revert
    }
    
    function test_RouterRevertInvalidArrayLength() public {
        address[] memory exitProtocols = new address[](2);
        address[] memory enterProtocols = new address[](1);
        uint256[] memory amounts = new uint256[](2);
        
        vm.expectRevert(SmartRouter.InvalidArrayLength.selector);
        router.rebalance(exitProtocols, enterProtocols, amounts);
    }
    
    function test_RouterReceiveMessage() public {
        uint256 srcChainId = 1;
        bytes memory payload = abi.encode(mockProtocol, 1000e6);
        
        router.receiveMessage(srcChainId, payload);
        // Should not revert
    }
    
    function test_RouterEmergencyWithdraw() public {
        // Mint some tokens to router
        usdc.mint(address(router), 1000e6);
        
        uint256 balanceBefore = usdc.balanceOf(owner);
        router.emergencyWithdraw(address(usdc), 1000e6);
        uint256 balanceAfter = usdc.balanceOf(owner);
        
        assertEq(balanceAfter - balanceBefore, 1000e6, "Owner should receive withdrawn tokens");
    }
    
    function test_RouterEmergencyWithdrawNative() public {
        // Send some ETH to router using low-level call
        (bool success,) = address(router).call{value: 1 ether}("");
        require(success, "Failed to send ETH to router");
        
        uint256 balanceBefore = owner.balance;
        router.emergencyWithdrawNative();
        uint256 balanceAfter = owner.balance;
        
        assertEq(balanceAfter - balanceBefore, 1 ether, "Owner should receive withdrawn ETH");
    }
    
    // ============ StrategyAdapter Tests ============
    
    function test_AdapterDeposit() public {
        uint256 depositAmount = 1000e6;
        
        // Mint tokens to vault and approve adapter
        usdc.mint(address(vault), depositAmount);
        
        vm.startPrank(address(vault));
        usdc.approve(address(adapter), depositAmount);
        uint256 shares = adapter.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        assertEq(shares, depositAmount, "Should receive shares 1:1");
        assertEq(adapter.totalDeposited(), depositAmount, "Total deposited should be tracked");
    }
    
    function test_AdapterWithdraw() public {
        uint256 depositAmount = 1000e6;
        
        // Setup: deposit first
        usdc.mint(address(vault), depositAmount);
        vm.startPrank(address(vault));
        usdc.approve(address(adapter), depositAmount);
        uint256 shares = adapter.deposit(address(usdc), depositAmount);
        
        // Withdraw
        uint256 withdrawn = adapter.withdraw(shares);
        vm.stopPrank();
        
        assertEq(withdrawn, depositAmount, "Should withdraw deposited amount");
        assertEq(adapter.totalShares(), 0, "Total shares should be zero");
    }
    
    function test_AdapterGetCurrentAPY() public {
        uint256 apy = adapter.getCurrentAPY();
        assertEq(apy, 500, "APY should be 5% (500 basis points)");
    }
    
    function test_AdapterGetTVL() public {
        uint256 tvl = adapter.getTVL();
        assertEq(tvl, 1_000_000e6, "TVL should match mock value");
    }
    
    function test_AdapterGetRiskMetrics() public {
        (uint256 utilization, uint256 liquidationRisk, uint256 oracleDeviation) = adapter.getRiskMetrics();
        
        assertEq(utilization, 7500, "Utilization should be 75%");
        assertEq(liquidationRisk, 1000, "Liquidation risk should be 10%");
        assertEq(oracleDeviation, 50, "Oracle deviation should be 0.5%");
    }
    
    function test_AdapterEmergencyWithdraw() public {
        uint256 balanceBefore = usdc.balanceOf(address(vault));
        uint256 recovered = adapter.emergencyWithdraw();
        uint256 balanceAfter = usdc.balanceOf(address(vault));
        
        assertGt(recovered, 0, "Should recover some assets");
        assertEq(balanceAfter - balanceBefore, recovered, "Vault should receive recovered assets");
        assertEq(adapter.totalShares(), 0, "Total shares should be reset");
    }
    
    function test_AdapterRevertOnlyVault() public {
        vm.startPrank(user1);
        vm.expectRevert(BaseStrategyAdapter.OnlyVault.selector);
        adapter.deposit(address(usdc), 1000e6);
        vm.stopPrank();
    }
    
    function test_AdapterSetVault() public {
        address newVault = makeAddr("newVault");
        adapter.setVault(newVault);
        assertEq(adapter.vault(), newVault, "Vault address should be updated");
    }
    
    function test_AdapterSetMockValues() public {
        adapter.setMockAPY(1000); // 10%
        assertEq(adapter.getCurrentAPY(), 1000, "APY should be updated");
        
        adapter.setMockTVL(2_000_000e6);
        assertEq(adapter.getTVL(), 2_000_000e6, "TVL should be updated");
        
        adapter.setMockRiskMetrics(8000, 2000, 100);
        (uint256 util, uint256 liq, uint256 oracle) = adapter.getRiskMetrics();
        assertEq(util, 8000, "Utilization should be updated");
        assertEq(liq, 2000, "Liquidation risk should be updated");
        assertEq(oracle, 100, "Oracle deviation should be updated");
    }
    
    // ============ Integration Tests ============
    
    function test_VaultWithStrategyIntegration() public {
        // Deposit to vault
        vm.startPrank(user1);
        usdc.approve(address(vault), 10000e6);
        vault.deposit(address(usdc), 10000e6);
        vm.stopPrank();
        
        // Allocate to strategy
        vault.allocate(address(adapter), 5000e6);
        
        // Verify allocation
        assertEq(vault.strategyAllocations(address(adapter)), 5000e6, "Strategy should have allocation");
        assertEq(adapter.totalDeposited(), 5000e6, "Adapter should track deposit");
        
        // Withdraw from vault (should pull from strategy)
        vm.startPrank(user1);
        uint256 userShares = vault.balanceOf(user1);
        vault.withdraw(userShares);
        vm.stopPrank();
        
        assertEq(vault.balanceOf(user1), 0, "User should have no shares");
    }
}
