// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IVotes} from "../lib/openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

contract DelegationHolder {
    constructor(address _delegatee) {
        IVotes(msg.sender).delegate(_delegatee);
    }
}
