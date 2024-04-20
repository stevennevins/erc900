// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC900} from "../src/ERC900.sol";
import {MockERC20} from "./mocks/MockERC20.sol"; // Assuming you have a MockERC20 contract

contract ERC900Test is Test {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    ERC900 internal erc900;
    MockERC20 internal mockToken;

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        erc900 = new ERC900(address(mockToken));
    }

    function testStakeTokens() public {
        address staker = address(1);
        uint256 stakeAmount = 100 * 10**18; // 100 tokens
        mockToken.mint(staker, stakeAmount);

        vm.startPrank(staker);
        mockToken.approve(address(erc900), stakeAmount);
        erc900.stake(stakeAmount, "");
        vm.stopPrank();

        assertEq(erc900.totalStakedFor(address(1)), stakeAmount, "Staked amount should match");
        assertEq(erc900.totalStaked(), stakeAmount, "Total staked should match");
    }

    function testUnstakeTokens() public {
        address staker = address(1);
        uint256 stakeAmount = 100 * 10**18; // 100 tokens
        mockToken.mint(staker, stakeAmount);

        vm.startPrank(staker);
        mockToken.approve(address(erc900), stakeAmount);
        mockToken.approve(address(erc900),type(uint256).max);
        erc900.stake(stakeAmount, "");
        erc900.unstake(stakeAmount, "");
        vm.stopPrank();

        assertEq(erc900.totalStakedFor(staker), 0, "Staked amount should be zero after unstaking");
        assertEq(erc900.totalStaked(), 0, "Total staked should be zero after unstaking");
    
    }

function testPartialUnstakeTokens() public {
    address staker = address(1);
    uint256 initialStakeAmount = 100 * 10**18; // 100 tokens
    uint256 unstakeAmount = 40 * 10**18; // 40 tokens
    uint256 expectedRemainingStake = initialStakeAmount - unstakeAmount;

    mockToken.mint(staker, initialStakeAmount);

    vm.startPrank(staker);
    mockToken.approve(address(erc900), initialStakeAmount);
    erc900.stake(initialStakeAmount, "");
    erc900.unstake(unstakeAmount, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker), expectedRemainingStake, "Remaining staked amount should match expected after partial unstake");
    assertEq(erc900.totalStaked(), expectedRemainingStake, "Total staked should match remaining stake after partial unstake");
}
function testReStakeTokens() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens
    uint256 reStakeAmount = 50 * 10**18; // 50 tokens
    uint256 expectedTotalStakeAfterReStake = stakeAmount + reStakeAmount;

    // Mint initial tokens and stake them
    mockToken.mint(staker, stakeAmount + reStakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), stakeAmount + reStakeAmount);
    erc900.stake(stakeAmount, "");
    erc900.unstake(stakeAmount, "");
    erc900.stake(reStakeAmount, "");
    vm.stopPrank();

    // Check the staked amounts after re-staking
    assertEq(erc900.totalStakedFor(staker), reStakeAmount, "Staked amount should match the re-staked amount");
    assertEq(erc900.totalStaked(), reStakeAmount, "Total staked should match the re-staked amount");
}
function testStakingByMultipleAddresses() public {
    address staker1 = address(1);
    address staker2 = address(2);
    uint256 stakeAmount1 = 100 * 10**18; // 100 tokens
    uint256 stakeAmount2 = 150 * 10**18; // 150 tokens

    // Mint tokens to staker1 and staker2
    mockToken.mint(staker1, stakeAmount1);
    mockToken.mint(staker2, stakeAmount2);

    // Staker1 stakes tokens
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");
    vm.stopPrank();

    // Staker2 stakes tokens
    vm.startPrank(staker2);
    mockToken.approve(address(erc900), stakeAmount2);
    erc900.stake(stakeAmount2, "");
    vm.stopPrank();

    // Check individual staked amounts
    assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staked amount for staker1 should match");
    assertEq(erc900.totalStakedFor(staker2), stakeAmount2, "Staked amount for staker2 should match");

    // Check total staked amount
    uint256 expectedTotalStaked = stakeAmount1 + stakeAmount2;
    assertEq(erc900.totalStaked(), expectedTotalStaked, "Total staked should match the sum of individual stakes");
}

function testUnstakeMoreThanStaked() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens
    uint256 unstakeAmount = 150 * 10**18; // Attempting to unstake 150 tokens

    // Mint tokens and stake them
    mockToken.mint(staker, stakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), stakeAmount);
    erc900.stake(stakeAmount, "");

    // Attempt to unstake more than staked and expect revert
    vm.expectRevert("Insufficient stake");
    erc900.unstake(unstakeAmount, "");
    vm.stopPrank();

    // Verify that the staked amount has not changed
    assertEq(erc900.totalStakedFor(staker), stakeAmount, "Staked amount should not change after failed unstake");
    assertEq(erc900.totalStaked(), stakeAmount, "Total staked should not change after failed unstake");
}

