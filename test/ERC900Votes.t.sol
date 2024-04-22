// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract DelegationHolderTest is Test {
    address internal mockToken;

    function setUp() public {
        mockToken = address(new MockERC20("", ""));
    }

}