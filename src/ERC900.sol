// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC900} from "./IERC900.sol";

contract ERC900 is IERC900 {
    using SafeERC20 for IERC20;

    /// @inheritdoc IERC900
    address public token;

    /// @notice Mapping of user addresses to their staked amounts
    mapping(address => uint256) internal _stakes;

    /// @notice Total amount of tokens staked in the contract
    uint256 internal _totalStaked;

    /// @notice Initializes the contract with the staking token address
    /// @param _token Address of the ERC20 token used for staking
    constructor(address _token) {
        token = _token;
    }

    /// @inheritdoc IERC900
    function stake(uint256 amount, bytes calldata data) external override {
        _stakeFor(msg.sender, msg.sender, amount, data);
    }

    /// @inheritdoc IERC900
    function stakeFor(address user, uint256 amount, bytes calldata data) external override {
        _stakeFor(msg.sender, user, amount, data);
    }

    /// @inheritdoc IERC900
    function unstake(uint256 amount, bytes calldata data) external override {
        _unstake(msg.sender, amount, data);
    }

    /// @inheritdoc IERC900
    function totalStakedFor(address user) external view override returns (uint256) {
        return _stakes[user];
    }

    /// @inheritdoc IERC900
    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    /// @inheritdoc IERC900
    function supportsHistory() external pure override returns (bool) {
        return true;
    }

    /// @notice Internal function to handle staking logic for a user
    /// @param payer Address of the account transferring the tokens
    /// @param user Address of the user for whom tokens are being staked
    /// @param amount Amount of tokens to stake
    /// @param data Additional data with no specified format
    function _stakeFor(address payer, address user, uint256 amount, bytes memory data) internal virtual {
        require(amount > 0, "Stake amount must be positive");
        require(user != address(0), "Cannot stake for zero address");

        _totalStaked += amount;
        _stakes[user] += amount;

        emit Staked(user, amount, _stakes[user], data);

        IERC20(token).safeTransferFrom(payer, address(this), amount);
    }

    /// @notice Internal function to handle unstaking logic for a user
    /// @param user Address of the user unstaking tokens
    /// @param amount Amount of tokens to unstake
    /// @param data Additional data with no specified format
    function _unstake(address user, uint256 amount, bytes memory data) internal virtual {
        require(amount > 0, "Unstake amount must be positive");
        require(_stakes[user] >= amount, "Insufficient stake");

        _stakes[user] -= amount;
        _totalStaked -= amount;

        emit Unstaked(user, amount, _stakes[user], data);

        IERC20(token).safeTransfer(user, amount);
    }
}
