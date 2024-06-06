// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC900} from "./ERC900.sol";
import {Slashable} from "./Slashable.sol";

contract ERC900Slashable is ERC900, Slashable {
    constructor(address _token) ERC900(_token) {}

    /// @dev Stakes tokens for a beneficiary, automatically delegating the voting units to the beneficiary if not already delegated.
    /// @param _payer The address paying for the stake.
    /// @param _beneficiary The beneficiary of the stake.
    /// @param _amount The amount of tokens to stake.
    /// @param _data Additional data with no specified format.
    function _stakeFor(
        address _payer,
        address _beneficiary,
        uint256 _amount,
        bytes memory _data
    ) internal virtual override {
        super._stakeFor(_payer, _beneficiary, _amount, _data);
    }

    /// @dev Unstakes tokens, ensuring the amount does not exceed the undelegated balance.
    /// @param _user The user unstaking tokens.
    /// @param _amount The amount of tokens to unstake.
    /// @param _data Additional data with no specified format.
    function _unstake(address _user, uint256 _amount, bytes memory _data) internal virtual override {
        super._unstake(_user, _amount, _data);
    }
}
