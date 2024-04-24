// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {ERC900Votes} from "../src/ERC900Votes.sol";

contract ERC900VotesTest is Test {
    ERC900Votes internal erc900Votes;
    MockERC20 internal mockToken;

    address internal staker1 = address(1);
    address internal staker2 = address(2);
    address internal staker3 = address(3);
    uint256 internal stakeAmount1 = 100 * 10 ** 18;
    uint256 internal stakeAmount2 = 150 * 10 ** 18;
    uint256 internal stakeAmount3 = 200 * 10 ** 18;

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        erc900Votes = new ERC900Votes(address(mockToken), "ERC900Votes", "1");
    }

    function testStakeTokens() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900Votes), stakeAmount1);
        erc900Votes.stake(stakeAmount1, "");
        erc900Votes.delegate(staker1);
        vm.stopPrank();

        assertEq(erc900Votes.totalStakedFor(staker1), stakeAmount1, "Staked amount should match");
        assertEq(erc900Votes.totalStaked(), stakeAmount1, "Total staked should match");
        assertEq(erc900Votes.getVotes(staker1), stakeAmount1, "Voting units for staker1 should match staked amount");
    }

    function testStakeAndUnstakeTokens() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900Votes), stakeAmount1);
        erc900Votes.stake(stakeAmount1, "");
        erc900Votes.unstake(stakeAmount1, "");
        vm.stopPrank();

        assertEq(erc900Votes.totalStakedFor(staker1), 0, "Staked amount should match");
        assertEq(erc900Votes.totalStaked(), 0, "Total staked should match");
        assertEq(erc900Votes.getVotes(staker1), 0, "Voting units for staker1 should match staked amount");
    }

    function testStakeAndTransferDeleation() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900Votes), stakeAmount1);
        erc900Votes.stake(stakeAmount1, "");
        erc900Votes.transferDelegation(staker2, stakeAmount1);
        vm.stopPrank();

        assertEq(erc900Votes.totalStakedFor(staker1), stakeAmount1, "Staked amount should match");
        assertEq(erc900Votes.totalStaked(), stakeAmount1, "Total staked should match");
        assertEq(erc900Votes.getVotes(staker2), stakeAmount1, "Voting units for staker2 should match staked amount");
    }

    function testStakeAndTransferDeleationAndReclaim() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900Votes), stakeAmount1);
        erc900Votes.stake(stakeAmount1, "");
        erc900Votes.transferDelegation(staker2, stakeAmount1);
        erc900Votes.reclaimVotingPower(staker2, stakeAmount1);
        vm.stopPrank();

        assertEq(erc900Votes.totalStakedFor(staker1), stakeAmount1, "Staked amount should match");
        assertEq(erc900Votes.totalStaked(), stakeAmount1, "Total staked should match");
        assertEq(erc900Votes.getVotes(staker2), 0, "Voting units for staker1 should match staked amount");
        assertEq(erc900Votes.getVotes(staker1), stakeAmount1, "Voting units for staker2 should match staked amount");
    }

    function testStakeAndTransferDeleationAndReclaimAndUnstake() public {
        mockToken.mint(staker1, stakeAmount1);

        vm.startPrank(staker1);
        mockToken.approve(address(erc900Votes), stakeAmount1);
        erc900Votes.stake(stakeAmount1, "");
        erc900Votes.transferDelegation(staker2, stakeAmount1);
        erc900Votes.reclaimVotingPower(staker2, stakeAmount1);
        erc900Votes.unstake(stakeAmount1, "");
        vm.stopPrank();

        assertEq(erc900Votes.totalStakedFor(staker1), 0, "Staked amount should match");
        assertEq(erc900Votes.totalStaked(), 0, "Total staked should match");
        assertEq(erc900Votes.getVotes(staker2), 0, "Voting units for staker1 should match staked amount");
        assertEq(erc900Votes.getVotes(staker1), 0, "Voting units for staker2 should match staked amount");
    }
}
