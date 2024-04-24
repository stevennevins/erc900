// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Votes} from "@openzeppelin/contracts/governance/utils/Votes.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC900} from "./ERC900.sol";
import {DelegationHolder} from "./DelegationHolder.sol";
import {Test, console} from "forge-std/Test.sol";

contract ERC900Votes is ERC900, Votes {
    /// Owner -> DelegateProxy -> Amount
    mapping(address => mapping(address => uint256)) public encumberedVotes;
    mapping(address => uint256) public encumberedBalanceOf;

    constructor(address _token, string memory _name, string memory _version) ERC900(_token) EIP712(_name, _version) {}

    function transferDelegation(address _to, uint256 _amount) external {
        address delegationProxy = _getDelegationProxy(_to);
        _encumber(msg.sender, delegationProxy, _amount);
    }

    function reclaimVotingPower(address _from, uint256 _amount) external {
        address delegationProxy = _getDelegationProxy(_from);
        _reclaim(delegationProxy, msg.sender, _amount);
    }

    function _getDelegationProxy(address _delegatee) internal returns (address _delegationHolder) {
        bytes32 salt = keccak256(abi.encodePacked(token, _delegatee));
        bytes memory constructorArgs = abi.encode(_delegatee);
        bytes memory bytecode = bytes.concat(type(DelegationHolder).creationCode, constructorArgs);
        address delegate = Create2.computeAddress(salt, keccak256(bytecode));
        if (delegate.code.length == 0) {
            Create2.deploy(0, salt, bytecode);
        }

        return delegate;
    }

    function _getVotingUnits(address _account) internal view virtual override returns (uint256) {
        return _stakes[_account] - encumberedBalanceOf[_account];
    }

    function _encumber(address _from, address _to, uint256 _amount) internal {
        // TODO: Confirm this isn't needed
        // require(_getVotingUnits(_from) - encumberedBalanceOf[_from] > _amount, "Insufficient Vote Balance");
        encumberedVotes[_from][_to] += _amount;
        encumberedBalanceOf[_from] += _amount;
        _transferVotingUnits(_from, _to, _amount);
    }

    function _reclaim(address _from, address _to, uint256 _amount) internal {
        encumberedVotes[_to][_from] -= _amount;
        encumberedBalanceOf[_to] -= _amount;
        _transferVotingUnits(_from, _to, _amount);
    }

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

    function _unstake(address _user, uint256 _amount, bytes memory _data) internal virtual override {
        require(_amount <= _getVotingUnits(_user), "Amount exceeds undelegated balance");
        _transferVotingUnits(_user, address(0), _amount);
        super._unstake(_user, _amount, _data);
    }
}
