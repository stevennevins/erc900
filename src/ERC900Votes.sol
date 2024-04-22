// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC900} from "./ERC900.sol";

contract ERC900Votes is ERC900, Votes {
    constructor(address _token, string memory _name, string memory _version) ERC900(_token) EIP712(_name, _version) {}

    /// TODO: Need to track deposits and withdrawals for stakers into the delegatee pools
    function stakeAndDelegate() external {}
    /*
      Flows include:
       - I should be able to stake and not specify a delegate
            - My stake should be delegated to myself or is undelegated
        - I should be able to delegate portions of my stake to other accounts
        - I should be able to transfer my delegated stake to new accounts
        - I should be able to remove my delegated stake from accounts
        - I should be able to unstake and remove my delegated stake
        -
        - With EIP3074 on the horizon it probably makes sense to keep each action atomic

     */

    /// TODO: Needs to undelegate from staker - Should be automatic
    function unstake() external {
        /// TODO: When Unstaking if unstaked all then delete delegation

    }

    /// TODO: Should move tokens between pools
    /// TODO: Needs to make sure pool exists
    function transferDelegation(address to, uint256 amount) external {
        _transferVotingUnits(msg.sender, to, amount);
    }

    function transferDelegationFrom(address from, address to, uint256 amount) external {
        /// TODO: Check that from is a pool controlled by from
        _transferVotingUnits(from, to, amount);
    }

    function _getVotingUnits(address delegatee) internal view virtual override returns (uint256) {
        /// TODO: Get delegatee's pool
        /// TODO: Get balance of delegatee's pool
    }
}
