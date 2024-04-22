// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DelegationHolder {
    constructor(address _token, address _delegatee) {
        IVotes(msg.sender).delegate(_delegatee);
        // IERC20(_token).approve(msg.sender, type(uint256).max);
    }
}
