// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC900History} from "../src/ERC900History.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract ERC900Test is Test {
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    ERC900History internal erc900;
    MockERC20 internal mockToken;

    address internal staker1 = address(1);
    address internal staker2 = address(2);
    address internal staker3 = address(3);
    uint256 internal stakeAmount1 = 100 * 10 ** 18;
    uint256 internal stakeAmount2 = 150 * 10 ** 18;
    uint256 internal stakeAmount3 = 200 * 10 ** 18;

    function setUp() public {
        mockToken = new MockERC20("Mock Token", "MTK");
        erc900 = new ERC900History(address(mockToken));
    }
}
