// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DelegationHolder} from "../src/DelegationHolder.sol";
import {MockVotes} from "./mocks/MockVotes.sol";

contract DelegationHolderTest is Test {
    address internal mockVotes;

    function setUp() public {
        mockVotes = address(new MockVotes());
    }

    function testDeployCost() public {
        vm.prank(mockVotes);
        new DelegationHolder(address(0));
    }
}
