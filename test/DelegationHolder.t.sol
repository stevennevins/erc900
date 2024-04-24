// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DelegationHolder} from "../src/DelegationHolder.sol";
import {MockVotes} from "./mocks/MockVotes.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract DelegationHolderTest is Test {
    address internal mockToken;
    address internal mockVotes;

    function setUp() public {
        mockVotes = address(new MockVotes());
        mockToken = address(new MockERC20("", ""));
    }

    function testDeployCost() public {
        vm.prank(mockVotes);
        new DelegationHolder(address(0));
    }
}
