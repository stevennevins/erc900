// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IVotes} from "../lib/openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

/// @title Delegation Proxy
/// @notice This contract is used to delegate voting power of a token holder to another address upon deployment.
contract DelegationProxy {
    /// @notice Creates a new delegation proxy which delegates the sender's voting power to the specified delegatee.
    /// @param _delegatee The address to which the voting power is delegated.
    constructor(address _delegatee) {
        IVotes(msg.sender).delegate(_delegatee);
    }
}