function testStakeEventEmission() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens

    // Mint tokens and stake them
    mockToken.mint(staker, stakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), stakeAmount);

    // Expect the Staked event to be emitted with correct parameters
    vm.expectEmit(true, true, true, true);
    emit Staked(staker, stakeAmount, stakeAmount, "");
    erc900.stake(stakeAmount, "");

    vm.stopPrank();
}

function testUnstakeEventEmission() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens
    uint256 unstakeAmount = 50 * 10**18; // 50 tokens

    // Mint tokens and stake them
    mockToken.mint(staker, stakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), stakeAmount);
    erc900.stake(stakeAmount, "");

    // Expect the Unstaked event to be emitted with correct parameters
    vm.expectEmit(true, true, true, true);
    emit Unstaked(staker, unstakeAmount, stakeAmount - unstakeAmount, "");
    erc900.unstake(unstakeAmount, "");

    vm.stopPrank();
}
function testZeroAmountStake() public {
    address staker = address(1);
    uint256 zeroStakeAmount = 0; // Zero tokens

    // Mint zero tokens and attempt to stake them
    mockToken.mint(staker, zeroStakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), zeroStakeAmount);

    // Expect revert due to staking zero amount
    vm.expectRevert("Stake amount must be positive");
    erc900.stake(zeroStakeAmount, "");

    vm.stopPrank();
}

function testZeroAmountUnstake() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens
    uint256 zeroUnstakeAmount = 0; // Zero tokens

    // Mint tokens and stake them
    mockToken.mint(staker, stakeAmount);
    vm.startPrank(staker);
    mockToken.approve(address(erc900), stakeAmount);
    erc900.stake(stakeAmount, "");

    // Attempt to unstake zero amount and expect revert
    vm.expectRevert("Unstake amount must be positive");
    erc900.unstake(zeroUnstakeAmount, "");

    vm.stopPrank();
}

function testStakeWithInsufficientApproval() public {
    address staker = address(1);
    uint256 stakeAmount = 100 * 10**18; // 100 tokens
    uint256 approvedAmount = 50 * 10**18; // 50 tokens, less than the stake amount

    // Mint tokens to staker
    mockToken.mint(staker, stakeAmount);

    // Start prank as staker
    vm.startPrank(staker);

    // Approve the contract for less than the stake amount
    mockToken.approve(address(erc900), approvedAmount);

    // Expect revert due to insufficient approval
    vm.expectRevert();
    erc900.stake(stakeAmount, "");

    // Stop prank
    vm.stopPrank();
}

function testUnstakeWithoutStaking() public {
    address staker = address(1);
    uint256 unstakeAmount = 50 * 10**18; // Attempting to unstake 50 tokens without staking

    // Start prank as staker
    vm.startPrank(staker);

    // Expect revert due to attempting to unstake without any prior staking
    vm.expectRevert("Insufficient stake");
    erc900.unstake(unstakeAmount, "");

    // Stop prank
    vm.stopPrank();
}
function testStakingAndUnstakingByMultipleAddresses() public {
    address staker1 = address(1);
    address staker2 = address(2);
    address staker3 = address(3);
    uint256 stakeAmount1 = 100 * 10**18; // 100 tokens
    uint256 stakeAmount2 = 150 * 10**18; // 150 tokens
    uint256 stakeAmount3 = 200 * 10**18; // 200 tokens

    // Mint and stake tokens for multiple stakers
    mockToken.mint(staker1, stakeAmount1);
    mockToken.mint(staker2, stakeAmount2);
    mockToken.mint(staker3, stakeAmount3);

    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");
    vm.stopPrank();

    vm.startPrank(staker2);
    mockToken.approve(address(erc900), stakeAmount2);
    erc900.stake(stakeAmount2, "");
    vm.stopPrank();

    vm.startPrank(staker3);
    mockToken.approve(address(erc900), stakeAmount3);
    erc900.stake(stakeAmount3, "");
    vm.stopPrank();

    // Verify staking
    assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staker1 staked amount mismatch");
    assertEq(erc900.totalStakedFor(staker2), stakeAmount2, "Staker2 staked amount mismatch");
    assertEq(erc900.totalStakedFor(staker3), stakeAmount3, "Staker3 staked amount mismatch");

    // Unstake all tokens by staker1 and staker3
    vm.startPrank(staker1);
    erc900.unstake(stakeAmount1, "");
    vm.stopPrank();

    vm.startPrank(staker3);
    erc900.unstake(stakeAmount3, "");
    vm.stopPrank();

    // Verify unstaking
    assertEq(erc900.totalStakedFor(staker1), 0, "Staker1 should have 0 staked after unstaking");
    assertEq(erc900.totalStakedFor(staker3), 0, "Staker3 should have 0 staked after unstaking");

    // Check total staked and stakers count
    uint256 totalStaked = stakeAmount2; // Only staker2's stake should remain
    assertEq(erc900.totalStaked(), totalStaked, "Total staked amount mismatch after unstaking");
    assertTrue(erc900.isStaker(staker2), "Staker2 should still be in the stakers list");
    assertFalse(erc900.isStaker(staker1), "Staker1 should not be in the stakers list after unstaking");
    assertFalse(erc900.isStaker(staker3), "Staker3 should not be in the stakers list after unstaking");
}

}
