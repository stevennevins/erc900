pragma solidity 0.5.17;


import {Checkpoint} from "openzeppelin-contracts/";
import "./lib/os/SafeERC20.sol";
import "./lib/os/TimeHelpers.sol";

import "./locking/ILockable.sol";
import "./locking/ILockManager.sol";

import "./IERC900History.sol";


struct Lock {
    uint256 amount;
    uint256 allowance; // A lock is considered active when its allowance is greater than zero, and the allowance is always greater than or equal to amount
}

struct Account {
    mapping (address => Lock) locks; // Mapping of lock manager => lock info
    uint256 totalLocked;
    Checkpointing.History stakedHistory;
}

contract Staking is IERC900History, ILockable, TimeHelpers {
    using Checkpointing for Checkpointing.History;
    using SafeERC20 for IERC20;

    string private constant ERROR_AMOUNT_ZERO = "STAKING_AMOUNT_ZERO";
    string private constant ERROR_TOKEN_TRANSFER = "STAKING_TOKEN_TRANSFER_FAIL";
    string private constant ERROR_TOKEN_DEPOSIT = "STAKING_TOKEN_DEPOSIT_FAIL";
    string private constant ERROR_WRONG_TOKEN = "STAKING_WRONG_TOKEN";
    string private constant ERROR_NOT_ENOUGH_BALANCE = "STAKING_NOT_ENOUGH_BALANCE";
    string private constant ERROR_NOT_ENOUGH_ALLOWANCE = "STAKING_NOT_ENOUGH_ALLOWANCE";
    string private constant ERROR_ALLOWANCE_ZERO = "STAKING_ALLOWANCE_ZERO";
    string private constant ERROR_LOCK_ALREADY_EXISTS = "STAKING_LOCK_ALREADY_EXISTS";
    string private constant ERROR_LOCK_DOES_NOT_EXIST = "STAKING_LOCK_DOES_NOT_EXIST";
    string private constant ERROR_NOT_ENOUGH_LOCK = "STAKING_NOT_ENOUGH_LOCK";
    string private constant ERROR_CANNOT_UNLOCK = "STAKING_CANNOT_UNLOCK";
    string private constant ERROR_CANNOT_CHANGE_ALLOWANCE = "STAKING_CANNOT_CHANGE_ALLOWANCE";
    string private constant ERROR_BLOCKNUMBER_TOO_BIG = "STAKING_BLOCKNUMBER_TOO_BIG";


    IERC20 public token;
    mapping (address => Account) internal accounts;
    Checkpointing.History internal totalStakedHistory;

    /**
     * @notice Initialize Staking app with token `_token`
     * @param _token ERC20 token used for staking
     */
    constructor(IERC20 _token) public {
        token = _token;
    }

    function stake(uint256 _amount, bytes calldata _data) external {
        _stakeFor(msg.sender, msg.sender, _amount, _data);
    }

    function stakeFor(address _user, uint256 _amount, bytes calldata _data) external {
        _stakeFor(msg.sender, _user, _amount, _data);
    }

    function unstake(uint256 _amount, bytes calldata _data) external {
        // _unstake() expects the caller to do this check
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        _unstake(msg.sender, _amount, _data);
    }

    function allowManager(address _lockManager, uint256 _allowance, bytes calldata _data) external {
        _allowManager(_lockManager, _allowance, _data);
    }

    function increaseLockAllowance(address _lockManager, uint256 _allowance) external {
        Lock storage lock_ = accounts[msg.sender].locks[_lockManager];
        require(lock_.allowance > 0, ERROR_LOCK_DOES_NOT_EXIST);

        _increaseLockAllowance(_lockManager, lock_, _allowance);
    }

    function decreaseLockAllowance(address _user, address _lockManager, uint256 _allowance) external {
        require(msg.sender == _user || msg.sender == _lockManager, ERROR_CANNOT_CHANGE_ALLOWANCE);
        require(_allowance > 0, ERROR_AMOUNT_ZERO);

        Lock storage lock_ = accounts[_user].locks[_lockManager];
        uint256 newAllowance = lock_.allowance.sub(_allowance);
        require(newAllowance >= lock_.amount, ERROR_NOT_ENOUGH_ALLOWANCE);
        // unlockAndRemoveManager() must be used for this:
    }

    function _transferAndUnstake(address _from, address _to, uint256 _amount) internal {
        // transferring 0 staked tokens is invalid
        require(_amount > 0, ERROR_AMOUNT_ZERO);

        // update stake
        uint256 newStake = _modifyStakeBalance(_from, _amount, false);

        // checkpoint total supply
        _modifyTotalStaked(_amount, false);

        emit Unstaked(_from, _amount, newStake, new bytes(0));

        // transfer tokens
        require(token.safeTransfer(_to, _amount), ERROR_TOKEN_TRANSFER);
    }

    function _totalStakedFor(address _user) internal view returns (uint256) {
        // we assume it's not possible to stake in the future
        return accounts[_user].stakedHistory.getLast();
    }

    function _totalStaked() internal view returns (uint256) {
        // we assume it's not possible to stake in the future
        return totalStakedHistory.getLast();
    }

    function _unlockedBalanceOf(address _user) internal view returns (uint256) {
        return _totalStakedFor(_user).sub(_lockedBalanceOf(_user));
    }

    function _lockedBalanceOf(address _user) internal view returns (uint256) {
        return accounts[_user].totalLocked;
    }

    function _canUnlockUnsafe(address _sender, address _user, address _lockManager, uint256 _amount) internal view returns (bool) {
        Lock storage lock_ = accounts[_user].locks[_lockManager];
        require(lock_.allowance > 0, ERROR_LOCK_DOES_NOT_EXIST);
        require(lock_.amount >= _amount, ERROR_NOT_ENOUGH_LOCK);

        uint256 amount = _amount == 0 ? lock_.amount : _amount;

        // If the sender is the lock manager, unlocking is allowed
        if (_sender == _lockManager) {
            return true;
        }

        // If the sender is neither the lock manager nor the owner, unlocking is not allowed
        if (_sender != _user) {
            return false;
        }

        // The sender must be the user
        // Allow unlocking if the amount of locked tokens for the user has already been decreased to 0
        if (amount == 0) {
            return true;
        }

        // Otherwise, check whether the lock manager allows unlocking
        return ILockManager(_lockManager).canUnlock(_user, amount);
    }
}
