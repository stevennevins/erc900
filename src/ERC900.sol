// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {EnumerableSet} from "../lib/openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol";
import {IERC900} from "./IERC900.sol";

contract ERC900 is IERC900 {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public token;

    // Mapping to keep track of each staker's total stake.
    mapping(address => uint256) internal _stakes;
    // Mapping to keep track of the total staked amount.
    uint256 internal _totalStaked;

    EnumerableSet.AddressSet internal stakers;

    constructor(address _token) {
        token = _token;
    }

    function stake(uint256 amount, bytes calldata data) external {
        stakeFor(msg.sender, amount, data);
    }

    function stakeFor(address beneficiary, uint256 amount, bytes calldata data) public {
        require(amount > 0, "Stake amount must be positive");
        require(beneficiary != address(0), "Cannot stake for zero address");

        _stakes[beneficiary] = _stakes[beneficiary] + amount;
        _totalStaked = _totalStaked + amount;
        if (_stakes[beneficiary]==amount) {
            stakers.add(beneficiary);
        }

        emit Staked(beneficiary, amount, _stakes[beneficiary], data);

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    function unstake(uint256 amount, bytes calldata data) external {
        require(amount > 0, "Unstake amount must be positive");
        require(_stakes[msg.sender] >= amount, "Insufficient stake");


        _stakes[msg.sender] = _stakes[msg.sender] - amount;
        _totalStaked = _totalStaked - amount;
        if (_stakes[msg.sender] == 0) {
            stakers.remove(msg.sender);
        }

        emit Unstaked(msg.sender, amount, _stakes[msg.sender], data);

        IERC20(token).safeTransfer(msg.sender, amount);
    }

    function totalStakedFor(address addr) external view returns (uint256) {
        return _stakes[addr];
    }

    function totalStaked() external view returns (uint256) {
        return _totalStaked;
    }

    function supportsHistory() external pure override returns (bool) {
        return true;
    }

    function isStaker(address staker) external view returns (bool){
        return stakers.contains(staker);
    }
}

