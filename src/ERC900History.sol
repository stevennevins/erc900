// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Checkpoints} from "../lib/openzeppelin-contracts/contracts/utils/structs/Checkpoints.sol";
import {Time} from "../lib/openzeppelin-contracts/contracts/utils/types/Time.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERC900} from "./IERC900.sol";

contract ERC900History is IERC900 {
    using SafeERC20 for IERC20;
    using Checkpoints for Checkpoints.Trace208;

    address public token;

    mapping(address => Checkpoints.Trace208) internal _stakeHistories;
    Checkpoints.Trace208 internal _totalStakeHistory;
    EnumerableSet.AddressSet internal _stakers;

    constructor(address _token) {
        token = _token;
    }

    function stake(uint256 amount, bytes calldata data) external {
        stakeFor(msg.sender, amount, data);
    }

    function stakeFor(address beneficiary, uint256 amount, bytes calldata data) public {
        require(amount > 0, "Stake amount must be positive");
        require(beneficiary != address(0), "Cannot stake for zero address");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _stakeHistories[beneficiary].push(Time.timestamp(), uint208(_stakeHistories[beneficiary].latest() + amount));
        _totalStakeHistory.push(Time.timestamp(), uint208(_totalStakeHistory.latest() + amount));
        EnumerableSet.add(_stakers, beneficiary);

        emit Staked(beneficiary, amount, _stakeHistories[beneficiary].latest(), data);
    }

    function unstake(uint256 amount, bytes calldata data) external {
        require(amount > 0, "Unstake amount must be positive");
        uint256 currentStake = _stakeHistories[msg.sender].latest();
        require(currentStake >= amount, "Insufficient stake");

        IERC20(token).safeTransfer(msg.sender, amount);
        _stakeHistories[msg.sender].push(Time.timestamp(), uint208(currentStake - amount));
        _totalStakeHistory.push(Time.timestamp(), uint208(_totalStakeHistory.latest() - amount));

        if (_stakeHistories[msg.sender].latest() == 0) {
            EnumerableSet.remove(_stakers, msg.sender);
        }

        emit Unstaked(msg.sender, amount, _stakeHistories[msg.sender].latest(), data);
    }

    function totalStakedFor(address addr) external view returns (uint256) {
        return _stakeHistories[addr].latest();
    }

    function totalStaked() external view returns (uint256) {
        return _totalStakeHistory.latest();
    }

    function stakers() external view returns (address[] memory) {
        return EnumerableSet.values(_stakers);
    }

    function isStaker(address user) external view returns (bool) {
        return EnumerableSet.contains(_stakers, user);
    }

    function supportsHistory() external pure override returns (bool) {
        return true;
    }

    function getStakeHistory(address addr, uint32 checkpointId) external view returns (uint256, uint256) {
        /// TODO: Need to implement where it's by timestamp and not index #
        Checkpoints.Checkpoint208 memory cp = _stakeHistories[addr].at(checkpointId);
        return (cp._value, cp._key);
    }

    function getTotalStakeHistory(uint32 checkpointId) external view returns (uint256, uint256) {
        /// TODO: Need to implement where it's by timestamp and not index #
        Checkpoints.Checkpoint208 memory cp = _totalStakeHistory.at(checkpointId);
        return (cp._value, cp._key);
    }
}
