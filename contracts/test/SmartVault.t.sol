// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/SmartVault.sol";
import "./mocks/MockERC20.sol";

/**
 * @title SmartVaultTest
 * @notice Test suite for SmartVault contract
 */
contract SmartVaultTest is Test {
    SmartVault public vault;
    MockERC20 public usdc;
    
    address public owner;
    address public user1;
    address public user2;
    
    uint256 constant INITIAL_BALANCE = 1_000_000e6; // 1M USDC
    uint256 constant MAX_DEPOSIT = 100_000e6; // 100K USDC
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // Deploy mock USDC
        usdc = new MockERC20("USD Coin", "USDC", 6);
        
        // Deploy vault
        vault = new SmartVault(address(usdc));
        
        // Mint tokens to users
        usdc.mint(user1, INITIAL_BALANCE);
        usdc.mint(user2, INITIAL_BALANCE);
    }
    
    /**
     * @notice **Feature: meluri-ai-yield-aggregator, Property 2: Share minting proportionality**
     * @dev For any valid deposit, the vault shares minted should be proportional to the deposit amount
     *      relative to the current share price, maintaining the invariant that total_assets / total_shares
     *      remains consistent.
     * **Validates: Requirements 1.2**
     */
    function testFuzz_ShareMintingProportionality(uint256 depositAmount) public {
        // Bound deposit amount to reasonable range
        depositAmount = bound(depositAmount, 1e6, MAX_DEPOSIT); // Min 1 USDC, Max 100K USDC
        
        // Setup: user1 approves vault
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        
        // Record state before deposit
        uint256 sharesBefore = vault.totalShares();
        uint256 assetsBefore = vault.totalAssets();
        uint256 sharePriceBefore = vault.sharePrice();
        
        // Execute deposit
        uint256 sharesMinted = vault.deposit(address(usdc), depositAmount);
        
        // Record state after deposit
        uint256 sharesAfter = vault.totalShares();
        uint256 assetsAfter = vault.totalAssets();
        uint256 sharePriceAfter = vault.sharePrice();
        
        vm.stopPrank();
        
        // Property 1: Shares minted should be proportional to deposit amount
        if (sharesBefore == 0) {
            // First deposit: shares should equal deposit amount (1:1 ratio)
            assertEq(sharesMinted, depositAmount, "First deposit should mint shares 1:1");
        } else {
            // Subsequent deposits: shares should be proportional to existing ratio
            uint256 expectedShares = (depositAmount * sharesBefore) / assetsBefore;
            
            // Allow 1% tolerance for rounding
            uint256 tolerance = expectedShares / 100;
            if (tolerance == 0) tolerance = 1;
            
            assertApproxEqAbs(
                sharesMinted,
                expectedShares,
                tolerance,
                "Shares minted should be proportional to deposit"
            );
        }
        
        // Property 2: Total shares should increase by minted amount
        assertEq(
            sharesAfter,
            sharesBefore + sharesMinted,
            "Total shares should increase by minted amount"
        );
        
        // Property 3: Total assets should increase by deposit amount
        assertEq(
            assetsAfter,
            assetsBefore + depositAmount,
            "Total assets should increase by deposit amount"
        );
        
        // Property 4: Share price should remain stable (within 1% tolerance)
        if (sharesBefore > 0) {
            uint256 priceTolerance = sharePriceBefore / 100;
            if (priceTolerance == 0) priceTolerance = 1;
            
            assertApproxEqAbs(
                sharePriceAfter,
                sharePriceBefore,
                priceTolerance,
                "Share price should remain stable after deposit"
            );
        }
        
        // Property 5: User should receive the minted shares
        assertEq(
            vault.balanceOf(user1),
            sharesMinted,
            "User should receive minted shares"
        );
    }
    
    /**
     * @notice Test share minting proportionality with multiple sequential deposits
     * @dev This tests that the proportionality property holds across multiple deposits
     */
    function testFuzz_MultipleDepositsProportionality(
        uint256 deposit1,
        uint256 deposit2,
        uint256 deposit3
    ) public {
        // Bound deposits to reasonable ranges
        deposit1 = bound(deposit1, 1e6, MAX_DEPOSIT / 3);
        deposit2 = bound(deposit2, 1e6, MAX_DEPOSIT / 3);
        deposit3 = bound(deposit3, 1e6, MAX_DEPOSIT / 3);
        
        // First deposit by user1
        vm.startPrank(user1);
        usdc.approve(address(vault), deposit1);
        uint256 shares1 = vault.deposit(address(usdc), deposit1);
        vm.stopPrank();
        
        uint256 sharePrice1 = vault.sharePrice();
        
        // Second deposit by user2
        vm.startPrank(user2);
        usdc.approve(address(vault), deposit2);
        uint256 shares2 = vault.deposit(address(usdc), deposit2);
        vm.stopPrank();
        
        uint256 sharePrice2 = vault.sharePrice();
        
        // Third deposit by user1
        vm.startPrank(user1);
        usdc.approve(address(vault), deposit3);
        uint256 shares3 = vault.deposit(address(usdc), deposit3);
        vm.stopPrank();
        
        uint256 sharePrice3 = vault.sharePrice();
        
        // Verify share prices remain stable across deposits (within 1% tolerance)
        uint256 tolerance = sharePrice1 / 100;
        if (tolerance == 0) tolerance = 1;
        
        assertApproxEqAbs(
            sharePrice2,
            sharePrice1,
            tolerance,
            "Share price should remain stable after second deposit"
        );
        
        assertApproxEqAbs(
            sharePrice3,
            sharePrice1,
            tolerance,
            "Share price should remain stable after third deposit"
        );
        
        // Verify total assets equal sum of deposits
        assertEq(
            vault.totalAssets(),
            deposit1 + deposit2 + deposit3,
            "Total assets should equal sum of all deposits"
        );
        
        // Verify total shares equal sum of minted shares
        assertEq(
            vault.totalShares(),
            shares1 + shares2 + shares3,
            "Total shares should equal sum of all minted shares"
        );
        
        // Verify user balances
        assertEq(
            vault.balanceOf(user1),
            shares1 + shares3,
            "User1 should have shares from first and third deposits"
        );
        
        assertEq(
            vault.balanceOf(user2),
            shares2,
            "User2 should have shares from second deposit"
        );
    }
    
    /**
     * @notice Test that share price remains constant after deposit and withdrawal cycle
     * @dev This is a round-trip property test
     */
    function testFuzz_DepositWithdrawRoundTrip(uint256 depositAmount) public {
        depositAmount = bound(depositAmount, 1e6, MAX_DEPOSIT);
        
        // Initial deposit by user1
        vm.startPrank(user1);
        usdc.approve(address(vault), depositAmount);
        uint256 sharesMinted = vault.deposit(address(usdc), depositAmount);
        
        uint256 sharePriceAfterDeposit = vault.sharePrice();
        
        // Withdraw all shares
        uint256 assetsReturned = vault.withdraw(sharesMinted);
        vm.stopPrank();
        
        // After complete withdrawal, vault should be empty
        assertEq(vault.totalShares(), 0, "Total shares should be zero after complete withdrawal");
        assertEq(vault.totalAssets(), 0, "Total assets should be zero after complete withdrawal");
        
        // User should receive approximately the same amount back (within rounding)
        assertApproxEqAbs(
            assetsReturned,
            depositAmount,
            1,
            "User should receive approximately the same amount back"
        );
        
        // Make another deposit to verify share price resets correctly
        vm.startPrank(user2);
        usdc.approve(address(vault), depositAmount);
        uint256 newSharesMinted = vault.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        // First deposit after empty vault should mint shares 1:1
        assertEq(
            newSharesMinted,
            depositAmount,
            "First deposit after empty vault should mint shares 1:1"
        );
    }
}
