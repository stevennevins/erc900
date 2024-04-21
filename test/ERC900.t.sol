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

    address internal staker1 = address(1);
    address internal staker2 = address(2);
    address internal staker3 = address(3);
    uint256 internal stakeAmount1 = 100 * 10**18; // 100 tokens
    uint256 internal stakeAmount2 = 150 * 10**18; // 150 tokens
    uint256 internal stakeAmount3 = 200 * 10**18; // 200 tokens

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        erc900 = new ERC900(address(mockToken));
    }

    function testStakeTokens() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        vm.stopPrank();

        assertEq(erc900.totalStakedFor(address(1)), stakeAmount1, "Staked amount should match");
        assertEq(erc900.totalStaked(), stakeAmount1, "Total staked should match");
    }

    function testUnstakeTokens() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        mockToken.approve(address(erc900),type(uint256).max);
        erc900.stake(stakeAmount1, "");
        erc900.unstake(stakeAmount1, "");
        vm.stopPrank();

        assertEq(erc900.totalStakedFor(staker1), 0, "Staked amount should be zero after unstaking");
        assertEq(erc900.totalStaked(), 0, "Total staked should be zero after unstaking");
    
    }

function testPartialUnstakeTokens() public {
    uint256 unstakeAmount = 40 * 10**18; // 40 tokens
    uint256 expectedRemainingStake = stakeAmount1 - unstakeAmount;

    mockToken.mint(staker1, stakeAmount1);

    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");
    erc900.unstake(unstakeAmount, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker1), expectedRemainingStake, "Remaining staked amount should match expected after partial unstake");
    assertEq(erc900.totalStaked(), expectedRemainingStake, "Total staked should match remaining stake after partial unstake");
}
function testReStakeTokens() public {
    uint256 reStakeAmount = 50 * 10**18; // 50 tokens
    uint256 expectedTotalStakeAfterReStake = stakeAmount1 + reStakeAmount;

    mockToken.mint(staker1, stakeAmount1 + reStakeAmount);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1 + reStakeAmount);
    erc900.stake(stakeAmount1, "");
    erc900.stake(reStakeAmount, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker1), expectedTotalStakeAfterReStake, "Staked amount should match the re-staked amount");
    assertEq(erc900.totalStaked(), expectedTotalStakeAfterReStake, "Total staked should match the re-staked amount");
}
function testStakingByMultipleAddresses() public {
    mockToken.mint(staker1, stakeAmount1);
    mockToken.mint(staker2, stakeAmount2);

    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");
    vm.stopPrank();

    vm.startPrank(staker2);
    mockToken.approve(address(erc900), stakeAmount2);
    erc900.stake(stakeAmount2, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staked amount for staker1 should match");
    assertEq(erc900.totalStakedFor(staker2), stakeAmount2, "Staked amount for staker2 should match");

    uint256 expectedTotalStaked = stakeAmount1 + stakeAmount2;
    assertEq(erc900.totalStaked(), expectedTotalStaked, "Total staked should match the sum of individual stakes");
}

function testUnstakeMoreThanStaked() public {
    uint256 unstakeAmount = 150 * 10**18; // Attempting to unstake 150 tokens
    assertGt(unstakeAmount, stakeAmount1, "Unstake Amount less than Staked");

    mockToken.mint(staker1, stakeAmount1);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");

    vm.expectRevert("Insufficient stake");
    erc900.unstake(unstakeAmount, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staked amount should not change after failed unstake");
    assertEq(erc900.totalStaked(), stakeAmount1, "Total staked should not change after failed unstake");
}

function testStakeEventEmission() public {
    // Mint tokens and stake them
    mockToken.mint(staker1, stakeAmount1);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);

    vm.expectEmit(true, true, true, true);
    emit Staked(staker1, stakeAmount1, stakeAmount1, "");
    erc900.stake(stakeAmount1, "");

    vm.stopPrank();
}

function testUnstakeEventEmission() public {
    uint256 unstakeAmount = 50 * 10**18; // 50 tokens

    mockToken.mint(staker1, stakeAmount1);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");

    vm.expectEmit(true, true, true, true);
    emit Unstaked(staker1, unstakeAmount, stakeAmount1 - unstakeAmount, "");
    erc900.unstake(unstakeAmount, "");

    vm.stopPrank();
}
function testZeroAmountStake() public {
    uint256 zeroStakeAmount = 0; // Zero tokens

    mockToken.mint(staker1, zeroStakeAmount);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), zeroStakeAmount);

    vm.expectRevert("Stake amount must be positive");
    erc900.stake(zeroStakeAmount, "");

    vm.stopPrank();
}

function testZeroAmountUnstake() public {
    uint256 zeroUnstakeAmount = 0; // Zero tokens

    // Mint tokens and stake them
    mockToken.mint(staker1, stakeAmount1);
    vm.startPrank(staker1);
    mockToken.approve(address(erc900), stakeAmount1);
    erc900.stake(stakeAmount1, "");

    // Attempt to unstake zero amount and expect revert
    vm.expectRevert("Unstake amount must be positive");
    erc900.unstake(zeroUnstakeAmount, "");

    vm.stopPrank();
}

function testStakeWithInsufficientApproval() public {
    uint256 approvedAmount = 50 * 10**18; // 50 tokens, less than the stake amount

    mockToken.mint(staker1, stakeAmount1);

    vm.startPrank(staker1);

    mockToken.approve(address(erc900), approvedAmount);

    // Expect revert due to insufficient approval
    vm.expectRevert();
    erc900.stake(stakeAmount1, "");

    vm.stopPrank();
}

function testUnstakeWithoutStaking() public {
    uint256 unstakeAmount = 50 * 10**18; 

    vm.startPrank(staker1);
    vm.expectRevert("Insufficient stake");
    erc900.unstake(unstakeAmount, "");

    vm.stopPrank();
}
function testStakingAndUnstakingByMultipleAddresses() public {
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

    assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staker1 staked amount mismatch");
    assertEq(erc900.totalStakedFor(staker2), stakeAmount2, "Staker2 staked amount mismatch");
    assertEq(erc900.totalStakedFor(staker3), stakeAmount3, "Staker3 staked amount mismatch");

    vm.startPrank(staker1);
    erc900.unstake(stakeAmount1, "");
    vm.stopPrank();

    vm.startPrank(staker3);
    erc900.unstake(stakeAmount3, "");
    vm.stopPrank();

    assertEq(erc900.totalStakedFor(staker1), 0, "Staker1 should have 0 staked after unstaking");
    assertEq(erc900.totalStakedFor(staker3), 0, "Staker3 should have 0 staked after unstaking");

    uint256 totalStaked = stakeAmount2; // Only staker2's stake should remain
    assertEq(erc900.totalStaked(), totalStaked, "Total staked amount mismatch after unstaking");
    assertTrue(erc900.isStaker(staker2), "Staker2 should still be in the stakers list");
    assertFalse(erc900.isStaker(staker1), "Staker1 should not be in the stakers list after unstaking");
    assertFalse(erc900.isStaker(staker3), "Staker3 should not be in the stakers list after unstaking");
}

}
