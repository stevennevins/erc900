// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {DelegationProxy} from "../src/DelegationProxy.sol";
import {MockVotes} from "./mocks/MockVotes.sol";

contract DelegationProxyTest is Test {
    address internal mockVotes;

    function setUp() public {
        mockVotes = address(new MockVotes());
    }

    function testDeployCost() public {
        vm.prank(mockVotes);
        new DelegationProxy(address(0));
    }
}
