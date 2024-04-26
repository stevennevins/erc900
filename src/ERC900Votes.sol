// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC900} from "./ERC900.sol";
import {DelegationProxy} from "./DelegationProxy.sol";

/// @title ERC900Votes Contract
/// @notice This contract extends the ERC900 staking standard with voting capabilities, integrating OpenZeppelin's Votes and EIP712 for secure voting.
/// @dev The contract uses a delegation system where votes can be encumbered (locked) when delegated to another address.
/// This allows for the creation of a flexible and secure voting system on top of the staking functionality provided by ERC900.
contract ERC900Votes is ERC900, Votes {
    /// @notice Tracks the amount of votes encumbered by delegation for each owner to each delegate proxy.
    /// @dev Key1: Owner's address, Key2: Delegate proxy's address, Value: Amount of encumbered votes.
    mapping(address => mapping(address => uint256)) public encumberedVotes;

    /// @notice Tracks the total amount of votes encumbered by an owner due to delegation.
    /// @dev Key: Owner's address, Value: Total amount of encumbered votes.
    mapping(address => uint256) public encumberedBalanceOf;

    /// @notice Initializes a new ERC900Votes contract with specified token, name, and version for EIP712 domain.
    /// @param _token The address of the token used for staking.
    /// @param _name The name used in the EIP712 domain.
    /// @param _version The version used in the EIP712 domain.
    constructor(address _token, string memory _name, string memory _version) ERC900(_token) EIP712(_name, _version) {}

    /// @notice Transfers delegation from the caller to another address by encumbering the specified amount of votes.
    /// @param _to The address to which the delegation is transferred.
    /// @param _amount The amount of votes to delegate.
    function transferDelegation(address _to, uint256 _amount) external {
        address delegationProxy = _getDelegationProxy(_to);
        _encumber(msg.sender, delegationProxy, _amount);
    }

    /// @notice Reclaims delegated voting power from a delegate by unencumbering the specified amount of votes.
    /// @param _from The address from which the voting power is reclaimed.
    /// @param _amount The amount of votes to reclaim.
    function reclaimVotingPower(address _from, uint256 _amount) external {
        address delegationProxy = _getDelegationProxy(_from);
        _reclaim(delegationProxy, msg.sender, _amount);
    }

    /// @dev Retrieves or creates a delegation proxy for a given delegatee using deterministic deployment.
    /// @param _delegatee The address of the delegatee.
    /// @return _delegationHolder The address of the delegation proxy.
    function _getDelegationProxy(address _delegatee) internal returns (address _delegationHolder) {
        bytes32 salt = keccak256(abi.encodePacked(token, _delegatee));
        bytes memory constructorArgs = abi.encode(_delegatee);
        bytes memory bytecode = bytes.concat(type(DelegationProxy).creationCode, constructorArgs);
        address delegate = Create2.computeAddress(salt, keccak256(bytecode));
        if (delegate.code.length == 0) {
            Create2.deploy(0, salt, bytecode);
        }

        return delegate;
    }

    /// @dev Calculates the voting units available to an account, considering encumbered votes.
    /// @param _account The address of the account.
    /// @return The number of voting units available.
    function _getVotingUnits(address _account) internal view virtual override returns (uint256) {
        return _stakes[_account] - encumberedBalanceOf[_account];
    }

    /// @dev Encumbers a specified amount of votes from one address to another
    /// @param _from The address from which votes are encumbered.
    /// @param _to The address to which votes are encumbered.
    /// @param _amount The amount of votes to encumber.
    function _encumber(address _from, address _to, uint256 _amount) internal {
        encumberedVotes[_from][_to] += _amount;
        encumberedBalanceOf[_from] += _amount;
        _transferVotingUnits(_from, _to, _amount);
    }

    /// @dev Reclaims a specified amount of encumbered votes from one address to another
    /// @param _from The address from which votes are reclaimed.
    /// @param _to The address to which votes are reclaimed.
    /// @param _amount The amount of votes to reclaim.
    function _reclaim(address _from, address _to, uint256 _amount) internal {
        encumberedVotes[_to][_from] -= _amount;
        encumberedBalanceOf[_to] -= _amount;
        _transferVotingUnits(_from, _to, _amount);
    }

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
        if (delegates(_beneficiary) == address(0)) {
            _delegate(_beneficiary, _beneficiary);
        }
        super._stakeFor(_payer, _beneficiary, _amount, _data);
        _transferVotingUnits(address(0), _beneficiary, _amount);
    }

    /// @dev Unstakes tokens, ensuring the amount does not exceed the undelegated balance.
    /// @param _user The user unstaking tokens.
    /// @param _amount The amount of tokens to unstake.
    /// @param _data Additional data with no specified format.
    function _unstake(address _user, uint256 _amount, bytes memory _data) internal virtual override {
        require(_amount <= _getVotingUnits(_user), "Amount exceeds undelegated balance");
        _transferVotingUnits(_user, address(0), _amount);
        super._unstake(_user, _amount, _data);
    }
}
