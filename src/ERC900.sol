// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC900.sol";

contract ERC900 is IERC900{
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address private _token;

    mapping(address => uint256) private _stakes;
    EnumerableSet.AddressSet private _stakers;

    uint256 private _totalStaked;

    constructor(address token_) {
        _token = token_;
    }

    function stake(uint256 amount, bytes calldata data) external override {
        _stakeFor(msg.sender, msg.sender, amount, data);
    }

    function stakeFor(address user, uint256 amount, bytes calldata data) external override {
        _stakeFor(msg.sender, user, amount, data);
    }

    function unstake(uint256 amount, bytes calldata data) external override {
        _unstake(msg.sender, amount, data);
    }

    function totalStakedFor(address user) external view override returns (uint256) {
        return _stakes[user];
    }

    function totalStaked() external view override returns (uint256) {
        return _totalStaked;
    }

    function isStaker(address user) external view returns (bool) {
        return _stakers.contains(user);
    }

    function token() external view returns (address){
        return _token;
    }

    function supportsHistory() external pure override returns (bool) {
        return true;
    }

    function _stakeFor(address payer, address user, uint256 amount, bytes memory data) internal {
        require(amount > 0, "Stake amount must be positive");
        require(user != address(0), "Cannot stake for zero address");

        _totalStaked += amount;
        _stakes[user] += amount;
        _stakers.add(user);

        emit Staked(user, amount, _stakes[user], data);

        IERC20(_token).safeTransferFrom(payer, address(this), amount);
    }

    function _unstake(address user, uint256 amount, bytes memory data) internal {
        require(amount > 0, "Unstake amount must be positive");
        require(_stakes[user] >= amount, "Insufficient stake");

        _stakes[user] -= amount;
        _totalStaked -= amount;

        if (_stakes[user] == 0) {
            _stakers.remove(user);
        }

        emit Unstaked(user, amount, _stakes[user], data);

        IERC20(_token).safeTransfer(user, amount);
    }
}

