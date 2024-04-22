// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC900} from "./IERC900.sol";

// Interface for ERC900: https://eips.ethereum.org/EIPS/eip-900, optional History methods
interface IERC900History is IERC900 {
    function lastStakedFor(address _user) external view returns (uint256);
    function totalStakedForAt(address _user, uint256 _blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 _blockNumber) external view returns (uint256);
}
