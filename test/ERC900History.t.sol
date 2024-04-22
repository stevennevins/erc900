// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC900History} from "../src/ERC900History.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract ERC900Test is Test {
    ERC900History internal erc900;
    MockERC20 internal mockToken;

    address internal staker1 = address(1);
    address internal staker2 = address(2);
    address internal staker3 = address(3);
    uint256 internal stakeAmount1 = 100 * 10 ** 18;
    uint256 internal stakeAmount2 = 150 * 10 ** 18;
    uint256 internal stakeAmount3 = 200 * 10 ** 18;

    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        erc900 = new ERC900History(address(mockToken));
    }

    function testStakeTokens() public {
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");

        uint256 stakedAmountForStaker1 = erc900.totalStakedFor(staker1);
        uint256 totalStakedInContract = erc900.totalStaked();

        assertEq(stakedAmountForStaker1, stakeAmount1, "Staked amount for staker1 should match the amount staked");
        assertEq(
            totalStakedInContract,
            stakeAmount1,
            "Total staked in the contract should match the amount staked by staker1"
        );

        vm.stopPrank();
    }
    function testUnstakeAllTokens() public {
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");

        // Unstake all tokens
        erc900.unstake(stakeAmount1, "");

        uint256 stakedAmountForStaker1 = erc900.totalStakedFor(staker1);
        uint256 totalStakedInContract = erc900.totalStaked();

        assertEq(stakedAmountForStaker1, 0, "Staked amount for staker1 should be zero after unstaking all");
        assertEq(totalStakedInContract, 0, "Total staked in the contract should be zero after unstaking all");

        vm.stopPrank();
    }
    function testPartialUnstakeTokens() public {
        uint256 initialStakeAmount = 150 * 10 ** 18; // 150 tokens
        uint256 unstakeAmount = 50 * 10 ** 18; // 50 tokens
        uint256 expectedRemainingStake = initialStakeAmount - unstakeAmount;

        mockToken.mint(staker1, initialStakeAmount);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), initialStakeAmount);
        erc900.stake(initialStakeAmount, "");

        // Unstake a portion of the tokens
        erc900.unstake(unstakeAmount, "");

        uint256 stakedAmountForStaker1 = erc900.totalStakedFor(staker1);
        uint256 totalStakedInContract = erc900.totalStaked();

        assertEq(
            stakedAmountForStaker1,
            expectedRemainingStake,
            "Staked amount for staker1 should match the expected remaining stake after partial unstake"
        );
        assertEq(
            totalStakedInContract,
            expectedRemainingStake,
            "Total staked in the contract should match the expected remaining stake after partial unstake"
        );

        vm.stopPrank();
    }
    function testReStakeTokens() public {
        uint256 additionalStakeAmount = 50 * 10 ** 18;
        uint256 totalExpectedStake = stakeAmount1 + additionalStakeAmount;

        mockToken.mint(staker1, totalExpectedStake);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), totalExpectedStake);
        erc900.stake(stakeAmount1, "");
        erc900.stake(additionalStakeAmount, "");

        uint256 stakedAmountForStaker1 = erc900.totalStakedFor(staker1);
        uint256 totalStakedInContract = erc900.totalStaked();

        assertEq(
            stakedAmountForStaker1,
            totalExpectedStake,
            "Staked amount for staker1 should match the total expected stake after restaking"
        );
        assertEq(
            totalStakedInContract,
            totalExpectedStake,
            "Total staked in the contract should match the total expected stake after restaking"
        );

        vm.stopPrank();
    }

    function testStakingByMultipleAddresses() public {
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

        assertEq(erc900.totalStakedFor(staker1), stakeAmount1, "Staked amount for staker1 should match");
        assertEq(erc900.totalStakedFor(staker2), stakeAmount2, "Staked amount for staker2 should match");
        assertEq(erc900.totalStakedFor(staker3), stakeAmount3, "Staked amount for staker3 should match");

        uint256 expectedTotalStaked = stakeAmount1 + stakeAmount2 + stakeAmount3;
        assertEq(erc900.totalStaked(), expectedTotalStaked, "Total staked should match the sum of individual stakes");
    }
    function testUnstakeMoreThanStaked() public {
        uint256 unstakeAmount = 150 * 10 ** 18;

        address staker = address(1);

        mockToken.mint(staker, stakeAmount1);
        vm.startPrank(staker);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        vm.stopPrank();

        vm.startPrank(staker);
        vm.expectRevert("Insufficient stake");
        erc900.unstake(unstakeAmount, "");
        vm.stopPrank();

        uint256 remainingStake = erc900.totalStakedFor(staker);
        assertEq(remainingStake, stakeAmount1, "Staked amount should remain unchanged after failed unstake attempt");
    }
    function testStakeEventEmission() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        vm.expectEmit(true, true, true, true);
        emit Staked(staker1, stakeAmount1, stakeAmount1, "");

        erc900.stake(stakeAmount1, "");

        vm.stopPrank();
    }

    function testUnstakeEventEmission() public {
        uint256 unstakeAmount = 50 * 10 ** 18; // 50 tokens

        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        vm.stopPrank();

        vm.startPrank(staker1);
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
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        vm.stopPrank();

        vm.startPrank(staker1);
        vm.expectRevert("Unstake amount must be positive");
        erc900.unstake(zeroUnstakeAmount, "");
        vm.stopPrank();
    }

    function testStakeWithInsufficientApproval() public {
        uint256 insufficientApprovalAmount = 50 * 10 ** 18; // 50 tokens, less than the stake amount

        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), insufficientApprovalAmount);
        vm.expectRevert();
        erc900.stake(stakeAmount1, "");
        vm.stopPrank();
    }
    function testUnstakeWithoutStaking() public {
        uint256 unstakeAmount = 50 * 10 ** 18; // Attempting to unstake 50 tokens
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

        uint256 totalStaked = stakeAmount2;
        assertEq(erc900.totalStaked(), totalStaked, "Total staked amount mismatch after unstaking");

        assertTrue(erc900.isStaker(staker2), "Staker2 should still be in the stakers list");
        assertFalse(erc900.isStaker(staker1), "Staker1 should not be in the stakers list after unstaking");
        assertFalse(erc900.isStaker(staker3), "Staker3 should not be in the stakers list after unstaking");
    }
    function testStakeForAnotherUser() public {
        address beneficiary = address(4);

        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);

        erc900.stakeFor(beneficiary, stakeAmount1, "");
        assertEq(
            erc900.totalStakedFor(beneficiary),
            stakeAmount1,
            "Beneficiary's staked amount should match the staked amount"
        );

        assertEq(erc900.totalStakedFor(staker1), 0, "Staker1's staked amount should be zero after staking for another");
        assertTrue(erc900.isStaker(beneficiary), "Beneficiary should be registered as a staker");
        assertFalse(erc900.isStaker(staker1), "Staker1 should not be registered as a staker after staking for another");
        vm.stopPrank();
    }
    function testStakeForZeroAddress() public {
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);

        vm.expectRevert("Cannot stake for zero address");
        erc900.stakeFor(address(0), stakeAmount1, "");

        vm.stopPrank();
    }
    function testUnstakeWithZeroBalanceAfterUnstaking() public {
        uint256 unstakeAmount = 10 * 1e18;
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        erc900.unstake(stakeAmount1, "");

        vm.expectRevert("Insufficient stake");
        erc900.unstake(unstakeAmount, "");
        vm.stopPrank();
    }

    function testStakeHistoryRecording() public {
        uint256 initialStakeAmount = 50 * 10 ** 18; // 50 tokens
        uint256 additionalStakeAmount = 30 * 10 ** 18; // 30 tokens
        uint256 totalStakeAmount = initialStakeAmount + additionalStakeAmount;

        // Mint and approve tokens for staking
        mockToken.mint(staker1, totalStakeAmount);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), totalStakeAmount);

        // First staking action
        erc900.stake(initialStakeAmount, "");
        uint256 initialTimestamp = block.timestamp;
        (uint256 valueAfterFirstStake, uint256 timestampAfterFirstStake) = erc900.getStakeHistory(staker1, 0);
        assertEq(
            valueAfterFirstStake,
            initialStakeAmount,
            "Initial stake amount should be recorded correctly in the history"
        );
        assertEq(
            timestampAfterFirstStake,
            initialTimestamp,
            "Timestamp after first stake should be recorded correctly"
        );

        // Second staking action
        vm.warp(block.timestamp + 1 days); // Fast forward time by 1 day
        erc900.stake(additionalStakeAmount, "");
        uint256 secondTimestamp = block.timestamp;
        (uint256 valueAfterSecondStake, uint256 timestampAfterSecondStake) = erc900.getStakeHistory(staker1, 1);
        assertEq(
            valueAfterSecondStake,
            totalStakeAmount,
            "Total stake amount after second stake should be recorded correctly in the history"
        );
        assertEq(
            timestampAfterSecondStake,
            secondTimestamp,
            "Timestamp after second stake should be recorded correctly"
        );

        vm.stopPrank();
    }
    function testUnstakeHistoryRecording() public {
        uint256 unstakeAmount = 50 * 10 ** 18;
        mockToken.mint(staker1, stakeAmount1);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");

        vm.warp(block.timestamp + 1 days);
        erc900.unstake(unstakeAmount, "");
        uint256 timestampAfterUnstake = block.timestamp;

        (uint256 valueAfterUnstake, uint256 timestampRecordedAfterUnstake) = erc900.getStakeHistory(staker1, 1);
        assertEq(
            valueAfterUnstake,
            stakeAmount1 - unstakeAmount,
            "Unstake amount should be recorded correctly in the history"
        );
        assertEq(
            timestampRecordedAfterUnstake,
            timestampAfterUnstake,
            "Timestamp after unstake should be recorded correctly"
        );

        vm.stopPrank();
    }
    function testHistorySupportFunctionality() public view {
        assertTrue(erc900.supportsHistory(), "The contract should support history tracking.");
    }
    function testHistoryIntegrityOverTime() public {
        mockToken.mint(staker1, stakeAmount1 + stakeAmount2 + stakeAmount3);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1 + stakeAmount2 + stakeAmount3);

        erc900.stake(stakeAmount1, "");
        uint256 firstTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1 days);

        erc900.stake(stakeAmount2, "");
        uint256 secondTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1 days);

        erc900.stake(stakeAmount3, "");
        uint256 thirdTimestamp = block.timestamp;

        (uint256 valueAfterFirstStake, uint256 timestampAfterFirstStake) = erc900.getStakeHistory(staker1, 0);
        (uint256 valueAfterSecondStake, uint256 timestampAfterSecondStake) = erc900.getStakeHistory(staker1, 1);
        (uint256 valueAfterThirdStake, uint256 timestampAfterThirdStake) = erc900.getStakeHistory(staker1, 2);

        assertEq(valueAfterFirstStake, stakeAmount1, "First stake amount should be recorded correctly in the history");
        assertEq(timestampAfterFirstStake, firstTimestamp, "Timestamp after first stake should be recorded correctly");

        assertEq(
            valueAfterSecondStake,
            stakeAmount1 + stakeAmount2,
            "Second stake amount should be recorded correctly in the history"
        );
        assertEq(
            timestampAfterSecondStake,
            secondTimestamp,
            "Timestamp after second stake should be recorded correctly"
        );

        assertEq(
            valueAfterThirdStake,
            stakeAmount1 + stakeAmount2 + stakeAmount3,
            "Third stake amount should be recorded correctly in the history"
        );
        assertEq(timestampAfterThirdStake, thirdTimestamp, "Timestamp after third stake should be recorded correctly");

        vm.stopPrank();
    }

    function testStakeHistoryAfterZeroingStake() public {
        uint256 newStake = 50 * 10 ** 18;

        mockToken.mint(staker1, stakeAmount1 + newStake);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1 + newStake);

        erc900.stake(stakeAmount1, "");
        uint256 initialTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1 days);
        erc900.unstake(stakeAmount1, "");
        vm.warp(block.timestamp + 1 days);

        erc900.stake(newStake, "");
        uint256 newStakeTimestamp = block.timestamp;

        (uint256 valueAfterInitialStake, uint256 timestampAfterInitialStake) = erc900.getStakeHistory(staker1, 0);
        (uint256 valueAfterNewStake, uint256 timestampAfterNewStake) = erc900.getStakeHistory(staker1, 2);

        assertEq(
            valueAfterInitialStake,
            stakeAmount1,
            "Initial stake amount should be recorded correctly in the history"
        );
        assertEq(
            timestampAfterInitialStake,
            initialTimestamp,
            "Timestamp after initial stake should be recorded correctly"
        );

        assertEq(valueAfterNewStake, newStake, "New stake amount should be recorded correctly in the history");
        assertEq(timestampAfterNewStake, newStakeTimestamp, "Timestamp after new stake should be recorded correctly");

        vm.stopPrank();
    }

    function testGetStakeHistory() public {
        mockToken.mint(staker1, stakeAmount1 + stakeAmount2);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1 + stakeAmount2);
        erc900.stake(stakeAmount1, "");
        uint256 firstTimestamp = block.timestamp;
        vm.warp(block.timestamp + 1 days);
        erc900.stake(stakeAmount2, "");
        uint256 secondTimestamp = block.timestamp;
        vm.stopPrank();

        (uint256 valueAtFirstCheckpoint, uint256 timestampAtFirstCheckpoint) = erc900.getStakeHistory(staker1, 0);
        (uint256 valueAtSecondCheckpoint, uint256 timestampAtSecondCheckpoint) = erc900.getStakeHistory(staker1, 1);

        assertEq(valueAtFirstCheckpoint, stakeAmount1, "Stake at first checkpoint should match the initial stake");
        assertEq(
            timestampAtFirstCheckpoint,
            firstTimestamp,
            "Timestamp at first checkpoint should match the initial staking time"
        );
        assertEq(
            valueAtSecondCheckpoint,
            stakeAmount1 + stakeAmount2,
            "Stake at second checkpoint should match the total stake"
        );
        assertEq(
            timestampAtSecondCheckpoint,
            secondTimestamp,
            "Timestamp at second checkpoint should match the second staking time"
        );
    }

    function testGetTotalStakeHistory() public {
        mockToken.mint(staker1, stakeAmount1);
        mockToken.mint(staker2, stakeAmount2);
        vm.startPrank(staker1);
        mockToken.approve(address(erc900), stakeAmount1);
        erc900.stake(stakeAmount1, "");
        uint256 firstTimestamp = block.timestamp;
        vm.stopPrank();
        vm.warp(block.timestamp + 1 days);
        vm.startPrank(staker2);
        mockToken.approve(address(erc900), stakeAmount2);
        erc900.stake(stakeAmount2, "");
        uint256 secondTimestamp = block.timestamp;
        vm.stopPrank();

        (uint256 totalValueAtFirstCheckpoint, uint256 totalTimestampAtFirstCheckpoint) = erc900.getTotalStakeHistory(0);
        (uint256 totalValueAtSecondCheckpoint, uint256 totalTimestampAtSecondCheckpoint) = erc900.getTotalStakeHistory(
            1
        );

        assertEq(
            totalValueAtFirstCheckpoint,
            stakeAmount1,
            "Total stake at first checkpoint should match the first staker's amount"
        );
        assertEq(
            totalTimestampAtFirstCheckpoint,
            firstTimestamp,
            "Total timestamp at first checkpoint should match the first staking time"
        );
        assertEq(
            totalValueAtSecondCheckpoint,
            stakeAmount1 + stakeAmount2,
            "Total stake at second checkpoint should match the combined stake"
        );
        assertEq(
            totalTimestampAtSecondCheckpoint,
            secondTimestamp,
            "Total timestamp at second checkpoint should match the last staking time"
        );
    }
}
